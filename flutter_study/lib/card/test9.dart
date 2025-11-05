import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: CardStackDemo(),
));

class CardItem {
  final String tag;
  final String title;
  final String subtitle;
  final String imageUrl;

  CardItem(this.tag, this.title, this.subtitle, this.imageUrl);
}

class CardStackDemo extends StatefulWidget {
  const CardStackDemo({super.key});

  @override
  State<CardStackDemo> createState() => _CardStackDemoState();
}

class _CardStackDemoState extends State<CardStackDemo>
    with TickerProviderStateMixin {
  final List<CardItem> items = List.generate(
    8,
        (i) => CardItem(
      i.isEven ? '#热门推荐' : '#日常分享',
      '北京的一周生活分享 ${i + 1}',
      'Gali（成都灵感相册）',
      'https://picsum.photos/seed/${i + 30}/800/1200',
    ),
  );

  int topIndex = 0;
  Offset dragOffset = Offset.zero;
  bool animating = false;
  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          dragOffset = Offset.zero;
          animating = false;
        }
      });
  }

  @override
  void dispose() {
    animCtrl.dispose();
    super.dispose();
  }

  bool get canSwipeDown => topIndex > 0;
  bool get canSwipeUp => topIndex < items.length - 1;

  void _animateTo(Offset end, {VoidCallback? onEnd}) {
    animating = true;
    offsetAnim = Tween(begin: dragOffset, end: end)
        .animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOut));
    animCtrl.forward(from: 0).then((_) {
      onEnd?.call();
    });
  }

  void _swipeUp() {
    if (!canSwipeUp) return;
    _animateTo(const Offset(0, -800), onEnd: () {
      setState(() {
        topIndex++;
      });
    });
  }

  void _swipeDown() {
    if (!canSwipeDown) return;
    _animateTo(const Offset(0, 800), onEnd: () {
      setState(() {
        topIndex--;
      });
    });
  }

  void _reset() => _animateTo(Offset.zero);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    const height = 560.0;
    const radius = 22.0;
    const headerHeight = 74.0;
    const peekPrev = 45.0;
    const peekPrev2 = 42.0;
    const tiltPrev = 6 * pi / 180;
    const tiltPrev2 = 10 * pi / 180;

    final currentOffset =
    animating && offsetAnim != null ? offsetAnim!.value : dragOffset;

    // 叠放层（上一张和上上一张的头部）
    final backLayer = Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          height: height,
          child: _BackHeadsLayer(
            prev: (topIndex - 1) >= 0 ? items[topIndex - 1] : null,
            prev2: (topIndex - 2) >= 0 ? items[topIndex - 2] : null,
            width: width,
            height: height,
            radius: radius,
            headerHeight: headerHeight,
            peekPrev: peekPrev,
            peekPrev2: peekPrev2,
            tiltPrev: tiltPrev,
            tiltPrev2: tiltPrev2,
          ),
        ),
      ),
    );

    // 顶部卡片层
    final cards = <Widget>[];
    for (int i = 2; i >= 0; i--) {
      int idx = topIndex - i;
      if (idx < 0) continue;
      final card = _buildCard(
        items[idx],
        isTop: i == 0,
        width: width,
        height: height,
        offset: currentOffset,
      );
      cards.add(card);
    }

    // 下一条占位
    if (topIndex < items.length - 1) {
      cards.insert(
        0,
        Positioned.fill(child: _placeholderCard(scale: 0.9, translateY: 40)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C2C38),
      body: SafeArea(
        child: Stack(
          children: [
            // 顶部导航
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('热门',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('上滑切换 · 下滑查看上一条',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            // 主内容
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    backLayer,
                    ...cards,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(CardItem item,
      {required bool isTop,
        required double width,
        required double height,
        required Offset offset}) {
    final transformOffset = isTop ? offset : Offset.zero;

    return AnimatedBuilder(
      animation: animCtrl,
      builder: (_, __) {
        return Transform.translate(
          offset: transformOffset,
          child: GestureDetector(
            onPanStart: (_) => animCtrl.stop(),
            onPanUpdate: (d) {
              if (!isTop) return;
              setState(() => dragOffset += d.delta);
            },
            onPanEnd: (d) {
              if (!isTop) return;
              final vy = d.velocity.pixelsPerSecond.dy;
              const threshold = 120;
              if (dragOffset.dy < -threshold || vy < -800) {
                _swipeUp();
              } else if (dragOffset.dy > threshold && canSwipeDown) {
                _swipeDown();
              } else {
                _reset();
              }
            },
            child: _buildFullCard(item, width, height),
          ),
        );
      },
    );
  }

  Widget _buildFullCard(CardItem item, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.black54],
              ),
            ),
          ),
          // 头部
          Positioned(
            left: 12,
            right: 12,
            top: 16,
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item.tag,
                      style:
                      const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                const Icon(Icons.emoji_events, color: Colors.amberAccent),
              ],
            ),
          ),
          // 底部
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Text(item.subtitle,
                style:
                const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _placeholderCard({required double scale, required double translateY}) {
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: double.infinity,
          height: 560,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.grey.withOpacity(0.15),
            border: Border.all(color: Colors.white12),
          ),
          alignment: Alignment.center,
          child:
          const Text('下一条为空白展位', style: TextStyle(color: Colors.white24)),
        ),
      ),
    );
  }
}

class _BackHeadsLayer extends StatelessWidget {
  final CardItem? prev;
  final CardItem? prev2;
  final double width;
  final double height;
  final double radius;
  final double headerHeight;
  final double peekPrev;
  final double peekPrev2;
  final double tiltPrev;
  final double tiltPrev2;

  const _BackHeadsLayer({
    required this.prev,
    required this.prev2,
    required this.width,
    required this.height,
    required this.radius,
    required this.headerHeight,
    required this.peekPrev,
    required this.peekPrev2,
    required this.tiltPrev,
    required this.tiltPrev2,
  });

  Widget _fullHead(CardItem item) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.black54],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 16,
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item.tag,
                      style:
                      const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                const Icon(Icons.emoji_events,
                    color: Colors.amberAccent, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(double opacity) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white.withOpacity(opacity),
    ),
  );

  Widget _head({
    required Widget card,
    required double topOffset,
    required double tilt,
  }) {
    return Positioned(
      top: -topOffset,
      right: 0, // ✅ 保证右侧完全对齐
      height: height,
      width: width,
      child: Transform(
        alignment: Alignment.topRight, // ✅ 右上角为旋转轴心
        transform: Matrix4.identity()..rotateZ(tilt),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ClipRect(
            clipper: _HeaderClipper(headerHeight),
            child: card,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (prev2 != null || prev == null)
            _head(
              card: prev2 != null ? _fullHead(prev2!) : _placeholder(0.08),
              topOffset: peekPrev + peekPrev2,
              tilt: tiltPrev2,
            ),
          _head(
            card: prev != null ? _fullHead(prev!) : _placeholder(0.12),
            topOffset: peekPrev,
            tilt: tiltPrev,
          ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Rect> {
  final double headerHeight;
  _HeaderClipper(this.headerHeight);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, headerHeight);
  @override
  bool shouldReclip(covariant _HeaderClipper oldClipper) =>
      oldClipper.headerHeight != headerHeight;
}
