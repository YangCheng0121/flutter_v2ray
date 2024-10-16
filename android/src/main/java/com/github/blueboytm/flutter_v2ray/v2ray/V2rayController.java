package com.github.blueboytm.flutter_v2ray.v2ray;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.util.Log;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.ArrayList;

import com.github.blueboytm.flutter_v2ray.v2ray.core.V2rayCoreManager;
import com.github.blueboytm.flutter_v2ray.v2ray.services.V2rayProxyOnlyService;
import com.github.blueboytm.flutter_v2ray.v2ray.services.V2rayVPNService;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.AppConfigs;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.Utilities;
import libv2ray.Libv2ray;

public class V2rayController {

    // 初始化 V2Ray 控制器
    public static void init(final Context context, final int app_icon, final String app_name) {
        // 复制必要的资产文件
        Utilities.copyAssets(context);
        AppConfigs.APPLICATION_ICON = app_icon;  // 设置应用图标
        AppConfigs.APPLICATION_NAME = app_name;  // 设置应用名称

        // 注册广播接收器，监听 V2Ray 状态变化
        BroadcastReceiver receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context arg0, Intent arg1) {
                // 更新 V2Ray 状态
                AppConfigs.V2RAY_STATE = (AppConfigs.V2RAY_STATES) arg1.getExtras().getSerializable("STATE");
            }
        };

        // 根据 Android 版本选择合适的注册方式
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, new IntentFilter("V2RAY_CONNECTION_INFO"), Context.RECEIVER_EXPORTED);
        } else {
            context.registerReceiver(receiver, new IntentFilter("V2RAY_CONNECTION_INFO"));
        }
    }

    // 改变连接模式
    public static void changeConnectionMode(final AppConfigs.V2RAY_CONNECTION_MODES connection_mode) {
        // 只有在当前状态为断开连接时才能改变连接模式
        if (getConnectionState() == AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED) {
            AppConfigs.V2RAY_CONNECTION_MODE = connection_mode;
        }
    }

    // 启动 V2Ray 服务
    public static void StartV2ray(final Context context, final String remark, final String config, final ArrayList<String> blocked_apps, final ArrayList<String> bypass_subnets) {
        // 解析 V2Ray 配置文件
        AppConfigs.V2RAY_CONFIG = Utilities.parseV2rayJsonFile(remark, config, blocked_apps, bypass_subnets);
        if (AppConfigs.V2RAY_CONFIG == null) {
            return;  // 如果配置无效，返回
        }

        // 根据连接模式选择相应的服务
        Intent start_intent;
        if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY) {
            start_intent = new Intent(context, V2rayProxyOnlyService.class);
        } else if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN) {
            start_intent = new Intent(context, V2rayVPNService.class);
        } else {
            return;  // 无效的连接模式，返回
        }

        // 添加启动服务的命令和配置
        start_intent.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.START_SERVICE);
        start_intent.putExtra("V2RAY_CONFIG", AppConfigs.V2RAY_CONFIG);

        // 启动前台服务或普通服务
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.N_MR1) {
            context.startForegroundService(start_intent);
        } else {
            context.startService(start_intent);
        }
    }

    // 停止 V2Ray 服务
    public static void StopV2ray(final Context context) {
        Intent stop_intent;
        // 根据连接模式选择相应的服务
        if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY) {
            stop_intent = new Intent(context, V2rayProxyOnlyService.class);
        } else if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN) {
            stop_intent = new Intent(context, V2rayVPNService.class);
        } else {
            return;  // 无效的连接模式，返回
        }

        // 添加停止服务的命令
        stop_intent.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE);
        context.startService(stop_intent);  // 启动停止服务的意图
        AppConfigs.V2RAY_CONFIG = null;  // 清空配置
    }

    // 获取当前连接的 V2Ray 服务器延迟
    public static long getConnectedV2rayServerDelay(Context context) {
        if (V2rayController.getConnectionState() != AppConfigs.V2RAY_STATES.V2RAY_CONNECTED) {
            return -1;  // 如果未连接，返回 -1
        }

        Intent check_delay;
        // 根据连接模式选择相应的服务
        if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY) {
            check_delay = new Intent(context, V2rayProxyOnlyService.class);
        } else if (AppConfigs.V2RAY_CONNECTION_MODE == AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN) {
            check_delay = new Intent(context, V2rayVPNService.class);
        } else {
            return -1;  // 无效的连接模式，返回
        }

        final long[] delay = {-1};
        final CountDownLatch latch = new CountDownLatch(1);  // 计数器，用于同步

        // 添加测量延迟的命令
        check_delay.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.MEASURE_DELAY);
        context.startService(check_delay);  // 启动测量延迟的意图

        // 注册接收器，处理延迟测量结果
        BroadcastReceiver receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context arg0, Intent arg1) {
                String delayString = arg1.getExtras().getString("DELAY");
                delay[0] = Long.parseLong(delayString);  // 更新延迟
                context.unregisterReceiver(this);  // 注销接收器
                latch.countDown();  // 计数器减一
            }
        };

        context.registerReceiver(receiver, new IntentFilter("CONNECTED_V2RAY_SERVER_DELAY"));  // 注册接收器
        try {
            boolean received = latch.await(3000, TimeUnit.MILLISECONDS);  // 等待结果，超时 3 秒
            if (!received) {
                return -1;  // 如果超时，返回 -1
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return delay[0];  // 返回测量得到的延迟
    }

    // 根据配置和 URL 获取 V2Ray 服务器延迟
    public static long getV2rayServerDelay(final String config, final String url) {
        return V2rayCoreManager.getInstance().getV2rayServerDelay(config, url);
    }

    // 获取当前连接模式
    public static AppConfigs.V2RAY_CONNECTION_MODES getConnectionMode() {
        return AppConfigs.V2RAY_CONNECTION_MODE;
    }

    // 获取当前连接状态
    public static AppConfigs.V2RAY_STATES getConnectionState() {
        return AppConfigs.V2RAY_STATE;
    }

    // 获取 V2Ray 核心版本
    public static String getCoreVersion() {
        return Libv2ray.checkVersionX();
    }
}
