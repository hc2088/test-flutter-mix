import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, home: CardStackPage()));

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

class _CardStackPageState extends State<CardStackPage>
    with TickerProviderStateMixin {
  final List<CardItem> items = List.generate(
    100,
    (i) => CardItem(
      '北京的一周生活 ${i + 1}',
      'Gali（成都灵感相册）',
      'https://picsum.photos/seed/${i + 100}/800/1200',
    ),
  );

  int topIndex = 0;
  Offset dragOffset = Offset.zero;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;
  bool animating = false;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
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

  void _animateTo(Offset end, {VoidCallback? onEnd, int durationMs = 320}) {
    if (animating) return;
    animating = true;

    animCtrl.duration = Duration(milliseconds: durationMs);
    offsetAnim = Tween(begin: dragOffset, end: end)
        .animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOut));

    // 🚀 动画启动
    animCtrl.forward(from: 0).then((_) {
      _finishAnimation(onEnd);
    });

    // 🧩 安全兜底：防止系统未触发 completed
    Future.delayed(Duration(milliseconds: durationMs + 100), () {
      if (animating) _finishAnimation(onEnd);
    });
  }

  void _finishAnimation(VoidCallback? onEnd) {
    if (!mounted) return;
    setState(() {
      dragOffset = Offset.zero;
      animating = false;
    });
    onEnd?.call();
  }

  void _swipeDownFast(bool fast) {
    if (!canSwipeDown || animating) return;
    _animateTo(const Offset(0, 800), durationMs: fast ? 160 : 220, onEnd: () {
      setState(() {
        topIndex--;
        animating = false;
      });
    });
  }

  void _reset() => _animateTo(Offset.zero);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentOffset =
        animating && offsetAnim != null ? offsetAnim!.value : dragOffset;

    final cards = <Widget>[];

    // 最多显示三层：当前、上一张、上上一张
    for (int i = 2; i >= 0; i--) {
      int idx = topIndex - i;
      final baseWidth = screenWidth - 32;
      double cardWidth = baseWidth;
      double leftInset = 0;
      double angle = 0;
      double dy = 0;

      if (i == 1) {
        leftInset = 4;
        cardWidth = baseWidth - 2 * leftInset;
        angle = 3.8 * pi / 180;
        dy = -20;
      } else if (i == 2) {
        leftInset = 14;
        cardWidth = baseWidth - 2 * leftInset;
        angle = 7.6 * pi / 180;
        dy = -40;
      }

      double opacity = 1.0;
      if (i == 1) opacity = 0.6;
      if (i == 2) opacity = 0.3;

      // ✅ 如果 idx < 0，则显示空卡片
      if (idx < 0) {
        final color = i == 1
            ? const Color(0xFF6B8E68) // 第二层主题色
            : const Color(0xFF4F6A4D); // 第三层主题色
        cards.add(
          _buildEmptyCard(
            translateY: dy,
            translateX: leftInset,
            opacity: opacity,
            angle: angle,
            color: color,
            width: cardWidth,
          ),
        );
        continue;
      }

      final card = _buildCard(
        items[idx],
        i == 0,
        1.0 - i * 0.05,
        dy,
        leftInset,
        opacity,
        currentOffset,
        angle,
        width: cardWidth,
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
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: cards,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required double translateY,
    required double translateX,
    required double opacity,
    required double angle,
    required Color color,
    required double width,
  }) {
    // ✅ 先包一层 Padding 而不是让 Container 自带 margin
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Transform.translate(
        offset: Offset(translateX, translateY),
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.topRight,
          child: _applyVisualDimmer(
            opacity: opacity,
            child: Container(
              width: width,
              height: 520,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    CardItem item,
    bool isTop,
    double scale,
    double translateY,
    double translateX,
    double opacity,
    Offset offset,
    double angle, {
    required double width,
  }) {
    final transformOffset = isTop ? offset : Offset.zero;

    return AnimatedBuilder(
      animation: animCtrl,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(transformOffset.dx, transformOffset.dy + translateY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(-angle * 80, 0),
              child: Transform.rotate(
                angle: angle,
                alignment: Alignment.topRight,
                child: _applyVisualDimmer(
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
                        final fast = vy < -1500; // 🚀 高速上滑
                        _swipeUpFast(fast);
                      } else if (dragOffset.dy > threshold && canSwipeDown) {
                        final fast = vy > 1500;
                        _swipeDownFast(fast);
                      } else {
                        _reset();
                      }
                    },
                    child: _CardContent(item: item, width: width, isTop: isTop),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _swipeUpFast(bool fast) {
    _animateTo(
      const Offset(0, -800),
      durationMs: fast ? 160 : 220, // 快速滑动时更短动画
      onEnd: () {
        if (!mounted) return;
        setState(() {
          topIndex++;
        });
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
            color: Colors.grey.withValues(alpha: 0.15),
            border: Border.all(color: Colors.white12),
          ),
          alignment: Alignment.center,
          child:
              const Text('下一条为空白展位', style: TextStyle(color: Colors.white24)),
        ),
      ),
    );
  }

  Widget _applyVisualDimmer({
    required Widget child,
    required double opacity,
  }) {
    if (opacity >= 0.99) return child;

    return IgnorePointer(
      // 不影响交互
      child: DecoratedBox(
        position: DecorationPosition.foreground, // 👈 在前景绘制遮罩层
        decoration: BoxDecoration(
          color: Colors.black.withOpacity((1 - opacity) * 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}

class _CardContent extends StatefulWidget {
  final CardItem item;
  final double width;
  final bool isTop;

  const _CardContent({
    required this.item,
    required this.width,
    required this.isTop,
  });

  @override
  State<_CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<_CardContent>
    with SingleTickerProviderStateMixin {
  bool imageLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final width = widget.width;

    return Stack(
      children: [
        Container(
          width: width,
          height: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4A4A4A),
              width: 0.5,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ✅ 背景渐变层
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF050505), Color(0xFF050505)],
                      ),
                    ),
                  ),
                ),

                // 🌟 ✅ 模糊金色光晕层（仅在图片加载成功后显示）
                if (imageLoaded)
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 80, // 控制模糊强度
                        sigmaY: 80,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0.0, -0.15),
                            radius: 2,
                            colors: [
                              Color(0xCC8C753B), // 中心金色发光（稍微更亮）
                              Color(0x008C753B), // 边缘透明
                            ],
                            stops: [0.0, 0.35],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ✅ 内容层
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 10,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF7A7573),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/hot.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                                const Text('#日常分享',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: const Color(0xFF363636),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Image.asset(
                              'assets/images/ok.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      Text(item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 25),

                      // ✅ 图片加载监听
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            fadeOutDuration: const Duration(milliseconds: 0),
                            fadeInDuration: const Duration(milliseconds: 0),
                            imageBuilder: (context, imageProvider) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    imageLoaded = true;
                                  });
                                }
                              });
                              return Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              );
                            },
                            placeholder: (context, url) => Container(
                              color: Colors.black12,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ 底部提示文案
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('让你的表达被看见',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
