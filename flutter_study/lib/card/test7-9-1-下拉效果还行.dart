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

  /// =============================
  /// 上滑查看下一张动画
  /// =============================
  late AnimationController exitCtrl; // 当前卡片飞出控制器
  Animation<Offset>? exitAnim; // 当前卡片飞出位移动画

  late AnimationController animCtrl; // 拖拽松手后的复位动画
  Animation<Offset>? offsetAnim; // 回弹动画
  Animation<Offset>? nextCardOffsetAnim; // 下一张卡片的上推动画
  late AnimationController nextCardCtrl; // 下一张卡片推入控制器

  /// =============================
  /// 下滑查看上一张动画
  /// =============================
  late AnimationController prevStackCtrl; // 控制堆叠卡片联动
  Animation<Offset>? prevCardOffsetAnim; // 上一张卡片上移动画
  Animation<double>? prevCardAngleAnim; // 堆叠旋转动画

  @override
  void initState() {
    super.initState();

    animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragOffset = Offset.zero;
            animating = false;
          });
        }
      });

    exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() => setState(() {}));

    prevStackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));

    nextCardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    animCtrl.dispose();
    exitCtrl.dispose();
    prevStackCtrl.dispose();
    nextCardCtrl.dispose();
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

    animCtrl.forward(from: 0).then((_) => _finishAnimation(onEnd));
  }

  void _finishAnimation(VoidCallback? onEnd) {
    if (!mounted) return;
    setState(() {
      dragOffset = Offset.zero;
      animating = false;
    });
    onEnd?.call();
  }

  void _reset() => _animateTo(Offset.zero);

  /// ✅ 向上滑动：查看下一张
  void _swipeUpFast(bool fast) {
    if (!canSwipeUp || animating) return;
    animating = true;
    showNextCard = true;

    // 当前卡片飞出
    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, -800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    // 下一张卡片推入
    nextCardCtrl.reset();
    nextCardOffsetAnim = Tween(begin: const Offset(0, 150), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: nextCardCtrl,
      curve: Curves.easeOutCubic,
    ));

    exitCtrl.forward().then((_) async {
      setState(() {
        topIndex++;
        exitAnim = null;
        dragOffset = Offset.zero;
      });

      nextCardCtrl.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          animating = false;
          showNextCard = false;
          nextCardOffsetAnim = null;
        });
      });
    });
  }

  /// ✅ 向下滑动：查看上一张
  void _swipeDownFast(bool fast) {
    if (!canSwipeDown || animating) return;
    animating = true;
    showNextCard = false;

    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, 800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    exitCtrl.forward().then((_) async {
      if (!mounted) return;

      setState(() {
        topIndex--;
        exitAnim = null;
        dragOffset = Offset.zero;
      });

      prevStackCtrl.reset();
      prevCardOffsetAnim = Tween<Offset>(
        begin: const Offset(0, 100),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: prevStackCtrl,
        curve: Curves.easeOutBack,
      ));

      prevCardAngleAnim = Tween<double>(
        begin: -8 * pi / 180,
        end: 0,
      ).animate(CurvedAnimation(
        parent: prevStackCtrl,
        curve: Curves.easeOutBack,
      ));

      prevStackCtrl.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          animating = false;
          prevCardOffsetAnim = null;
          prevCardAngleAnim = null;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ 优先级判断：先动画值，再回弹，再拖动（恢复手指拖拽跟随）
    final currentOffset = (() {
      if (exitAnim != null) return exitAnim!.value;
      if (offsetAnim != null && animCtrl.isAnimating) return offsetAnim!.value;
      return dragOffset;
    })();

    final cards = <Widget>[];

    for (int i = 2; i >= 0; i--) {
      if (showNextCard && exitAnim == null && i == 0) continue;
      if (prevCardOffsetAnim != null && i == 1) continue;

      final idx = topIndex - i;
      final baseWidth = screenWidth - 32;

      double leftInset = 0;
      double angle = 0;
      double dy = 0;
      double scale = 1.0 - i * 0.05;
      double opacity = 1.0;
      double cardWidth = baseWidth;

      if (i == 1) {
        leftInset = 4;
        cardWidth = baseWidth - 8;
        angle = 3.8 * pi / 180;
        dy = -20;
        opacity = 0.6;
      } else if (i == 2) {
        leftInset = 14;
        cardWidth = baseWidth - 28;
        angle = 7.6 * pi / 180;
        dy = -40;
        opacity = 0.3;
      }

      Widget cardBody;
      bool isTop = (i == 0);

      if (idx < 0) {
        final color =
            (i == 1) ? const Color(0xFF6B8E68) : const Color(0xFF4F6A4D);
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.9),
                  color.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        );
      } else {
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: _CardContent(item: items[idx], width: cardWidth, isTop: isTop),
        );
      }

      final wrapped = _wrapTransforms(
        child: (idx >= 0)
            ? GestureDetector(
                onPanStart: (_) => animCtrl.stop(),
                onPanUpdate: (d) {
                  if (!isTop) return;
                  // ✅ 拖动时立即响应位置变化（带轻微阻尼）
                  setState(() => dragOffset += d.delta / 1.1);
                },
                onPanEnd: (d) {
                  if (!isTop) return;
                  final vy = d.velocity.pixelsPerSecond.dy;
                  const threshold = 120;
                  if (dragOffset.dy < -threshold || vy < -800) {
                    _swipeUpFast(vy < -1500);
                  } else if (dragOffset.dy > threshold && canSwipeDown) {
                    _swipeDownFast(vy > 1500);
                  } else {
                    _reset();
                  }
                },
                child: cardBody,
              )
            : cardBody,
        translateX: leftInset + (isTop ? currentOffset.dx : 0),
        // ✅ 拖动跟随手指
        translateY: (isTop ? currentOffset.dy : 0) + dy,
        angle: angle,
        scale: scale,
      );

      cards.add(wrapped);
    }

    // 下滑：上一张卡片弹性顶上来
    if (prevCardOffsetAnim != null && topIndex > 0) {
      final prevOffset = prevCardOffsetAnim!.value;
      final prevAngle = prevCardAngleAnim?.value ?? 0.0;
      cards.add(
        Transform.translate(
          offset: prevOffset,
          child: Transform.rotate(
            angle: prevAngle,
            alignment: Alignment.topRight,
            child: _buildCardShell(
              width: screenWidth - 32,
              opacity: 1.0,
              child: _CardContent(
                item: items[topIndex - 1],
                width: screenWidth - 32,
                isTop: false,
              ),
            ),
          ),
        ),
      );
    }

    // 上滑：下一张卡片推入
    if (showNextCard && exitAnim == null && topIndex < items.length - 1) {
      final nextOffset = nextCardOffsetAnim?.value ?? const Offset(0, 150);
      cards.add(
        Transform.translate(
          offset: nextOffset,
          child: _buildCardShell(
            width: screenWidth - 32,
            opacity: 0.8,
            child: _CardContent(
              item: items[topIndex],
              width: screenWidth - 32,
              isTop: false,
            ),
          ),
        ),
      );
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

  Widget _buildCardShell({
    required double width,
    required Widget child,
    required double opacity,
  }) {
    return _applyVisualDimmer(
        child: Container(
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
        opacity: opacity);
  }

  Widget _applyVisualDimmer({
    required Widget child,
    required double opacity,
  }) {
    if (opacity >= 0.99) return child;
    return IgnorePointer(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
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
  }) {
    return Transform.translate(
      offset: Offset(translateX, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.topRight,
          child: child,
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
