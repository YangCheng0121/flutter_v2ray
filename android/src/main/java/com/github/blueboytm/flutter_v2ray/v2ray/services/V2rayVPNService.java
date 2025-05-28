package com.github.blueboytm.flutter_v2ray.v2ray.services;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.net.InetAddresses;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.github.blueboytm.flutter_v2ray.v2ray.core.V2rayCoreManager;
import com.github.blueboytm.flutter_v2ray.v2ray.interfaces.V2rayServicesListener;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.AppConfigs;
import com.github.blueboytm.flutter_v2ray.v2ray.utils.V2rayConfig;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileDescriptor;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;

public class V2rayVPNService extends VpnService implements V2rayServicesListener {
    private static final int NOTIFICATION_ID = 10101;
    private static final String NOTIFICATION_CHANNEL_ID = "v2ray_vpn_channel";
    private ParcelFileDescriptor mInterface;
    private Process process;
    private V2rayConfig v2rayConfig;
    private boolean isRunning = true;

    @Override
    public void onCreate() {
        super.onCreate();
        V2rayCoreManager.getInstance().setUpListener(this);
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // 确保intent不为null
        if (intent == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        // 先启动前台服务再处理其他逻辑
        startForeground(NOTIFICATION_ID, createNotification());

        AppConfigs.V2RAY_SERVICE_COMMANDS startCommand = (AppConfigs.V2RAY_SERVICE_COMMANDS) intent.getSerializableExtra("COMMAND");
        if (startCommand == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        try {
            if (startCommand.equals(AppConfigs.V2RAY_SERVICE_COMMANDS.START_SERVICE)) {
                v2rayConfig = (V2rayConfig) intent.getSerializableExtra("V2RAY_CONFIG");
                if (v2rayConfig == null) {
                    stopSelf();
                    return START_NOT_STICKY;
                }

                if (V2rayCoreManager.getInstance().isV2rayCoreRunning()) {
                    V2rayCoreManager.getInstance().stopCore();
                }

                if (V2rayCoreManager.getInstance().startCore(v2rayConfig)) {
                    Log.d("V2rayVPNService", "V2ray core started successfully");
                    setup();
                } else {
                    stopSelf();
                }
            } else if (startCommand.equals(AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE)) {
                stopAllProcess();
                AppConfigs.V2RAY_CONFIG = null;
            } else if (startCommand.equals(AppConfigs.V2RAY_SERVICE_COMMANDS.MEASURE_DELAY)) {
                new Thread(() -> {
                    Intent sendB = new Intent("CONNECTED_V2RAY_SERVER_DELAY");
                    sendB.putExtra("DELAY", String.valueOf(V2rayCoreManager.getInstance().getConnectedV2rayServerDelay()));
                    sendBroadcast(sendB);
                }, "MEASURE_CONNECTED_V2RAY_SERVER_DELAY").start();
            }
        } catch (Exception e) {
            Log.e("V2rayVPNService", "Error in onStartCommand", e);
            stopSelf();
        }

        return START_STICKY;
    }

    private synchronized void stopAllProcess() {
        try {
            isRunning = false;
            if (process != null) {
                process.destroy();
                process = null;
            }
            V2rayCoreManager.getInstance().stopCore();

            if (mInterface != null) {
                mInterface.close();
                mInterface = null;
            }
        } catch (Exception e) {
            Log.e("V2rayVPNService", "Error stopping processes", e);
        } finally {
            stopForeground(true);
            stopSelf();
        }
    }

    private void setup() {
        try {
            Intent prepare_intent = prepare(this);
            if (prepare_intent != null) {
                return;
            }

            Builder builder = new Builder();
            builder.setSession("Secure Tunnel");
            builder.setMtu(1500);
            builder.addAddress("26.26.26.1", 30);

            if (v2rayConfig.BYPASS_SUBNETS == null || v2rayConfig.BYPASS_SUBNETS.isEmpty()) {
                builder.addRoute("0.0.0.0", 0);
            } else {
                for (String subnet : v2rayConfig.BYPASS_SUBNETS) {
                    String[] parts = subnet.split("/");
                    if (parts.length == 2) {
                        String address = parts[0];
                        int prefixLength = Integer.parseInt(parts[1]);
                        builder.addRoute(address, prefixLength);
                    }
                }
            }

            if (v2rayConfig.BLOCKED_APPS != null) {
                for (int i = 0; i < v2rayConfig.BLOCKED_APPS.size(); i++) {
                    try {
                        builder.addDisallowedApplication(v2rayConfig.BLOCKED_APPS.get(i));
                    } catch (Exception e) {
                        Log.w("V2rayVPNService", "Failed to block app: " + v2rayConfig.BLOCKED_APPS.get(i), e);
                    }
                }
            }

            try {
                JSONObject json = new JSONObject(v2rayConfig.V2RAY_FULL_JSON_CONFIG);
                JSONObject dnsObject = json.getJSONObject("dns");
                JSONArray serversArray = dnsObject.getJSONArray("servers");

                for (int i = 0; i < serversArray.length(); i++) {
                    Object serverEntry = serversArray.get(i);
                    handleDnsServerEntry(builder, serverEntry);
                }
            } catch (JSONException e) {
                Log.e("V2rayVPNService", "DNS config parsing error", e);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false);
                builder.setHttpProxy(null);
            }

            mInterface = builder.establish();
            isRunning = true;
            runTun2socks();
        } catch (Exception e) {
            Log.e("V2rayVPNService", "Error setting up VPN", e);
            stopAllProcess();
        }
    }

    private void handleDnsServerEntry(Builder builder, Object serverEntry) {
        try {
            if (serverEntry instanceof String) {
                String entry = (String) serverEntry;
                String cleanedIp = entry.split(":")[0];
                if (isValidIpAddress(cleanedIp)) {
                    builder.addDnsServer(cleanedIp);
                }
            } else if (serverEntry instanceof JSONObject) {
                JSONObject entry = (JSONObject) serverEntry;
                String address = entry.getString("address");
                String cleanedIp = address.split(":")[0];
                if (isValidIpAddress(cleanedIp)) {
                    builder.addDnsServer(cleanedIp);
                }
            }
        } catch (Exception e) {
            Log.w("V2rayVPNService", "Error processing DNS entry", e);
        }
    }

    private boolean isValidIpAddress(String ip) {
        if (ip == null || ip.isEmpty()) return false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return InetAddresses.isNumericAddress(ip);
        }
        return false;
    }

