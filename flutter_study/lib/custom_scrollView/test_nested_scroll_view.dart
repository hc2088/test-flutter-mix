// 如果你需要“多个子列表”与“一个外层 SliverAppBar”联动滚动，CustomScrollView 必死。
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NestedRefreshDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NestedRefreshDemo extends StatefulWidget {
  const NestedRefreshDemo({super.key});

  @override
  State<NestedRefreshDemo> createState() => _NestedRefreshDemoState();
}

class _NestedRefreshDemoState extends State<NestedRefreshDemo>
    with TickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  /// 每个 Tab 的独立 RefreshController
  final List<RefreshController> refreshControllers = List.generate(
    3,
    (_) => RefreshController(initialRefresh: false),
  );

  /// 每个 Tab 的列表数据（模拟）
  final List<List<String>> data = [
    List.generate(15, (i) => "推荐 Item $i"),
    List.generate(15, (i) => "热门 Item $i"),
    List.generate(15, (i) => "最新 Item $i"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            const SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              title: Text("Nested + SmartRefresher"),
              flexibleSpace: FlexibleSpaceBar(
                background: ColoredBox(
                  color: Colors.blue,
                  child: Center(
                    child: Text(
                      "顶部可伸缩区域",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),

            // 吸顶 TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabHeaderDelegate(
                child: Material(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    tabs: const [
                      Tab(text: "推荐"),
                      Tab(text: "热门"),
                      Tab(text: "最新"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },

        /// --- 内层，每个 Tab 都有独立 SmartRefresher + ListView ---
        body: TabBarView(
          controller: _tabController,
          children: List.generate(3, (index) {
            return SmartRefresher(
              controller: refreshControllers[index],
              enablePullDown: true,
              enablePullUp: true,
              header: const WaterDropHeader(),
              onRefresh: () => _onRefresh(index),
              onLoading: () => _onLoading(index),

              /// ListView 注意要关闭 primary
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: data[index].length,
                itemBuilder: (_, i) {
                  return Container(
                    height: 70,
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    color: Colors.grey.shade200,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data[index][i],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 下拉刷新
  Future<void> _onRefresh(int index) async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      data[index] = List.generate(15, (i) => "刷新后 Item $i");
    });
    refreshControllers[index].refreshCompleted();
  }

  /// 上拉加载更多
  Future<void> _onLoading(int index) async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      data[index].addAll(List.generate(10, (i) => "更多 Item $i"));
    });
    refreshControllers[index].loadComplete();
  }
}

/// SliverPersistentHeader delegate
class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _TabHeaderDelegate({required this.child});

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  Widget build(_, __, ___) => child;

  @override
  bool shouldRebuild(_) => false;
}
