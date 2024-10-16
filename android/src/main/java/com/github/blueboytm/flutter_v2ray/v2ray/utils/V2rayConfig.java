package com.github.blueboytm.flutter_v2ray.v2ray.utils;

import java.io.Serializable;
import java.util.ArrayList;

public class V2rayConfig implements Serializable {

    // 连接的 V2Ray 服务器地址
    public String CONNECTED_V2RAY_SERVER_ADDRESS = "";

    // 连接的 V2Ray 服务器端口
    public String CONNECTED_V2RAY_SERVER_PORT = "";

    // 本地 SOCKS5 端口，默认值为 10808
    public int LOCAL_SOCKS5_PORT = 10808;

    // 本地 HTTP 端口，默认值为 10809
    public int LOCAL_HTTP_PORT = 10809;

    // 被阻止的应用列表
    public ArrayList<String> BLOCKED_APPS = null;

    // 绕过的子网列表
    public ArrayList<String> BYPASS_SUBNETS = null;

    // 完整的 V2Ray JSON 配置
    public String V2RAY_FULL_JSON_CONFIG = null;

    // 是否启用流量统计
    public boolean ENABLE_TRAFFIC_STATICS = false;

    // 备注信息
    public String REMARK = "";

    // 应用名称
    public String APPLICATION_NAME;

    // 应用图标
    public int APPLICATION_ICON;
}
