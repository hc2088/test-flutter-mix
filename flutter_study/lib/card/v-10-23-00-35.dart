import 'dart:math';
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

  late AnimationController exitCtrl;
  Animation<Offset>? exitAnim;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;

  late AnimationController nextCardCtrl;
  Animation<Offset>? nextCardOffsetAnim;

  late AnimationController prevStackCtrl;
  bool prevStackActive = false;

  @override
  void initState() {
    super.initState();

    animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            dragOffset = Offset.zero;
            animating = false;
          });
        }
      });

    exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250))
      ..addListener(() => setState(() {}));

    nextCardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380))
      ..addListener(() => setState(() {}));

    prevStackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    animCtrl.dispose();
    exitCtrl.dispose();
    nextCardCtrl.dispose();
    prevStackCtrl.dispose();
    super.dispose();
  }

  bool get canSwipeDown => topIndex > 0;

  bool get canSwipeUp => topIndex < items.length - 1;

  /// ✅ 打断所有动画并采样当前视觉偏移（包括上滑/下滑）
  void _abortAllAndCapture() {
    final current = (exitAnim != null)
        ? exitAnim!.value
        : (nextCardOffsetAnim != null && nextCardCtrl.isAnimating)
            ? nextCardOffsetAnim!.value
            : ((offsetAnim != null && animCtrl.isAnimating)
                ? offsetAnim!.value
                : dragOffset);

    animCtrl.stop();
    exitCtrl.stop();
    nextCardCtrl.stop();
    prevStackCtrl.stop();

    setState(() {
      exitAnim = null;
      nextCardOffsetAnim = null;
      prevStackActive = false;
      animating = false;
      dragOffset = current;
    });
  }

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

  /// ✅ 向上滑动
  void _swipeUpFast(bool fast) {
    if (animating) return;

    // ✅ 没有下一张卡片：直接回弹
    if (!canSwipeUp) {
      _reset();
      return;
    }

    animating = true;
    showNextCard = true;

    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, -800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    nextCardCtrl.reset();
    nextCardOffsetAnim = Tween(begin: const Offset(0, 150), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: nextCardCtrl, curve: Curves.easeOutCubic));

    exitCtrl.forward(from: 0).then((_) {
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

  /// ✅ 向下滑动
  void _swipeDownFast(bool fast) {
    if (animating) return;

    if (!canSwipeDown) {
      _reset();
      return;
    }

    animating = true;
    showNextCard = false;

    prevStackActive = true;
    prevStackCtrl.reset();
    exitCtrl.reset();

    exitAnim = Tween(begin: dragOffset, end: const Offset(0, 800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    final exitFut = exitCtrl.forward(from: 0);
    final stackFut = prevStackCtrl.forward(from: 0);

    Future.wait([exitFut, stackFut]).then((_) {
      if (!mounted) return;
      prevStackCtrl.animateTo(0.999, duration: Duration.zero);
      prevStackActive = false;

      setState(() {
        topIndex--;
        exitAnim = null;
        dragOffset = Offset.zero;
        animating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // ✅ 静态堆叠参数
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
    final visibleCount = (prevStackActive || prevStackCtrl.isAnimating) ? 3 : 2;

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

      final rawT = (prevStackActive || prevStackCtrl.isAnimating)
          ? prevStackCtrl.value
          : 0.0;
      final tDown = Curves.easeInOutCubic.transform(rawT.clamp(0.0, 1.0));

      double angle = baseAngle;
      double dy = baseDy;
      double scale = baseScale;
      double opacity = baseOpacity;

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
        } else if (i == 3) {
          angle = _lerp(baseAngle, angle3, tDown);
          dy = _lerp(baseDy, dy3, tDown);
          scale = _lerp(baseScale, scale3, tDown);
          opacity = _lerp(baseOpacity, opacity3, tDown);
        }
      }

      final isTop = (i == 0);
      Widget cardBody;

      if (idx < 0 || idx >= items.length) {
        final color = Colors.grey.shade700;
        cardBody = _buildCardShell(
          width: cardWidth,
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.45), color.withOpacity(0.20)],
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

      cards.add(_wrapTransforms(
        child: (idx >= 0)
            ? GestureDetector(
                onPanStart: (_) => _abortAllAndCapture(),
                onPanUpdate: (d) {
                  if (!isTop) return;
                  setState(() => dragOffset += d.delta / 1.1);
                },
                onPanEnd: (d) {
                  if (!isTop) return;
                  final vy = d.velocity.pixelsPerSecond.dy;
                  const threshold = 120;
                  if (dragOffset.dy < -threshold || vy < -800) {
                    _swipeUpFast(vy < -1500);
                  } else if (dragOffset.dy > threshold) {
                    _swipeDownFast(vy > 1500);
                  } else {
                    _reset();
                  }
                },
                child: cardBody,
              )
            : cardBody,
        translateX: leftInset + (isTop ? currentOffset.dx : 0),
        translateY: (isTop ? currentOffset.dy : 0) + dy,
        angle: angle,
        scale: scale,
        tDown: tDown,
      ));
    }

    // ✅ 修正版：仅在顶卡飞出动画结束后才显示下一张，防止重复底卡
    if (showNextCard && exitAnim == null && topIndex < items.length - 1) {
      final nextOffset = nextCardOffsetAnim?.value ?? const Offset(0, 150);
      cards.add(
        Transform.translate(
          offset: nextOffset,
          child: GestureDetector(
            onPanStart: (_) => _abortAllAndCapture(),
            onPanUpdate: (d) => setState(() => dragOffset += d.delta / 1.1),
            onPanEnd: (d) {
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
            child: _buildCardShell(
              width: w - 32,
              opacity: 0.85,
              child: _CardContent(
                  item: items[topIndex], width: w - 32, isTop: false),
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

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Widget _buildCardShell({
    required double width,
    required Widget child,
    required double opacity,
  }) {
    return Opacity(
      opacity: opacity,
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

  const _CardContent(
      {required this.item, required this.width, required this.isTop});

  @override
  State<_CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<_CardContent> {
  bool imageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.item.imageUrl,
          fit: BoxFit.fill,
          alignment: Alignment.bottomRight,
          imageBuilder: (context, imageProvider) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => imageLoaded = true);
            });
            return Image(image: imageProvider, fit: BoxFit.fill);
          },
          placeholder: (_, __) =>
              Container(color: Colors.grey.shade800.withOpacity(0.2)),
        ),
        // if (imageLoaded)
        // Positioned.fill(
        //   child: DecoratedBox(
        //     decoration: const BoxDecoration(
        //       gradient: LinearGradient(
        //         colors: [
        //           Color(0x66000000),
        //           Color(0x00000000),
        //           Color(0xAA000000)
        //         ],
        //         begin: Alignment.topCenter,
        //         end: Alignment.bottomCenter,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
