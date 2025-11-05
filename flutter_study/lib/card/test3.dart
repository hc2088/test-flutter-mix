import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: FeedStackPage()));

class FeedStackPage extends StatefulWidget {
  const FeedStackPage({super.key});

  @override
  State<FeedStackPage> createState() => _FeedStackPageState();
}

class _FeedStackPageState extends State<FeedStackPage> {
  final FixedExtentScrollController _controller =
  FixedExtentScrollController(initialItem: 0);

  final List<String> images = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
    'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
    'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c',
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔹主滚动视图（实现上上条可见）
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: screenH * 0.8, // 当前卡片占80%高度
            perspective: 0.002, // 轻微透视
            diameterRatio: 2.0, // 控制上上条可见程度
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) => setState(() => _currentIndex = i),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= images.length) return null;
                return _buildFeedCard(context, index);
              },
              childCount: images.length,
            ),
          ),

          // 🔹固定层 - 顶部标题/Tab区
          Positioned(
            top: 60,
            left: 16,
            child: Row(
              children: [
                _buildTab("🔥 热门推荐", active: true),
                const SizedBox(width: 8),
                _buildTab("👀 关注", active: false),
              ],
            ),
          ),

          // 🔹固定层 - 底部slogan
          Positioned(
            bottom: 80,
            left: 16,
            child: const Text(
              "让感受沉浸于光影之间 🌄",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, int index) {
    final isCurrent = index == _currentIndex;
    final image = images[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: isCurrent ? 0 : 20),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
        // overflow: DecorationOverflow.clip,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(image, fit: BoxFit.cover),

          // 渐变遮罩
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),

          // 卡片内容
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "第 ${index + 1} 条内容",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "北京的一周生活分享：北疆的金秋",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 🔹非当前卡片添加半透明层，制造「上一个/上上个」效果
          if (!isCurrent)
            Container(
              color: Colors.black.withOpacity(index < _currentIndex ? 0.3 : 0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.orange : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
        TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 14),
      ),
    );
  }
}
