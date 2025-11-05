import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CardStackPage(),
    ));

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
  bool showNextCard = false;
  bool animating = false;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;

  late AnimationController exitCtrl;
  Animation<Offset>? exitAnim;

  late AnimationController nextCardCtrl;
  Animation<Offset>? nextCardOffsetAnim;

  late AnimationController prevStackCtrl;
  bool prevStackActive = false;

  /// 新增：上滑时堆叠轻微上推
  late AnimationController nextStackCtrl;
  bool nextStackActive = false;

  @override
  void initState() {
    super.initState();

    animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..addListener(() => setState(() {}));

    exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280))
      ..addListener(() => setState(() {}));

    nextCardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() => setState(() {}));

    prevStackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() => setState(() {}));

    nextStackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    animCtrl.dispose();
    exitCtrl.dispose();
    nextCardCtrl.dispose();
    prevStackCtrl.dispose();
    nextStackCtrl.dispose();
    super.dispose();
  }

  bool get canSwipeDown => topIndex > 0;

  bool get canSwipeUp => topIndex < items.length - 1;

  void _reset() {
    if (animating) return;
    animating = true;
    offsetAnim = Tween(begin: dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOut));
    animCtrl.forward(from: 0).then((_) {
      setState(() {
        dragOffset = Offset.zero;
        animating = false;
      });
    });
  }

  /// ✅ 上滑带堆叠联动
  void _swipeUpLinked() {
    if (!canSwipeUp || animating) return;
    animating = true;
    showNextCard = true;
    nextStackActive = true;

    // 顶卡飞出
    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, -800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    // 下一张推入
    nextCardCtrl.reset();
    nextCardOffsetAnim = Tween(begin: const Offset(0, 180), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: nextCardCtrl, curve: Curves.easeOutCubic));

    // 堆叠上推
    nextStackCtrl.reset();

    Future.wait([
      exitCtrl.forward(from: 0),
      nextCardCtrl.forward(from: 0),
      nextStackCtrl.forward(from: 0),
    ]).then((_) {
      if (!mounted) return;
      nextStackCtrl.animateTo(0.999, duration: Duration.zero);
      nextStackActive = false;
      setState(() {
        topIndex++;
        exitAnim = null;
        showNextCard = false;
        animating = false;
        dragOffset = Offset.zero;
      });
    });
  }

  /// ✅ 下滑堆叠前推
  void _swipeDownLinked() {
    if (!canSwipeDown || animating) return;
    animating = true;
    prevStackActive = true;

    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, 800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    prevStackCtrl.reset();

    Future.wait([
      exitCtrl.forward(from: 0),
      prevStackCtrl.forward(from: 0),
    ]).then((_) {
      if (!mounted) return;
      prevStackCtrl.animateTo(0.999, duration: Duration.zero);
      prevStackActive = false;
      setState(() {
        topIndex--;
        exitAnim = null;
        animating = false;
        dragOffset = Offset.zero;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    const dy1 = 0.0;
    const angle1 = 0.0;
    const scale1 = 1.0;
    const opacity1 = 1.0;

    const dy2 = -20.0;
    const angle2 = 3.8 * pi / 180;
    const scale2 = 0.95;
    const opacity2 = 0.6;

    const dy3 = -40.0;
    const angle3 = 7.6 * pi / 180;
    const scale3 = 0.9;
    const opacity3 = 0.3;

    final currentOffset = (() {
      if (exitAnim != null) return exitAnim!.value;
      if (offsetAnim != null && animCtrl.isAnimating) return offsetAnim!.value;
      return dragOffset;
    })();

    final cards = <Widget>[];

    final visibleCount = (prevStackActive ||
            prevStackCtrl.isAnimating ||
            nextStackActive ||
            nextStackCtrl.isAnimating)
        ? 3
        : 2;

    for (int i = visibleCount; i >= 0; i--) {
      if (showNextCard && exitAnim == null && i == 0) continue;
      final idx = topIndex - i;
      final baseWidth = w - 32;

      double leftInset = 0;
      double baseAngle = 0;
      double baseDy = 0;
      double baseScale = 1.0 - i * 0.05;
      double baseOpacity = 1.0;
      double cardWidth = baseWidth;

      if (i == 1) {
        leftInset = 4;
        cardWidth = baseWidth - 8;
        baseAngle = 3.8 * pi / 180;
        baseDy = -20;
        baseOpacity = 0.6;
      } else if (i == 2) {
        leftInset = 14;
        cardWidth = baseWidth - 28;
        baseAngle = 7.6 * pi / 180;
        baseDy = -40;
        baseOpacity = 0.3;
      } else if (i == 3) {
        leftInset = 22;
        cardWidth = baseWidth - 44;
        baseAngle = 11 * pi / 180;
        baseDy = -60;
        baseOpacity = 0.15;
      }

      double angle = baseAngle,
          dy = baseDy,
          scale = baseScale,
          opacity = baseOpacity;
      double tDown = 0.0, tUp = 0.0;

      if (prevStackActive || prevStackCtrl.isAnimating) {
        final rawT = prevStackCtrl.value;
        tDown = Curves.easeInOutCubic.transform(rawT);
      }
      if (nextStackActive || nextStackCtrl.isAnimating) {
        final rawT = nextStackCtrl.value;
        tUp = Curves.easeInOutCubic.transform(rawT);
      }

      // 下滑插值
      if (tDown > 0) {
        if (i == 1) {
          angle = _lerp(baseAngle, angle1, tDown);
          dy = _lerp(baseDy, dy1, tDown);
          scale = _lerp(baseScale, scale1, tDown);
          opacity = _lerp(baseOpacity, opacity1, tDown);
        } else if (i == 2) {
          angle = _lerp(baseAngle, angle2, tDown);
          dy = _lerp(baseDy, dy2, tDown);
          scale = _lerp(baseScale, scale2, tDown);
          opacity = _lerp(baseOpacity, opacity2, tDown);
        }
      }

      // 上滑插值（反向推上来）
      if (tUp > 0) {
        if (i == 1) {
          angle = _lerp(baseAngle, angle3, tUp);
          dy = _lerp(baseDy, -40, tUp);
          scale = _lerp(baseScale, 0.9, tUp);
          opacity = _lerp(baseOpacity, 0.3, tUp);
        } else if (i == 2) {
          angle = _lerp(baseAngle, angle2, tUp);
          dy = _lerp(baseDy, -20, tUp);
          scale = _lerp(baseScale, 0.95, tUp);
          opacity = _lerp(baseOpacity, 0.6, tUp);
        }
      }

      final isTop = (i == 0);
      Widget cardBody;
      if (idx < 0 || idx >= items.length) {
        final color = Colors.grey.shade700;
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: Container(color: color.withOpacity(0.25)),
        );
      } else {
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: _CardContent(item: items[idx], width: cardWidth, isTop: isTop),
        );
      }

      cards.add(_wrapTransforms(
        child: GestureDetector(
          onPanStart: (_) => animCtrl.stop(),
          onPanUpdate: (d) {
            if (!isTop) return;
            setState(() => dragOffset += d.delta / 1.1);
          },
          onPanEnd: (d) {
            if (!isTop) return;
            final vy = d.velocity.pixelsPerSecond.dy;
            const threshold = 120;
            if (dragOffset.dy < -threshold || vy < -800) {
              _swipeUpLinked();
            } else if (dragOffset.dy > threshold && canSwipeDown) {
              _swipeDownLinked();
            } else {
              _reset();
            }
          },
          child: cardBody,
        ),
        translateX: leftInset + (isTop ? currentOffset.dx : 0),
        translateY: (isTop ? currentOffset.dy : 0) + dy,
        angle: angle,
        scale: scale,
        tDown: max(tDown, tUp),
      ));
    }

    // 下一张推入
    if (showNextCard && topIndex < items.length - 1) {
      final nextOffset = nextCardOffsetAnim?.value ?? const Offset(0, 150);
      cards.add(Transform.translate(
        offset: nextOffset,
        child: _buildCardShell(
          width: w - 32,
          opacity: 0.85,
          child: _CardContent(
              item: items[topIndex + 1], width: w - 32, isTop: false),
        ),
      ));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: cards,
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Widget _buildCardShell({
    required double width,
    required Widget child,
    required double opacity,
  }) {
    return _applyVisualDimmer(
      opacity: opacity,
      child: Container(
        width: width,
        height: 520,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4A4A4A), width: 0.5),
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
          child: child,
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

  Widget _wrapTransforms({
    required Widget child,
    required double translateX,
    required double translateY,
    required double angle,
    required double scale,
    double tDown = 0.0,
  }) {
    return Transform.translate(
      offset: Offset(translateX, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.topRight,
          child: Transform.translate(
            offset: Offset(-angle * 20 * (1 - tDown), 0),
            child: child,
          ),
        ),
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
                                Text('#日常分享-${item.title}',
                                    style: const TextStyle(
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
                              color: Colors.transparent,
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
