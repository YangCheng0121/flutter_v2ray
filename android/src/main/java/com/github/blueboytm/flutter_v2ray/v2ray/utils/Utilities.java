package com.github.blueboytm.flutter_v2ray.v2ray.utils;

import android.content.Context;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;

import com.github.blueboytm.flutter_v2ray.v2ray.core.V2rayCoreManager;

public class Utilities {

    // 复制文件方法
    public static void CopyFiles(InputStream src, File dst) throws IOException {
        try (OutputStream out = new FileOutputStream(dst)) {
            byte[] buf = new byte[1024]; // 缓冲区
            int len;
            // 读取源文件并写入目标文件
            while ((len = src.read(buf)) > 0) {
                out.write(buf, 0, len);
            }
        }
    }

    // 获取用户资产路径
    public static String getUserAssetsPath(Context context) {
        File extDir = context.getExternalFilesDir("assets"); // 外部文件目录
        if (extDir == null) {
            return "";
        }
        // 如果目录不存在，返回应用内部目录
        if (!extDir.exists()) {
            return context.getDir("assets", 0).getAbsolutePath();
        } else {
            return extDir.getAbsolutePath();
        }
    }

    // 复制资产文件
    public static void copyAssets(final Context context) {
        String extFolder = getUserAssetsPath(context); // 获取用户资产路径
        try {
            String geo = "geosite.dat,geoip.dat"; // 需要复制的资产文件列表
            for (String assets_obj : context.getAssets().list("")) {
                if (geo.contains(assets_obj)) {
                    // 复制指定的资产文件
                    CopyFiles(context.getAssets().open(assets_obj), new File(extFolder, assets_obj));
                }
            }
        } catch (Exception e) {
            Log.e("Utilities", "copyAssets failed=>", e); // 记录错误
        }
    }

    // 将整数转换为两位数字的字符串
    public static String convertIntToTwoDigit(int value) {
        if (value < 10) return "0" + value; // 小于10时补零
        else return value + ""; // 否则直接返回字符串
    }

    // 解析 V2Ray 配置文件
    public static V2rayConfig parseV2rayJsonFile(final String remark, String config, final ArrayList<String> blockedApplication, final ArrayList<String> bypass_subnets) {
        final V2rayConfig v2rayConfig = new V2rayConfig();
        v2rayConfig.REMARK = remark; // 设置备注
        v2rayConfig.BLOCKED_APPS = blockedApplication; // 设置被阻止的应用
        v2rayConfig.BYPASS_SUBNETS = bypass_subnets; // 设置绕过的子网
        v2rayConfig.APPLICATION_ICON = AppConfigs.APPLICATION_ICON; // 设置应用图标
        v2rayConfig.APPLICATION_NAME = AppConfigs.APPLICATION_NAME; // 设置应用名称

        try {
            JSONObject config_json = new JSONObject(config); // 解析 JSON 配置
            try {
                JSONArray inbounds = config_json.getJSONArray("inbounds"); // 获取 inbound 数组
                for (int i = 0; i < inbounds.length(); i++) {
                    try {
                        // 获取 SOCKS5 端口
                        if (inbounds.getJSONObject(i).getString("protocol").equals("socks")) {
                            v2rayConfig.LOCAL_SOCKS5_PORT = inbounds.getJSONObject(i).getInt("port");
                        }
                    } catch (Exception e) {
                        // 忽略异常
                    }
                    try {
                        // 获取 HTTP 端口
                        if (inbounds.getJSONObject(i).getString("protocol").equals("http")) {
                            v2rayConfig.LOCAL_HTTP_PORT = inbounds.getJSONObject(i).getInt("port");
                        }
                    } catch (Exception e) {
                        // 忽略异常
                    }
                }
            } catch (Exception e) {
                Log.w(V2rayCoreManager.class.getSimpleName(), "startCore warn => can't find inbound port of socks5 or http.");
                return null; // 返回 null 如果未找到端口
            }
            try {
                // 获取 V2Ray 服务器地址和端口
                v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = config_json.getJSONArray("outbounds")
                        .getJSONObject(0).getJSONObject("settings")
                        .getJSONArray("vnext").getJSONObject(0)
                        .getString("address");
                v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = config_json.getJSONArray("outbounds")
                        .getJSONObject(0).getJSONObject("settings")
                        .getJSONArray("vnext").getJSONObject(0)
                        .getString("port");
            } catch (Exception e) {
                v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = config_json.getJSONArray("outbounds")
                        .getJSONObject(0).getJSONObject("settings")
                        .getJSONArray("servers").getJSONObject(0)
                        .getString("address");
                v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = config_json.getJSONArray("outbounds")
                        .getJSONObject(0).getJSONObject("settings")
                        .getJSONArray("servers").getJSONObject(0)
                        .getString("port");
            }
            // 移除不必要的政策和统计信息
            try {
                if (config_json.has("policy")) {
                    config_json.remove("policy");
                }
                if (config_json.has("stats")) {
                    config_json.remove("stats");
                }
            } catch (Exception ignore_error) {
                // 忽略错误
            }
            // 启用流量和速度统计
            if (AppConfigs.ENABLE_TRAFFIC_AND_SPEED_STATICS) {
                try {
                    JSONObject policy = new JSONObject();
                    JSONObject levels = new JSONObject();
                    levels.put("8", new JSONObject()
                            .put("connIdle", 300)
                            .put("downlinkOnly", 1)
                            .put("handshake", 4)
                            .put("uplinkOnly", 1));
                    JSONObject system = new JSONObject()
                            .put("statsOutboundUplink", true)
                            .put("statsOutboundDownlink", true);
                    policy.put("levels", levels);
                    policy.put("system", system);
                    config_json.put("policy", policy);
                    config_json.put("stats", new JSONObject());
                    config = config_json.toString(); // 更新配置
                    v2rayConfig.ENABLE_TRAFFIC_STATICS = true; // 启用流量统计
                } catch (Exception e) {
                    // 忽略错误
                }
            }
        } catch (Exception e) {
            Log.e(Utilities.class.getName(), "parseV2rayJsonFile failed => ", e); // 记录错误
            return null; // 返回 null 如果解析失败
        }
        v2rayConfig.V2RAY_FULL_JSON_CONFIG = config; // 保存完整的 JSON 配置
        return v2rayConfig; // 返回 V2rayConfig 对象
    }
}
