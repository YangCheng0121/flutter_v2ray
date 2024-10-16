package com.github.blueboytm.flutter_v2ray.v2ray.utils;

public class AppConfigs {

    // 当前的 V2Ray 连接模式，默认为 VPN_TUN
    public static V2RAY_CONNECTION_MODES V2RAY_CONNECTION_MODE = V2RAY_CONNECTION_MODES.VPN_TUN;
    // 应用名称
    public static String APPLICATION_NAME;
    // 应用图标资源 ID
    public static int APPLICATION_ICON;
    // V2Ray 配置对象
    public static V2rayConfig V2RAY_CONFIG = null;
    // V2Ray 当前状态，默认为已断开连接
    public static V2RAY_STATES V2RAY_STATE = V2RAY_STATES.V2RAY_DISCONNECTED;
    // 是否启用流量和速度统计
    public static boolean ENABLE_TRAFFIC_AND_SPEED_STATICS = true;
    // 延迟测量的 URL
    public static String DELAY_URL;

    // V2Ray 服务命令枚举
    public enum V2RAY_SERVICE_COMMANDS {
        START_SERVICE,  // 启动服务命令
        STOP_SERVICE,   // 停止服务命令
        MEASURE_DELAY   // 测量延迟命令
    }

    // V2Ray 状态枚举
    public enum V2RAY_STATES {
        V2RAY_CONNECTED,    // 连接状态
        V2RAY_DISCONNECTED, // 断开状态
        V2RAY_CONNECTING    // 正在连接状态
    }

    // V2Ray 连接模式枚举
    public enum V2RAY_CONNECTION_MODES {
        VPN_TUN,    // VPN 模式
        PROXY_ONLY  // 代理模式
    }

}
