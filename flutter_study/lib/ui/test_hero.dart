import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero简单示例")),
      body: Center(
        child: GestureDetector(
          onTap: () {
            //1、Navigator 是什么？
            //  Navigator 就是 Flutter 的“页面栈”。
            //Navigator 是一个 路由管理器，内部维护一个 路由栈，list
            // Navigator.push(
            // //页面 = Route（比如MaterialPageRoute）
            // //栈顶的 Route 就是当前显示的页面。
            //     context, MaterialPageRoute(builder: (_) => const DetailPage()));

            //2、Navigator.of(context)
            //通过 context 往上查找树中的最近的 Navigator widget，拿到它的状态对象 NavigatorState。


            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DetailPage()));


            //后续的 push/pop 操作其实都是调用 NavigatorState 的方法。

            //3、push(route) 做了什么？

            /***
             *
             * Future<T?> push<T extends Object?>(Route<T> route) {
                // 1. 包装成 RouteEntry 加入栈顶
                _history.add(_RouteEntry(route));

                // 2. 调用 Route 生命周期
                route.install(this);   // 把页面挂载到 Navigator 的 Overlay
                route.didPush();       // 执行入场动画

                // 3. 返回一个 Future，在这个 route 被 pop 时完成
                return route.popped;
                }
             *
             *
             *
             */


            //4、页面是怎么切换的？
           /* Overlay（叠加层）

           1、 Navigator 内部有一个 Overlay，它是一个 Widget 叠层容器。

           2、 每个 Route 都会创建一个 OverlayEntry。

           3、 install() 时，把新 Route 的 entry 插到 Overlay 顶部。

           4、 Flutter 重建时，Overlay 最上面的 entry（新页面）就显示出来，旧页面变成下层不可见。

           5、 动画（slide、fade 等）就是在 Overlay 里完成的。

            👉 页面切换 = 给 Overlay 插入一个新的 entry，并播放入场动画。*/
            /*
            * 总结：Navigator.of(context).push(route) 能切换页面，是因为：

                 1、 Navigator 内部维护路由栈，push 会把新 Route 压入栈顶；

                 2、2Overlay 管理页面渲染，新 Route 的 OverlayEntry 被插入到最上层；

                 3、 Route 生命周期（install/didPush）负责初始化和入场动画；

                 4、 push 返回的 Future 会在 pop 时完成，从而支持返回结果。

                  👉 本质上：Navigator 就是一个“基于栈的路由管理器 + Overlay 渲染器”。
            *
            *
            * */


            /*
            根 Widget 与 Overlay 的关系

            整个层级关系（简化版）大概是这样的：

              runApp(MyApp)
                 ↓
              MaterialApp （应用框架）//class MaterialApp extends StatefulWidget
                 ↓
              WidgetsApp  //class WidgetsApp extends StatefulWidget
                 ↓
              Navigator （路由管理）// class Navigator extends StatefulWidget Overlay 就是在 Navigator 内部被创建和管理的。
                 ↓
              Overlay （层叠容器） //class Overlay extends StatefulWidget
                  Overlay = 一个特殊的 Stack，里面放着很多层（OverlayEntry），每一层可以是一个页面或浮层。

                 ↓
              OverlayEntry（具体的页面/弹窗/浮层） //class OverlayEntry implements Listenable
                class _OverlayEntryWidget extends StatefulWidget

              1、  根 Widget (MaterialApp) 提供了应用框架（主题、导航、路由）。

              2、  Navigator 管理路由栈，每次 push/pop 都会改变 Overlay 的 Entry。

             3、   Overlay 负责把所有页面和浮层叠在一起渲染。
            *  //页面切换、Dialog、SnackBar、Hero 动画，本质上都是 往 Overlay 里插入/移除 Entry。
            *
            * */
          },
          child: const Hero(
            tag: 'avatar1',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("详情页")),
      body: const Align(
        alignment: Alignment.topCenter,
        child: Hero(
          tag: 'avatar',
          child: CircleAvatar(
            radius: 120,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 120, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
