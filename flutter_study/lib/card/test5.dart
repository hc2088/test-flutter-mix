import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: CardStackPage()));

class CardItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  CardItem(this.title, this.subtitle, this.imageUrl);
}

class CardStackPage extends StatefulWidget {
  const CardStackPage({super.key});

  @override
  State<CardStackPage> createState() => _CardStackPageState();
}

class _CardStackPageState extends State<CardStackPage> with TickerProviderStateMixin {
  final List<CardItem> items = List.generate(
    6,
        (i) => CardItem(
      '北京的一周生活 ${i + 1}',
      'Gali（成都灵感相册）',
      'https://picsum.photos/seed/${i + 100}/800/1200',
    ),
  );

  int topIndex = 0;
  Offset dragOffset = Offset.zero;
  bool showOK = false;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;
  bool animating = false;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragOffset = Offset.zero;
            animating = false;
          });
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
      if (onEnd != null) onEnd();
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
    final currentOffset = animating && offsetAnim != null ? offsetAnim!.value : dragOffset;
    final cards = <Widget>[];

    // 最多渲染 3 层
    for (int i = 2; i >= 0; i--) {
      int idx = topIndex - i;
      if (idx < 0) continue;

      final scale = 1 - i * 0.04;
      final dy = -i * 20.0; // 往上挪一点
      final opacity = 1.0 - i * 0.15;
      final angle = i == 0 ? 0.0 : (i == 1 ? 6 : 10) * pi / 180; // 往右倾斜（左高右低）

      final card = _buildCard(items[idx], i == 0, scale, dy, opacity, currentOffset, angle);
      cards.add(card);
    }

    // 下一条占位
    if (topIndex < items.length - 1) {
      cards.insert(
          0,
          Positioned.fill(
              child: _placeholderCard(scale: 0.9, translateY: 40)));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('热门', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('上滑切换 · 下滑查看上一条', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Stack(alignment: Alignment.center, children: cards),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(CardItem item, bool isTop, double scale, double translateY,
      double opacity, Offset offset, double angle) {
    final transformOffset = isTop ? offset : Offset.zero;

    return AnimatedBuilder(
      animation: animCtrl,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(transformOffset.dx, transformOffset.dy + translateY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: angle,
              child: Opacity(
                opacity: opacity,
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
                    } else if (dragOffset.dy > threshold || vy > 800) {
                      _swipeDown();
                    } else {
                      _reset();
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 520,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Image.network(item.imageUrl,
                                  fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black38, Colors.black54],
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('#日常分享',
                                          style: TextStyle(color: Colors.white, fontSize: 12)),
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
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 20,
                                child: Text(item.subtitle,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showOK && isTop)
                        const Positioned(
                          right: 36,
                          bottom: 36,
                          child: _OKAnimation(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderCard({required double scale, required double translateY}) {
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: double.infinity,
          height: 520,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.withOpacity(0.15),
            border: Border.all(color: Colors.white12),
          ),
          alignment: Alignment.center,
          child: const Text('下一条为空白展位', style: TextStyle(color: Colors.white24)),
        ),
      ),
    );
  }
}

class _OKAnimation extends StatefulWidget {
  const _OKAnimation();

  @override
  State<_OKAnimation> createState() => _OKAnimationState();
}

class _OKAnimationState extends State<_OKAnimation> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    scale = CurvedAnimation(parent: ctrl, curve: Curves.elasticOut);
    fade = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);
    ctrl.forward();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
          alignment: Alignment.center,
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
      ),
    );
  }
}
