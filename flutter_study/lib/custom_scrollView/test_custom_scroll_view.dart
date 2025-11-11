import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';



void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CustomScrollExample(),
    );
  }
}

class CustomScrollExample extends StatefulWidget {
  @override
  State<CustomScrollExample> createState() => _CustomScrollExampleState();
}

class _CustomScrollExampleState extends State<CustomScrollExample> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void _onRefresh() {
    Future.delayed(const Duration(milliseconds: 1000)).then((_) {
      _refreshController.refreshCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: true,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            /// 可折叠 AppBar
            SliverAppBar(
              title: const Text("CustomScrollView 示例"),
              expandedHeight: 180,
              flexibleSpace: Container(color: Colors.blue),
              pinned: true,
            ),

            /// 吸顶 Header
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  height: 50,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text(
                    "我是吸顶 Header",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            // 把 ListView 当“普通 Widget”嵌进去
            // SliverToBoxAdapter(
            //   child: ListView.builder(
            //     itemCount: 10,
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemBuilder: (_, i) {
            //       return Container(
            //         margin: const EdgeInsets.all(10),
            //         padding: const EdgeInsets.all(20),
            //         color: Colors.grey.shade300,
            //         child: Text("内部 ListView Item $i"),
            //       );
            //     },
            //   ),
            // ),

            /// 列表内容
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    height: 80,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: Text("Item $index"),
                  );
                },
                childCount: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky Header 的 delegate
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(context, shrinkOffset, overlapsContent) => child;

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => false;
}
