// lib/main.dart
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: SafeArea(child: CardStackDemo()))));
}

class CardItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  CardItem({required this.title, required this.subtitle, required this.imageUrl});
}

class CardStackDemo extends StatefulWidget {
  const CardStackDemo({Key? key}) : super(key: key);

  @override
  State<CardStackDemo> createState() => _CardStackDemoState();
}

class _CardStackDemoState extends State<CardStackDemo> with SingleTickerProviderStateMixin {
  final List<CardItem> items = List.generate(
    6,
        (i) => CardItem(
      title: '北京的一周生活分周生活 ${i + 1}',
      subtitle: 'Gali（成都灵感相册）',
      imageUrl: 'https://picsum.photos/seed/${100 + i}/800/600',
    ),
  );

  int topIndex = 0; // 当前展示的卡片索引（0 为第一张）
  Offset dragOffset = Offset.zero;
  late AnimationController _animController;
  Animation<Offset>? _animOffset;
  bool isDragging = false;
  bool showOkAnim = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // 判断是否可以下滑查看上一条：
  bool canShowPrevious() {
    return topIndex > 0; // 只有当不是第一张（已经上滑过）才允许下拉查看上一条
  }

  // 执行上滑（切到下一条）
  void _swipeUp() {
    if (topIndex >= items.length - 1) return;
    final begin = dragOffset;
    _animOffset = Tween<Offset>(begin: begin, end: const Offset(0, -1200)).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0).then((_) {
      setState(() {
        topIndex++;
        dragOffset = Offset.zero;
      });
    });
  }

  // 执行下滑（回到上一条）
  void _swipeDown() {
    if (!canShowPrevious()) return;
    // animate top card down off screen then decrease index and reset
    final begin = dragOffset;
    _animOffset = Tween<Offset>(begin: begin, end: const Offset(0, 1200)).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0).then((_) {
      setState(() {
        topIndex = max(0, topIndex - 1);
        dragOffset = Offset.zero;
      });
    });
  }

  // 若未到阈值则回弹
  void _resetPosition() {
    final begin = dragOffset;
    _animOffset = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0).then((_) {
      setState(() {
        dragOffset = Offset.zero;
      });
    });
  }

  Widget _buildCard(CardItem item, {required double scale, required double translateY, bool isTop = false, Widget? overlay}) {
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          height: 540,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withOpacity(0.85),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // image (top)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Image.network(item.imageUrl, fit: BoxFit.cover),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),

                // overlay gradient top title
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(12)),
                        child: const Text('#日常分享', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.emoji_events, color: Colors.yellow),
                    ],
                  ),
                ),

                // bottom caption
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(item.subtitle, style: const TextStyle(color: Colors.white70)),
                ),

                if (overlay != null) overlay,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 空白占位卡（用于初始时上一条占位）
  Widget _placeholderCard({required double scale, required double translateY}) {
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          width: double.infinity,
          height: 540,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.grey.shade900.withOpacity(0.4),
            border: Border.all(color: Colors.white12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
          ),
          child: Center(
            child: Text('上一条（空白占位）', style: TextStyle(color: Colors.white24, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // 构建叠层（最下面的在先渲染）
  List<Widget> _buildStack() {
    List<Widget> widgets = [];
    // show up to 3 cards: top, next1, next2
    for (int i = 2; i >= 0; i--) {
      int idx = topIndex + i;
      double scale = 1 - i * 0.04;
      double translateY = i * 18.0 + (i == 0 ? dragOffset.dy : 0);
      Widget card;
      if (i == 2) {
        // 最底层卡
        if (idx < items.length) {
          card = _buildCard(items[idx], scale: scale, translateY: translateY);
        } else {
          card = Container(); // nothing
        }
      } else if (i == 1) {
        // 中间卡
        if (idx < items.length) {
          card = _buildCard(items[idx], scale: scale, translateY: translateY);
        } else {
          card = Container();
        }
      } else {
        // 顶层
        if (idx < items.length) {
          // overlay for top: show a subtle drag transform
          Widget overlay = Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(min(0.5, dragOffset.distance / 400))]),
                ),
              ),
            ),
          );

          card = _buildCard(items[idx], scale: scale, translateY: translateY, isTop: true, overlay: overlay);
          // wrap with gesture handling
          card = Transform.translate(
            offset: Offset(dragOffset.dx, dragOffset.dy),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // 点击进入沉浸态
                debugPrint('tap: open feed for index $idx');
                // TODO: navigate to feed page
              },
              onLongPress: () {
                // 长按 OK action（示例：短暂展示 OK 动效）
                setState(() => showOkAnim = true);
                Future.delayed(const Duration(milliseconds: 600), () {
                  setState(() => showOkAnim = false);
                });
                debugPrint('long press: ok action index $idx');
              },
              onPanStart: (_) {
                isDragging = true;
                _animController.stop();
              },
              onPanUpdate: (details) {
                setState(() {
                  dragOffset += details.delta;
                });
              },
              onPanEnd: (details) {
                isDragging = false;
                final vy = details.velocity.pixelsPerSecond.dy;
                final dy = dragOffset.dy;
                const threshold = 120; // 上/下滑阈值
                if (dy < -threshold || vy < -800) {
                  // 上滑
                  _swipeUp();
                } else if ((dy > threshold || vy > 800) && canShowPrevious()) {
                  // 下滑并允许查看上一条
                  _swipeDown();
                } else {
                  _resetPosition();
                }
              },
              child: Stack(
                children: [
                  card,
                  // OK 动效圆点（右下）
                  if (showOkAnim)
                    Positioned(
                      right: 28,
                      bottom: 28,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.5, end: 1.2).animate(
                          CurvedAnimation(parent: _animController..forward(from: 0), curve: Curves.elasticOut),
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.yellow),
                          alignment: Alignment.center,
                          child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        } else {
          card = Container();
        }
      }

      // 在 topIndex == 0 情况下，渲染“上一条空白占位”在最上层下方（视觉为固定空白展位）
      if (i == 0 && topIndex == 0) {
        // show placeholder behind the top card (slightly up)
        widgets.add(Positioned.fill(child: _placeholderCard(scale: 0.92, translateY: -40)));
      }

      widgets.add(Positioned.fill(child: card));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在动画并有 _animOffset，我们需要用其值覆盖 dragOffset
    if (_animOffset != null && _animController.isAnimating) {
      final off = _animOffset!.value;
      // animate logically: but we still let build continue (dragOffset replaced visually)
      // we won't mutate dragOffset until animation completion in callbacks above.
      // For simplicity, use Transform on top card (already applied in gesture).
    }

    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // header placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('热门', style: TextStyle(color: Colors.white, fontSize: 18)),
              Text('上滑切换，下滑查看上一条', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: _buildStack(),
              ),
            ),
          ),

          // footer instructions
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              '点击进入，长按 OK，首次进入不可下拉查看上一条',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
