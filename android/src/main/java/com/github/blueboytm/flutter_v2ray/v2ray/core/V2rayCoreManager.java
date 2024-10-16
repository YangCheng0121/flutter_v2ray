package com.github.blueboytm.flutter_v2ray.v2ray.core;

import static com.github.blueboytm.flutter_v2ray.v2ray.utils.Utilities.getUserAssetsPath;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.CountDownTimer;
import android.util.Log;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import org.json.JSONObject;

import java.util.Objects;

import com.github.blueboytm.flutter_v2ray.v2ray.interfaces.V2rayServicesListener;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.AppConfigs;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.Utilities;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.V2rayConfig;
import com.github.blueboytm.flutter_v2ray.v2ray.services.V2rayProxyOnlyService;
import com.github.blueboytm.flutter_v2ray.v2ray.services.V2rayVPNService;
import com.github.blueboytm.flutter_v2ray.R;

import libv2ray.Libv2ray;
import libv2ray.V2RayPoint;
import libv2ray.V2RayVPNServiceSupportsSet;

public final class V2rayCoreManager {
    private volatile static V2rayCoreManager INSTANCE;
    // V2ray 服务监听器
    public V2rayServicesListener v2rayServicesListener = null;
    // LibV2rayCore 初始化状态
    private boolean isLibV2rayCoreInitialized = false;
    // V2ray 当前状态
    public AppConfigs.V2RAY_STATES V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED;
    // 倒计时器
    private CountDownTimer countDownTimer;
    // 用于时间计数的变量
    private int seconds, minutes, hours;
    // 总下载和上传流量
    private long totalDownload, totalUpload, uploadSpeed, downloadSpeed;
    // 服务时长的字符串表示
    private String SERVICE_DURATION = "00:00:00";
    // 通知管理器
    private NotificationManager mNotificationManager = null;

    // 私有构造函数
    private V2rayCoreManager() {}

    // 获取单例实例
    public static V2rayCoreManager getInstance() {
        if (INSTANCE == null) {
            synchronized (V2rayCoreManager.class) {
                if (INSTANCE == null) {
                    INSTANCE = new V2rayCoreManager();
                }
            }
        }
        return INSTANCE;
    }

    // 创建时长计时器
    private void makeDurationTimer(final Context context, final boolean enable_traffic_statics) {
        countDownTimer = new CountDownTimer(7200, 1000) { // 每小时7200秒，每秒触发一次
            @RequiresApi(api = Build.VERSION_CODES.M)
            public void onTick(long millisUntilFinished) {
                seconds++; // 秒数递增
                if (seconds == 59) {
                    minutes++; // 分钟递增
                    seconds = 0; // 秒数重置
                }
                if (minutes == 59) {
                    minutes = 0; // 分钟重置
                    hours++; // 小时递增
                }
                if (hours == 23) {
                    hours = 0; // 小时重置
                }
                // 如果启用了流量统计
                if (enable_traffic_statics) {
                    downloadSpeed = v2RayPoint.queryStats("block", "downlink") + v2RayPoint.queryStats("proxy", "downlink");
                    uploadSpeed = v2RayPoint.queryStats("block", "uplink") + v2RayPoint.queryStats("proxy", "uplink");
                    totalDownload = totalDownload + downloadSpeed; // 更新总下载流量
                    totalUpload = totalUpload + uploadSpeed; // 更新总上传流量
                }
                // 更新服务时长
                SERVICE_DURATION = Utilities.convertIntToTwoDigit(hours) + ":" + Utilities.convertIntToTwoDigit(minutes) + ":" + Utilities.convertIntToTwoDigit(seconds);
                // 发送连接信息的广播
                Intent connection_info_intent = new Intent("V2RAY_CONNECTION_INFO");
                connection_info_intent.putExtra("STATE", V2rayCoreManager.getInstance().V2RAY_STATE);
                connection_info_intent.putExtra("DURATION", SERVICE_DURATION);
                connection_info_intent.putExtra("UPLOAD_SPEED", uploadSpeed);
                connection_info_intent.putExtra("DOWNLOAD_SPEED", downloadSpeed);
                connection_info_intent.putExtra("UPLOAD_TRAFFIC", totalUpload);
                connection_info_intent.putExtra("DOWNLOAD_TRAFFIC", totalDownload);
                context.sendBroadcast(connection_info_intent); // 发送广播
            }

            public void onFinish() {
                countDownTimer.cancel(); // 取消计时器
                // 如果 V2ray 核心正在运行，重新开始计时
                if (V2rayCoreManager.getInstance().isV2rayCoreRunning())
                    makeDurationTimer(context, enable_traffic_statics);
            }
        }.start(); // 启动计时器
    }

