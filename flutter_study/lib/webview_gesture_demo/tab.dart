import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView Banner Tab Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TabContainerPage(),
    );
  }
}

class TabContainerPage extends StatefulWidget {
  const TabContainerPage({super.key});

  @override
  State<TabContainerPage> createState() => _TabContainerPageState();
}

class _TabContainerPageState extends State<TabContainerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool canSwipeTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WebView Banner Tab Demo"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "H5 页面"),
            Tab(text: "第二页"),
            Tab(text: "第三页"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: canSwipeTab
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        children: [
          WebViewTabPage(
            onCanSwipeChanged: (value) {
              setState(() {
                canSwipeTab = value;
              });
            },
          ),
          const Center(
              child: Text("这是第二页 Flutter 页面", style: TextStyle(fontSize: 18))),
          const Center(
              child: Text("这是第三页 Flutter 页面", style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}

class WebViewTabPage extends StatefulWidget {
  final ValueChanged<bool> onCanSwipeChanged;

  const WebViewTabPage({super.key, required this.onCanSwipeChanged});

  @override
  State<WebViewTabPage> createState() => _WebViewTabPageState();
}

class _WebViewTabPageState extends State<WebViewTabPage> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowsBackForwardNavigationGestures: true,
      ),
      onWebViewCreated: (controller) async {
        webViewController = controller;
        String htmlContent =
            await rootBundle.loadString('assets/html/banner_test.html');

        await controller.loadData(
          data: htmlContent,
          baseUrl: WebUri('about:blank'),
          mimeType: 'text/html',
          encoding: 'utf-8',
        );

        controller.addJavaScriptHandler(
          handlerName: "updateCanSwipeTab",
          callback: (args) {
            if (args.isNotEmpty && args[0] is bool) {
              widget.onCanSwipeChanged(args[0] as bool);
            }
            return null;
          },
        );
      },
    );
  }
}
