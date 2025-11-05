import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MaterialApp(home: FeedStackPage()));
}

class FeedStackPage extends StatefulWidget {
  const FeedStackPage({super.key});

  @override
  State<FeedStackPage> createState() => _FeedStackPageState();
}

class _FeedStackPageState extends State<FeedStackPage> {
  final PageController _controller = PageController(viewportFraction: 0.85);

  final List<Map<String, String>> items = List.generate(8, (i) => {
    'title': '卡片标题 $i',
    'subtitle': '这是第 $i 条内容，带有一些描述文字。',
    'image': 'https://picsum.photos/400/600?random=$i',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: PageView.builder(
        controller: _controller,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = 0;
              if (_controller.position.haveDimensions) {
                value = _controller.page! - index;
              } else {
                value = _controller.initialPage - index.toDouble();
              }
              // 限制 [-1, 1] 范围
              value = value.clamp(-1, 1);

              // 卡片纵向上移
              double translateY = value * -50;
              // 卡片旋转（向上滑时后面的轻微倾斜）
              double rotation = value * 0.05;
              // 缩放效果
              double scale = 1 - (value.abs() * 0.05);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(0.0, translateY)
                  ..rotateZ(rotation)
                  ..scale(scale),
                child: Opacity(
                  opacity: 1 - value.abs() * 0.3,
                  child: FeedCard(
                    title: items[index]['title']!,
                    subtitle: items[index]['subtitle']!,
                    image: items[index]['image']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FeedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;

  const FeedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(image, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
