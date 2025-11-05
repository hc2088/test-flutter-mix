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
  bool showNextCard = false;
  int topIndex = 0;
  Offset dragOffset = Offset.zero;
  late AnimationController exitCtrl;
  Animation<Offset>? exitAnim;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim; // 当前卡片动画
  Animation<Offset>? nextCardOffsetAnim; // 下一张卡片动画

  Animation<Offset>? prevCardOffsetAnim;
  Animation<double>? prevCardAngleAnim;

  late AnimationController prevStackCtrl;
  Animation<double>? prevUpperCardAnim; // 上一张主卡片上移动画
  Animation<double>? prevLowerCardAnim; // 上上一张轻微弹起动画


  Animation<double>? nextCardAngleAnim;
  late AnimationController nextCardCtrl;

  late AnimationController nextStackCtrl;
  Animation<double>? nextUpperCardAnim; // 下一张主卡片旋转动画
  Animation<double>? nextLowerCardAnim; // 下下一张轻微旋转动画


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

    nextStackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));

  }

  @override
  void dispose() {
    animCtrl.dispose();
    exitCtrl.dispose();
    prevStackCtrl.dispose();
    nextCardCtrl.dispose();
    nextStackCtrl.dispose();

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

    animating = true;
    showNextCard = false;

    // 当前卡片向下飞出
    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, 800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    // 播放飞出动画
    exitCtrl.forward().then((_) async {
      if (!mounted) return;

      // 飞出后切换 index
      setState(() {
        topIndex--;
        exitAnim = null;
        dragOffset = Offset.zero;
      });

      // 上一张卡片弹起动画（双层）
      prevStackCtrl.reset();

      prevUpperCardAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: prevStackCtrl,
          curve: Curves.easeOutBack,
        ),
      );

      prevLowerCardAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: prevStackCtrl,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
        ),
      );

      prevCardOffsetAnim = Tween<Offset>(
        begin: const Offset(0, 100),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: prevStackCtrl,
        curve: Curves.easeOutCubic,
      ));

      prevCardAngleAnim = Tween<double>(
        begin: -5 * pi / 180,
        end: 0,
      ).animate(CurvedAnimation(
        parent: prevStackCtrl,
        curve: Curves.easeOutBack,
      ));

      await Future.delayed(const Duration(milliseconds: 80));

      prevStackCtrl.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          animating = false;

          // 清理动画状态
          prevCardOffsetAnim = null;
          prevCardAngleAnim = null;
          prevUpperCardAnim = null;
          prevLowerCardAnim = null;
        });
      });
    });
  }

  void _reset() => _animateTo(Offset.zero);

  // ✅ 改进后的上滑动画
  void _swipeUpFast(bool fast) {
    if (!canSwipeUp || animating) return;

    animating = true;
    showNextCard = true;

    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, -800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    // ✅ 启动“底部卡旋转”动画
    nextStackCtrl.reset();

    nextUpperCardAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: nextStackCtrl,
        curve: Curves.easeOutBack,
      ),
    );

    nextLowerCardAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: nextStackCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // ✅ 当前卡片上飞
    exitCtrl.forward().then((_) async {
      if (!mounted) return;

      setState(() {
        topIndex++;
        exitAnim = null;
        dragOffset = Offset.zero;
      });

      // ✅ 让底部的上一张卡片旋转动效触发
      nextStackCtrl.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 90));

      animCtrl.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          animating = false;
          showNextCard = false;

          // 清理动画状态
          nextUpperCardAnim = null;
          nextLowerCardAnim = null;
        });
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final currentOffset = exitAnim?.value ??
        (animating && offsetAnim != null ? offsetAnim!.value : dragOffset);

    final cards = <Widget>[];