    public void setUpListener(Service targetService) {
        try {
            // 将目标服务赋值给 v2rayServicesListener
            v2rayServicesListener = (V2rayServicesListener) targetService;
            // 初始化 V2Ray 环境
            Libv2ray.initV2Env(getUserAssetsPath(targetService.getApplicationContext()), "");
            isLibV2rayCoreInitialized = true; // 标记初始化成功
            SERVICE_DURATION = "00:00:00"; // 初始化服务时长
            seconds = 0; // 秒数重置
            minutes = 0; // 分钟重置
            hours = 0; // 小时重置
            uploadSpeed = 0; // 上传速度重置
            downloadSpeed = 0; // 下载速度重置
            totalDownload = 0; // 总下载流量重置
            totalUpload = 0; // 总上传流量重置
            Log.e(V2rayCoreManager.class.getSimpleName(), "setUpListener => new initialize from " + v2rayServicesListener.getService().getClass().getSimpleName());
        } catch (Exception e) {
            // 捕获异常并记录错误
            Log.e(V2rayCoreManager.class.getSimpleName(), "setUpListener failed => ", e);
            isLibV2rayCoreInitialized = false; // 标记初始化失败
        }
    }

    public final V2RayPoint v2RayPoint = Libv2ray.newV2RayPoint(new V2RayVPNServiceSupportsSet() {
        @Override
        public long shutdown() {
            if (v2rayServicesListener == null) {
                Log.e(V2rayCoreManager.class.getSimpleName(), "shutdown failed => can't find initial service.");
                return -1; // 找不到初始服务，返回失败
            }
            try {
                v2rayServicesListener.stopService(); // 停止服务
                v2rayServicesListener = null; // 清空服务监听器
                return 0; // 成功
            } catch (Exception e) {
                Log.e(V2rayCoreManager.class.getSimpleName(), "shutdown failed =>", e);
                return -1; // 捕获异常，返回失败
            }
        }

        @Override
        public long prepare() {
            return 0; // 准备工作，返回成功
        }

        @Override
        public boolean protect(long l) {
            if (v2rayServicesListener != null)
                return v2rayServicesListener.onProtect((int) l); // 调用保护方法
            return true; // 默认返回 true
        }

        @Override
        public long onEmitStatus(long l, String s) {
            return 0; // 状态发射处理，返回成功
        }

        @Override
        public long setup(String s) {
            if (v2rayServicesListener != null) {
                try {
                    v2rayServicesListener.startService(); // 启动服务
                } catch (Exception e) {
                    Log.e(V2rayCoreManager.class.getSimpleName(), "setup failed => ", e);
                    return -1; // 捕获异常，返回失败
                }
            }
            return 0; // 成功
        }
    }, Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1);

    public boolean startCore(final V2rayConfig v2rayConfig) {
        // 开始计时器并启用流量统计
        makeDurationTimer(v2rayServicesListener.getService().getApplicationContext(),
                v2rayConfig.ENABLE_TRAFFIC_STATICS);
        V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_CONNECTING; // 设置状态为连接中
        if (!isLibV2rayCoreInitialized) {
            Log.e(V2rayCoreManager.class.getSimpleName(), "startCore failed => LibV2rayCore should be initialize before start.");
            return false; // 如果没有初始化，返回失败
        }
        if (isV2rayCoreRunning()) {
            stopCore(); // 如果正在运行，则停止核心
        }
        try {
            // Libv2ray.testConfig(v2rayConfig.V2RAY_FULL_JSON_CONFIG); // 检查配置有效性
        } catch (Exception e) {
            sendDisconnectedBroadCast(); // 发送断开连接广播
            Log.e(V2rayCoreManager.class.getSimpleName(), "startCore failed => v2ray json config not valid.");
            return false; // 配置无效，返回失败
        }
        try {
            // 设置 V2Ray 配置文件内容和服务器地址
            v2RayPoint.setConfigureFileContent(v2rayConfig.V2RAY_FULL_JSON_CONFIG);
            v2RayPoint.setDomainName(v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS + ":" + v2rayConfig.CONNECTED_V2RAY_SERVER_PORT);
            v2RayPoint.runLoop(false); // 运行主循环
            V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_CONNECTED; // 设置状态为已连接
            if (isV2rayCoreRunning()) {
                showNotification(v2rayConfig); // 显示通知
            }
        } catch (Exception e) {
            Log.e(V2rayCoreManager.class.getSimpleName(), "startCore failed =>", e);
            return false; // 捕获异常，返回失败
        }
        return true; // 成功
    }

