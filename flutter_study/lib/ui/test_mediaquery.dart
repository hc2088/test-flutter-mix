import 'package:flutter/material.dart';

//void main() => runApp(MyApp());
void main() {
  runApp(
    Builder(
      builder: (context) {
        // 这里没有 MediaQuery 包裹

        //虽然这段代码似乎是在最顶层调用 MediaQuery.of(context)，按道理“最顶层是没有 MediaQuery 的”，但为何这段代码仍然能正常工作？

        /*
        *
        * 你没有报错的原因是：这个 context 是 Builder 的 context，而不是 MyApp 的 context。

            但是！这个 context 实际上还不是挂在 MaterialApp 之后的 context，也就是说：

              它确实还能访问 MediaQuery.of(context)，说明 Flutter 提前插入了 MediaQuery（某些平台会自动注入）；

              但这在不同平台或版本下不能保证一直有效，仍然是不推荐的用法；

             这个例子里，Flutter engine 已经提供了初始尺寸（可能来源于 window.physicalSize / devicePixelRatio），所以可以用。
        * */

        final mediaQuery = MediaQuery.of(context);

        // 状态栏高度并不是固定值，它包括：
        // 1、 状态栏内容（时间、电池、信号）；
        //
        // 2、 刘海 / notch 区域（iPhone X 系列有）；
        //
        // 3、 系统手势预留空间（某些安卓设备）；
        //
        // 4、 可能还有 系统 UI 缩放、字体放大等影响。

        final double statusBarHeight = mediaQuery.padding.top;

        final double bottomSafeArea = mediaQuery.padding.bottom;

        final double appBarHeight = kToolbarHeight;
        final double bottomBarHeight = kBottomNavigationBarHeight;

        print("statusBarHeight=${statusBarHeight}");
        print("bottomSafeArea=${bottomSafeArea}");
        print("appBarHeight=${appBarHeight}");
        print("bottomBarHeight=${bottomBarHeight}");
        print(MediaQuery.of(context).size); // ❌ 没有报错：No MediaQuery ancestor？？？

        return MyApp();

        // return Container();
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LayoutMetricsPage(),
    );
  }
}

class LayoutMetricsPage extends StatelessWidget {
  const LayoutMetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    //在 build() 方法中通过 MediaQuery.of(context) 获取的值是否 总是有效、是否会出现为 0 的情况？
    //答案是：大多数情况下是安全的，但在某些特殊时机或结构下可能获取到 0，甚至抛出异常。
    //一般情况下是安全的：
    /*
      在正常的 widget build 流程中，MediaQuery.of(context) 会：

        成功从上层查找到最近的 MediaQuery（通常由 MaterialApp 或 WidgetsApp 插入的）；

        返回正确的 MediaQueryData，如屏幕尺寸、padding、safeArea 等。



但以下这些「特殊场景」下，可能会返回 0 或抛错：

   1、   在根 widget 的 build 中直接调用（太早）

void main() {
  runApp(
    Builder(
      builder: (context) {
        // 这里没有 MediaQuery 包裹
        print(MediaQuery.of(context).size); // ❌ 报错：No MediaQuery ancestor
        return MyApp();
      },
    ),
  );
}

  2、在自定义 RenderObjectWidget / RenderObjectElement 中访问
        这些底层 widget 不在 widget 层的 normal tree 中，
        无法从 context 拿到 inherited widget，自然也就无法获得 MediaQuery。

  3、在一些被异步延迟初始化的 widget 的 build 中调用时
        如果你在 FutureBuilder、StreamBuilder 这种构造早、异步加载 late 的 widget 中访问 MediaQuery.of(context)，
        而其 context 是在异步结果未返回之前创建的，可能会出现：
                  拿到的 size 为 0，或者 padding 为 0

    */

    final mediaQuery = MediaQuery.of(context);

    final double statusBarHeight = mediaQuery.padding.top;
    final double bottomSafeArea = mediaQuery.padding.bottom;

    final double appBarHeight = kToolbarHeight;
    final double bottomBarHeight = kBottomNavigationBarHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text("高度信息"),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: bottomBarHeight,
          child: const Center(child: Text("底部TabBar")),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📱 状态栏高度（状态区域/topSafeArea）: $statusBarHeight"),
            Text("🔼 AppBar高度: $appBarHeight"),
            Text("🔽 BottomNavigationBar高度: $bottomBarHeight"),
            Text("📏 底部安全区高度（下巴/bottomSafeArea）: $bottomSafeArea"),
          ],
        ),
      ),
    );
  }
}
