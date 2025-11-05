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
  late AnimationController exitCtrl;
  Animation<Offset>? exitAnim;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;
  Animation<Offset>? nextCardOffsetAnim;
  late AnimationController nextCardCtrl;

  /// =============================
  /// 下滑查看上一张动画
  /// =============================
  late AnimationController prevStackCtrl;
  bool prevStackActive = false;

  /// =============================
  /// 新增：上滑堆叠联动（旧卡片被顶下去）
  /// =============================
  late AnimationController nextStackCtrl;
  bool nextStackActive = false;

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

    exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
      ..addListener(() => setState(() {}));

    prevStackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() => setState(() {}));

    nextStackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() => setState(() {}));

    nextCardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    animCtrl.dispose();
    exitCtrl.dispose();
    prevStackCtrl.dispose();
    nextStackCtrl.dispose();
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

  /// ✅ 向上滑动：查看下一张 + 旧卡片联动往后退
  void _swipeUpFast(bool fast) {
    if (!canSwipeUp || animating) return;
    animating = true;
    showNextCard = true;

    nextStackActive = true;
    nextStackCtrl.forward(from: 0);

    // 顶卡飞出
    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, -800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    // 下一张推入
    nextCardCtrl.reset();
    nextCardOffsetAnim = Tween(begin: const Offset(0, 150), end: Offset.zero)
        .animate(CurvedAnimation(parent: nextCardCtrl, curve: Curves.easeOutCubic));

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
          nextStackActive = false;
          nextCardOffsetAnim = null;
        });
      });
    });
  }

  /// ✅ 向下滑动：查看上一张（堆叠前挪）
  void _swipeDownFast(bool fast) {
    if (!canSwipeDown || animating) return;
    animating = true;
    showNextCard = false;
    prevStackActive = true;
    prevStackCtrl.forward(from: 0);

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

      prevStackCtrl.animateTo(1.0, curve: Curves.easeOut).then((_) {
        if (!mounted) return;
        setState(() {
          prevStackActive = false;
          animating = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final currentOffset = (() {
      if (exitAnim != null) return exitAnim!.value;
      if (offsetAnim != null && animCtrl.isAnimating) return offsetAnim!.value;
      return dragOffset;
    })();

    final cards = <Widget>[];
    for (int i = 2; i >= 0; i--) {
      if (showNextCard && exitAnim == null && i == 0) continue;

      final idx = topIndex - i;
      final baseW = w - 32;
      double leftInset = 0;
      double baseAngle = 0;
      double baseDy = 0;
      double baseScale = 1.0 - i * 0.05;
      double baseOpacity = 1.0;
      if (i == 1) {
        leftInset = 4;
        baseAngle = 3.8 * pi / 180;
        baseDy = -20;
        baseOpacity = 0.6;
      } else if (i == 2) {
        leftInset = 14;
        baseAngle = 7.6 * pi / 180;
        baseDy = -40;
        baseOpacity = 0.3;
      }

      double tDown = prevStackActive ? prevStackCtrl.value : 0;
      double tUp = nextStackActive ? nextStackCtrl.value : 0;

      // 基础几何
      double angle = baseAngle;
      double dy = baseDy;
      double scale = baseScale;
      double opacity = baseOpacity;

      // 下滑联动（底卡顶上来）
      if (tDown > 0) {
        if (i == 1) {
          angle = _lerp(baseAngle, 0, tDown);
          dy = _lerp(baseDy, 0, tDown);
          scale = _lerp(baseScale, 1.0, tDown);
          opacity = _lerp(baseOpacity, 1.0, tDown);
        } else if (i == 2) {
          angle = _lerp(baseAngle, 3.8 * pi / 180, tDown);
          dy = _lerp(baseDy, -20, tDown);
          scale = _lerp(baseScale, 0.95, tDown);
          opacity = _lerp(baseOpacity, 0.6, tDown);
        }
      }

      // 上滑联动（顶卡被推走）
      if (tUp > 0) {
        if (i == 0) {
          angle = _lerp(baseAngle, -5 * pi / 180, tUp);
          dy = _lerp(baseDy, -60, tUp);
          scale = _lerp(baseScale, 0.95, tUp);
          opacity = _lerp(baseOpacity, 0.7, tUp);
        } else if (i == 1) {
          angle = _lerp(baseAngle, -8 * pi / 180, tUp);
          dy = _lerp(baseDy, -40, tUp);
          scale = _lerp(baseScale, 0.9, tUp);
          opacity = _lerp(baseOpacity, 0.5, tUp);
        }
      }

      final isTop = i == 0;
      Widget card = _buildCardShell(
        width: baseW - 2 * leftInset,
        opacity: opacity,
        child: (idx >= 0)
            ? _CardContent(item: items[idx], width: baseW, isTop: isTop)
            : Container(color: Colors.grey.shade800),
      );

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
              _swipeUpFast(vy < -1500);
            } else if (dragOffset.dy > threshold && canSwipeDown) {
              _swipeDownFast(vy > 1500);
            } else {
              _reset();
            }
          },
          child: card,
        ),
        translateX: leftInset + (isTop ? currentOffset.dx : 0),
        translateY: (isTop ? currentOffset.dy : 0) + dy,
        angle: angle,
        scale: scale,
      ));
    }

    // 下一张推入
    if (showNextCard && exitAnim == null && topIndex < items.length - 1) {
      final nextOffset = nextCardOffsetAnim?.value ?? const Offset(0, 150);
      cards.add(
        Transform.translate(
          offset: nextOffset,
          child: _buildCardShell(
            width: w - 32,
            opacity: 0.85,
            child: _CardContent(item: items[topIndex], width: w - 32, isTop: false),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: cards),
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
          border: Border.all(color: const Color(0xFF4A4A4A), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
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
        child: Transform.rotate(angle: angle, alignment: Alignment.topRight, child: child),
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

class _CardContentState extends State<_CardContent> {
  bool imageLoaded = false;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: widget.item.imageUrl,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => imageLoaded = true);
          });
          return Image(image: imageProvider, fit: BoxFit.cover);
        },
      ),
    );
  }
}
