import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Tab Demo',
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
  bool canSwipeTab = true; // 控制 TabBarView 是否允许左右滑动

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
        title: const Text("WebView Tab Demo"),
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
    return Listener(
      onPointerDown: (_) => widget.onCanSwipeChanged(false),
      onPointerUp: (_) => widget.onCanSwipeChanged(true),
      onPointerCancel: (_) => widget.onCanSwipeChanged(true),
      child: InAppWebView(
        // 2) 关键：让 WebView 抢占所有手势
        // gestureRecognizers: {
        //   Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        // },
        // 3) 可选：减少 iOS 触摸延迟
        preventGestureDelay: true,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          allowsBackForwardNavigationGestures: true, // 保留你原有设置

        ),
        initialUrlRequest: URLRequest(
          url: WebUri("https://www.baidu.com"),
        ),
        onWebViewCreated: (c) => webViewController = c,
        onReceivedServerTrustAuthRequest: (controller, challenge) async =>
            ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED),
        onLoadStart: (c, url) => print("开始加载: $url"),
        onLoadStop: (c, url) async => print("加载完成: $url"),
        onConsoleMessage: (c, m) => print("JS console: ${m.message}"),
      ),
    );
  }
}