    private void runTun2socks() {
        ArrayList<String> cmd = new ArrayList<>(Arrays.asList(
                new File(getApplicationInfo().nativeLibraryDir, "libtun2socks.so").getAbsolutePath(),
                "--netif-ipaddr", "26.26.26.2",
                "--netif-netmask", "255.255.255.252",
                "--socks-server-addr", "127.0.0.1:" + v2rayConfig.LOCAL_SOCKS5_PORT,
                "--tunmtu", "1500",
                "--sock-path", "sock_path",
                "--enable-udprelay",
                "--loglevel", "error"));

        try {
            ProcessBuilder processBuilder = new ProcessBuilder(cmd);
            processBuilder.redirectErrorStream(true);
            process = processBuilder.directory(getApplicationContext().getFilesDir()).start();

            new Thread(() -> {
                try {
                    process.waitFor();
                    if (isRunning) {
                        runTun2socks();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }, "Tun2socks_Thread").start();

            sendFileDescriptor();
        } catch (Exception e) {
            Log.e("V2rayVPNService", "Error running tun2socks", e);
            stopAllProcess();
        }
    }

    private void sendFileDescriptor() {
        String localSocksFile = new File(getApplicationContext().getFilesDir(), "sock_path").getAbsolutePath();
        FileDescriptor tunFd = mInterface.getFileDescriptor();

        new Thread(() -> {
            int tries = 0;
            while (tries <= 5) {
                try {
                    Thread.sleep(100L * (1 << tries));
                    LocalSocket clientLocalSocket = new LocalSocket();
                    clientLocalSocket.connect(new LocalSocketAddress(localSocksFile, LocalSocketAddress.Namespace.FILESYSTEM));

                    OutputStream clientOutStream = clientLocalSocket.getOutputStream();
                    clientLocalSocket.setFileDescriptorsForSend(new FileDescriptor[]{tunFd});
                    clientOutStream.write(32);
                    clientLocalSocket.setFileDescriptorsForSend(null);
                    clientLocalSocket.shutdownOutput();
                    clientLocalSocket.close();
                    break;
                } catch (Exception e) {
                    tries++;
                    if (tries > 5) {
                        Log.e("V2rayVPNService", "Failed to send file descriptor after retries", e);
                    }
                }
            }
        }, "sendFd_Thread").start();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopAllProcess();
    }

    @Override
    public void onRevoke() {
        stopAllProcess();
    }

    @Override
    public boolean onProtect(int socket) {
        return protect(socket);
    }

    @Override
    public Service getService() {
        return this;
    }

    @Override
    public void startService() {
        setup();
    }

    @Override
    public void stopService() {
        stopAllProcess();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "VPN Service",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("VPN background service");
            channel.setShowBadge(false);
            NotificationManager nm = getSystemService(NotificationManager.class);
            nm.createNotificationChannel(channel);
        }
    }

    private Notification createNotification() {
        Intent intent = new Intent(this, io.flutter.embedding.android.FlutterActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ? PendingIntent.FLAG_IMMUTABLE : 0);

        return new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("VPN 已连接")
                .setContentText("流量受保护")
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
                .setContentIntent(pendingIntent)
                .setShowWhen(false)
                .setCategory(Notification.CATEGORY_SERVICE)
                .build();
    }
}