    public void stopCore() {
        try {
            if (isV2rayCoreRunning()) {
                v2RayPoint.stopLoop(); // 停止主循环
                v2rayServicesListener.stopService(); // 停止服务
                Log.e(V2rayCoreManager.class.getSimpleName(), "stopCore success => v2ray core stopped.");
            } else {
                Log.e(V2rayCoreManager.class.getSimpleName(), "stopCore failed => v2ray core not running.");
            }
            sendDisconnectedBroadCast(); // 发送断开连接广播
        } catch (Exception e) {
            Log.e(V2rayCoreManager.class.getSimpleName(), "stopCore failed =>", e);
        }
    }

    private void sendDisconnectedBroadCast() {
        V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED; // 设置状态为已断开
        SERVICE_DURATION = "00:00:00"; // 重置服务时长
        seconds = 0; // 秒数重置
        minutes = 0; // 分钟重置
        hours = 0; // 小时重置
        uploadSpeed = 0; // 上传速度重置
        downloadSpeed = 0; // 下载速度重置
        if (v2rayServicesListener != null) {
            // 发送断开连接信息广播
            Intent connection_info_intent = new Intent("V2RAY_CONNECTION_INFO");
            connection_info_intent.putExtra("STATE", V2rayCoreManager.getInstance().V2RAY_STATE);
            connection_info_intent.putExtra("DURATION", SERVICE_DURATION);
            connection_info_intent.putExtra("UPLOAD_SPEED", uploadSpeed);
            connection_info_intent.putExtra("DOWNLOAD_SPEED", uploadSpeed);
            connection_info_intent.putExtra("UPLOAD_TRAFFIC", uploadSpeed);
            connection_info_intent.putExtra("DOWNLOAD_TRAFFIC", uploadSpeed);
            try {
                v2rayServicesListener.getService().getApplicationContext().sendBroadcast(connection_info_intent); // 发送广播
            } catch (Exception e) {
                // 忽略异常
            }
        }
        if (countDownTimer != null) {
            countDownTimer.cancel(); // 取消计时器
        }
    }

//
//    private fun getNotificationManager(): NotificationManager? {
//        if (mNotificationManager == null) {
//            val service = serviceControl?.get()?.getService() ?: return null
//            mNotificationManager =
//                    service.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
//        }
//        return mNotificationManager
//    }

    private NotificationManager getNotificationManager() {
        if (mNotificationManager == null) {
            try {
                mNotificationManager = (NotificationManager) v2rayServicesListener.getService().getSystemService(Context.NOTIFICATION_SERVICE);
            } catch (Exception e) {
                return null;
            }
        }
        return mNotificationManager;
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private String createNotificationChannelID(final String Application_name) {
        // 创建通知频道 ID
        String notification_channel_id = "DEV7_DEV_V_E_CH_ID";
        // 创建通知频道
        NotificationChannel notificationChannel = new NotificationChannel(
                notification_channel_id, Application_name + " Background Service", NotificationManager.IMPORTANCE_DEFAULT);
        notificationChannel.setLightColor(Color.BLUE); // 设置通知灯光颜色
        notificationChannel.setImportance(NotificationManager.IMPORTANCE_DEFAULT); // 设置通知重要性
        // 注册通知频道
        Objects.requireNonNull(getNotificationManager()).createNotificationChannel(notificationChannel);
        return notification_channel_id; // 返回通知频道 ID
    }

    private int judgeForNotificationFlag() {
        // 判断 PendingIntent 标志
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT; // Android 6.0 及以上
        } else {
            return PendingIntent.FLAG_UPDATE_CURRENT; // Android 6.0 以下
        }
    }

