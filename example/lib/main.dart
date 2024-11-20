import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter V2Ray',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const Scaffold(
        body: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
    },
  );

  // final config = TextEditingController(text: "vmess://eyJhZGQiOiAiMzguMTIuMjcuMTMyIiwgImFpZCI6ICIwIiwgImhvc3QiOiAiIiwgImlkIjogIjM5ZWRiZTFkLWUzZDktNGI0MC04YjY3LTI3Mjc5OGYzODUyZSIsICJuZXQiOiAia2NwIiwgInBhdGgiOiAiIiwgInBvcnQiOiA1OTQ3MywgInBzIjogIiIsICJzY3kiOiAibm9uZSIsICJ0bHMiOiAiIiwgInR5cGUiOiAibm9uZSIsICJ2IjogIjIifQ==");
  final config = TextEditingController(
      text: "4nrZEw8xKHP+EVv4LEqmmeX+OYHDp6qYPNh0igUGMCXO5mSRnzep0BBu8W7G5Bm0FoPlrcBhBzqYD+LEwGmVRDFTDZvFhk52R2xnVkd87WQYFVX1pJVppB65Tb9swJxTMyC2jnmatE1ueeSUIewN3BQX8ba1GeMs5qyIDhoEUAcsNQ+GT3G37cbKCrkI9NMj1tL0pJyze5m6zjdEeqE90ImZmkHV6tAtcFrUC/mndRj1O0UhVktyYyNiQu2oLiS/t6kC+ELBh982jBDKkNAPGmOarX7b8cDb+u1G+E4j8b8DbGFXXr5tJXP4nMdnZXCuFxWzB/4ts5tEYVPEHBTZUaz9gqs+SfS4xE6jdX/CLpw=");

  bool proxyOnly = false;
  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  final bypassSubnetController = TextEditingController();
  List<String> bypassSubnets = [];
  String? coreVersion;

  String remark = "Default Remark";


  void connect() async {
    if (await flutterV2ray.requestPermission()) {
      // Remove "vmess://" prefix
      // String base64Data = config.text.replaceFirst("vmess://", "");

      // Decode Base64 string
      // String decodedString = utf8.decode(base64.decode(base64Data));

      V2RayURL parser = FlutterV2ray.parseFromURL(config.text);

      flutterV2ray.startV2Ray(
        remark: remark,
        config: parser.getFullConfiguration(),
        proxyOnly: proxyOnly,
        bypassSubnets: bypassSubnets,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission Denied'),
          ),
        );
      }
    }
  }

  void importConfig() async {
    if (await Clipboard.hasStrings()) {
      try {
        final String link =
            (await Clipboard.getData('text/plain'))?.text?.trim() ?? '';
        final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(link);
        remark = v2rayURL.remark;
        config.text = v2rayURL.getFullConfiguration();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Success',
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $error',
              ),
            ),
          );
        }
      }
    }
  }

  void delay() async {
    late int delay;
    if (v2rayStatus.value.state == 'CONNECTED') {
      delay = await flutterV2ray.getConnectedServerDelay();
    } else {
      delay = await flutterV2ray.getServerDelay(config: config.text);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${delay}ms',
        ),
      ),
    );
  }

  void bypassSubnet() {
    bypassSubnetController.text = bypassSubnets.join("\n");
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Subnets:',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: bypassSubnetController,
                    maxLines: 5,
                    minLines: 5,
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    onPressed: () {
                      bypassSubnets =
                          bypassSubnetController.text.trim().split('\n');
                      if (bypassSubnets.first.isEmpty) {
                        bypassSubnets = [];
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    flutterV2ray.initializeV2Ray().then((value) async {
      coreVersion = await flutterV2ray.getCoreVersion();
      setState(() {});
    });
  }

  @override
  void dispose() {
    config.dispose();
    bypassSubnetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            const Text(
              'V2Ray Config (json):',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: config,
              maxLines: 10,
              minLines: 10,
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: v2rayStatus,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Text(value.state),
                    const SizedBox(height: 10),
                    Text(value.duration),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Speed:'),
                        const SizedBox(width: 10),
                        Text(value.uploadSpeed.toString()),
                        const Text('↑'),
                        const SizedBox(width: 10),
                        Text(value.downloadSpeed.toString()),
                        const Text('↓'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Traffic:'),
                        const SizedBox(width: 10),
                        Text(value.upload.toString()),
                        const Text('↑'),
                        const SizedBox(width: 10),
                        Text(value.download.toString()),
                        const Text('↓'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Core Version: $coreVersion'),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  ElevatedButton(
                    onPressed: connect,
                    child: const Text('Connect'),
                  ),
                  ElevatedButton(
                    onPressed: () => flutterV2ray.stopV2Ray(),
                    child: const Text('Disconnect'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => proxyOnly = !proxyOnly),
                    child: Text(proxyOnly ? 'Proxy Only' : 'VPN Mode'),
                  ),
                  ElevatedButton(
                    onPressed: importConfig,
                    child: const Text(
                      'Import from v2ray share link (clipboard)',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: delay,
                    child: const Text('Server Delay'),
                  ),
                  ElevatedButton(
                    onPressed: bypassSubnet,
                    child: const Text('Bypass Subnet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