// 最多显示三层：当前、上一张、上上一张
    for (int i = 2; i >= 0; i--) {
      if (showNextCard && exitAnim == null && i == 0) continue;
      if (prevCardOffsetAnim != null && i == 1) continue;

      final idx = topIndex - i;
      final baseWidth = screenWidth - 32;

      // ✅ 统一的几何：和你原来一致（保持视觉）
      double leftInset = 0;
      double angle = 0;
      double dy = 0;
      double scale = 1.0 - i * 0.05;
      double opacity = 1.0;
      double cardWidth = baseWidth;

      if (i == 1) {
        leftInset = 4;
        cardWidth = baseWidth - 2 * leftInset;
        angle = 3.8 * pi / 180;
        dy = -20;

        if (prevUpperCardAnim != null) {
          // 下滑动画：逆时针回正
          dy += 30 * (1 - prevUpperCardAnim!.value);
          angle = angle * (1 - prevUpperCardAnim!.value);
        }

        if (nextUpperCardAnim != null) {
          // 上滑动画：顺时针旋转再回正
          angle = 5 * pi / 180 * (1 - nextUpperCardAnim!.value);
        }

        opacity = 0.6;
      } else if (i == 2) {
        leftInset = 14;
        cardWidth = baseWidth - 2 * leftInset;
        angle = 7.6 * pi / 180;
        dy = -40;

        if (prevLowerCardAnim != null) {
          // 下滑动画
          dy += 20 * (1 - prevLowerCardAnim!.value);
          angle = angle * (1 - prevLowerCardAnim!.value);
        }

        if (nextLowerCardAnim != null) {
          // 上滑动画：轻微顺时针旋转
          angle = 2.5 * pi / 180 * (1 - nextLowerCardAnim!.value);
        }

        opacity = 0.3;
      }


      // ✅ 统一“壳”与“几何变换”
      Widget cardBody;
      bool isTop = (i == 0);

      if (idx < 0) {
        final color =
        (i == 1) ? const Color(0xFF6B8E68) : const Color(0xFF4F6A4D);
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: _buildPlaceholderBody(color),
        );
      } else {
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: _buildRealBody(items[idx], cardWidth, isTop),
        );
      }

      // ✅ 所有卡（空/真）同一套几何包装
      final wrapped = _wrapTransforms(
        child: (idx >= 0)
            ? GestureDetector(
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
              final fast = vy < -1500;
              _swipeUpFast(fast);
            } else if (dragOffset.dy > threshold && canSwipeDown) {
              final fast = vy > 1500;
              _swipeDownFast(fast);
            } else {
              _reset();
            }
          },
          child: cardBody,
        )
            : cardBody,
        // 空卡不需要手势
        translateX: leftInset +
            (isTop
                ? (exitAnim?.value.dx ?? offsetAnim?.value.dx ?? dragOffset.dx)
                : 0),
        translateY: (isTop
            ? (exitAnim?.value.dy ?? offsetAnim?.value.dy ?? dragOffset.dy)
            : 0) +
            dy,
        angle: angle,
        scale: scale,
      );

      cards.add(wrapped);
    }

    // ✅ 如果正在执行下滑动画，则渲染上一张卡片动画
    if (prevCardOffsetAnim != null && topIndex > 0) {
      final prevOffset = prevCardOffsetAnim!.value;
      final prevAngle = prevCardAngleAnim?.value ?? 0.0;

      cards.add(
        Transform.translate(
          offset: prevOffset,
          child: Transform.rotate(
            angle: prevAngle,
            alignment: Alignment.topRight,
            child: _buildCard(
              items[topIndex - 1],
              false,
              1.0,
              // 返回后成为新顶层
              0,
              0,
              1.0,
              Offset.zero,
              0,
              width: screenWidth - 32,
            ),
          ),
        ),
      );
    }

// ✅ 仅当飞出动画结束后，才渲染下一张卡片
    if (showNextCard && exitAnim == null && topIndex < items.length - 1) {
      final nextOffset = nextCardOffsetAnim?.value ?? const Offset(0, 150);
      final nextAngle = nextCardAngleAnim?.value ?? 0.0; // ✅ 新增角度动画
      cards.add(
        Transform.translate(
          offset: nextOffset,
          child: Transform.rotate(
            angle: nextAngle, // ✅ 顺时针旋转
            alignment: Alignment.topRight,
            child: _buildCard(
              items[topIndex],
              false,
              0.98,
              40,
              0,
              0.8,
              Offset.zero,
              0,
              width: screenWidth - 32,
            ),
          ),
        ),
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

  // 空卡的“内容区”（仅渐变/柔光）
  Widget _buildPlaceholderBody(Color color) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0.0, -0.15),
                radius: 1.4,
                colors: [Color(0x33000000), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 真卡的“内容区”（你原来的 _CardContent ）
  Widget _buildRealBody(CardItem item, double width, bool isTop) {
    return _CardContent(item: item, width: width, isTop: isTop);
  }

  Widget _buildCardShell({
    required double width,
    required Widget child,
    required double opacity,
  }) {
    // 与 _CardContent 外层容器完全一致（边框/圆角/阴影/裁剪一模一样）
    final shell = Container(
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
        child: child, // 这里塞“真实内容”或“空卡渐变”
      ),
    );

    return _applyVisualDimmer(opacity: opacity, child: shell);
  }

  // 把几何变换统一封装（顺序固定，所有卡片都走同一套）
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
        child: Transform.translate(
          offset: Offset(-angle * 80, 0), // 你原本的“补位移”也统一加在这里
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.topRight,
            child: child,
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
          offset: Offset(
              transformOffset.dx + translateX, transformOffset.dy + translateY),
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
                        final fast = vy < -1500;
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