    private void showNotification(final V2rayConfig v2rayConfig) {
        // 显示通知
        if (v2rayServicesListener == null) {
            return; // 如果服务监听器为空，返回
        }
        // 获取启动应用的 Intent
        Intent launchIntent = v2rayServicesListener.getService().getPackageManager().
                getLaunchIntentForPackage(v2rayServicesListener.getService().getApplicationInfo().packageName);
        launchIntent.setAction("FROM_DISCONNECT_BTN"); // 设置意图动作
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK); // 设置意图标志
        // 创建 PendingIntent
        PendingIntent notificationContentPendingIntent = PendingIntent.getActivity(
                v2rayServicesListener.getService(), 0, launchIntent, judgeForNotificationFlag());
        String notificationChannelID = "";
        // 创建通知频道
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            notificationChannelID = createNotificationChannelID(v2rayConfig.APPLICATION_NAME);
        }

        Intent stop_intent; // 停止服务的意图
        // 根据连接模式创建停止意图
        if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY) {
            stop_intent = new Intent(v2rayServicesListener.getService(), V2rayProxyOnlyService.class);
        } else if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN) {
            stop_intent = new Intent(v2rayServicesListener.getService(), V2rayVPNService.class);
        } else {
            return; // 如果连接模式不匹配，返回
        }
        stop_intent.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE); // 添加停止服务命令

        // 创建停止服务的 PendingIntent
        PendingIntent pendingIntent = PendingIntent.getService(
                v2rayServicesListener.getService(),
                0,
                stop_intent,
                PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE
        );

        // 创建通知构建器
        NotificationCompat.Builder mBuilder =
                new NotificationCompat.Builder(v2rayServicesListener.getService(), notificationChannelID);
        // 设置通知内容
        mBuilder.setSmallIcon(v2rayConfig.APPLICATION_ICON) // 设置小图标
                .setContentTitle(v2rayConfig.REMARK) // 设置标题
                // .setContentText("tap to open application") // 设置内容文本
                .addAction(0, "DISCONNECT", pendingIntent) // 添加断开连接按钮
                .setSmallIcon(R.drawable.baseline_vpn_key_24); // 设置小图标
        // .setContentIntent(notificationContentPendingIntent); // 设置点击通知的意图
        // 启动前台服务并显示通知
        v2rayServicesListener.getService().startForeground(1, mBuilder.build());
    }

    public boolean isV2rayCoreRunning() {
        // 检查 V2Ray 核心是否正在运行
        if (v2RayPoint != null) {
            return v2RayPoint.getIsRunning(); // 返回运行状态
        }
        return false; // 如果 v2RayPoint 为空，返回 false
    }

    public Long getConnectedV2rayServerDelay() {
        // 获取连接的 V2Ray 服务器延迟
        try {
            return v2RayPoint.measureDelay(AppConfigs.DELAY_URL); // 测量延迟
        } catch (Exception e) {
            return -1L; // 捕获异常，返回 -1
        }
    }

    public Long getV2rayServerDelay(final String config, final String url) {
        // 获取 V2Ray 服务器延迟
        try {
            try {
                JSONObject config_json = new JSONObject(config); // 将配置字符串转换为 JSON 对象
                JSONObject new_routing_json = config_json.getJSONObject("routing");
                new_routing_json.remove("rules"); // 移除路由规则
                config_json.remove("routing");
                config_json.put("routing", new_routing_json); // 更新路由配置
                return Libv2ray.measureOutboundDelay(config_json.toString(), url); // 测量延迟
            } catch (Exception json_error) {
                Log.e("getV2rayServerDelay", json_error.toString()); // 记录 JSON 解析错误
                return Libv2ray.measureOutboundDelay(config, url); // 如果失败，则使用原始配置
            }
        } catch (Exception e) {
            Log.e("getV2rayServerDelayCore", e.toString()); // 记录其他错误
            return -1L; // 返回 -1 表示错误
        }
    }

}
