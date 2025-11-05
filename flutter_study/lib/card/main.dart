import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: FeedHomePage()));

class FeedHomePage extends StatefulWidget {
  const FeedHomePage({super.key});

  @override
  State<FeedHomePage> createState() => _FeedHomePageState();
}

class _FeedHomePageState extends State<FeedHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  double _currentPage = 0.0;

  final List<Map<String, String>> hotList = [
    {
      'image':
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      'title': '北京的一周生活分享：北疆的金秋',
      'author': 'Gail（成就感摄影版）',
      'slogan': '让感受沉浸于光影之间 🌄',
    },
    {
      'image':
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
      'title': '呼伦贝尔的秋天，光影流动的草原',
      'author': '摄影师Leo',
      'slogan': '慢下来，看看风的方向 🍂',
    },
    {
      'image':
      'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?w=800',
      'title': '西藏旅拍纪实',
      'author': '摄影师Mia',
      'slogan': '灵魂走得比脚还远 ✨',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildPageView(context),
            _buildTopBar(),
            _buildSloganLayer(),
          ],
        ),
      ),
    );
  }

  // 顶部 tab + 状态栏
  Widget _buildTopBar() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: '🔥 热门推荐'),
              Tab(text: '👀 我的关注'),
            ],
          ),
        ],
      ),
    );
  }

  // slogan 固定层
  Widget _buildSloganLayer() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Nook 让生活灵感被看见 ✨',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 主体卡片滑动区
  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: hotList.length,
      itemBuilder: (context, index) {
        final scale =
        (index == _currentPage.floor()) ? 1.0 : 0.9; // 当前卡片放大一点
        final opacity =
        (index == _currentPage.floor()) ? 1.0 : 0.5; // 非当前卡片半透明

        final data = hotList[index];

        return Transform.scale(
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: opacity,
            child: GestureDetector(
              onTap: () => debugPrint('进入第 $index 条内容详情'),
              onLongPress: () => debugPrint('长按 OK 操作：${data['title']}'),
              child: Container(
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // overflow: DecorationOverflow.clip,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 封面图 9:16
                    AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Image.network(
                        data['image']!,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // 渐变遮罩层
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),

                    // 卡片内文字信息
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标签行
                          const Text(
                            "🔥 热门推荐",
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          // 标题
                          Text(
                            data['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // 作者昵称
                          Text(
                            data['author']!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
