import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

///满意的版本
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

  late AnimationController nextStackCtrl;
  bool nextStackActive = false;

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
      vsync: this,
      duration: const Duration(milliseconds: 460),
      lowerBound: 0.0,
      upperBound: 1.1, // ✅ 允许略微超过 1，用于弹性效果
    )..addListener(() => setState(() {}));

    nextStackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() => setState(() {}));
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

  /// 上滑
  void _swipeUpFast(bool fast) {
    if (animating) return;
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

    nextStackActive = true;
    nextStackCtrl.reset();
    nextStackCtrl.forward(from: 0);

    exitCtrl.forward(from: 0).then((_) {
      setState(() {
        topIndex++;
        exitAnim = null;
        dragOffset = Offset.zero;
      });
      nextCardCtrl.forward(from: 0).then((_) {
        if (!mounted) return;

        nextStackCtrl.value = 0.0;
        nextStackActive = false;

        setState(() {
          animating = false;
          showNextCard = false;
          nextCardOffsetAnim = null;
        });
      });
    });
  }

  /// 下滑
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
    final stackFut = prevStackCtrl.animateTo(
      1.05, // ✅ 让它略微超过 1
      curve: Curves.easeOutBack, // ✅ 对应 overshoot 效果
    );

    Future.wait([exitFut, stackFut]).then((_) {
      if (!mounted) return;
      prevStackCtrl.value = 0.0;
      prevStackActive = false;

      setState(() {
        topIndex--;
        exitAnim = null;
        dragOffset = Offset.zero;
        animating = false;
      });
    });
  }

  // 🧩 抽取堆叠参数函数
  double _leftInsetFor(int i) => [0.0, 4.0, 14.0, 22.0][i.clamp(0, 3)];

  double _cardWidthFor(int i, double base) =>
      [base, base - 8, base - 28, base - 44][i.clamp(0, 3)];

  double _angleFor(int i) =>
      [0.0, 3.8 * pi / 180, 7.6 * pi / 180, 11 * pi / 180][i.clamp(0, 3)];

  double _dyFor(int i) => [0.0, -20.0, -40.0, -60.0][i.clamp(0, 3)];

  double _scaleFor(int i) => 1.0 - 0.05 * i.clamp(0, 3);

  double _opacityFor(int i) => [1.0, 0.6, 0.3, 0.15][i.clamp(0, 3)];

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final currentOffset = (() {
      if (exitAnim != null) return exitAnim!.value;
      if (offsetAnim != null && animCtrl.isAnimating) return offsetAnim!.value;
      return dragOffset;
    })();

    final cards = <Widget>[];
    final visibleCount = (prevStackActive || prevStackCtrl.isAnimating) ? 3 : 2;

    final upT = (nextStackActive || nextStackCtrl.isAnimating)
        ? Curves.easeOutCubic.transform(nextStackCtrl.value.clamp(0.0, 1.0))
        : 0.0;

    for (int i = visibleCount; i >= 0; i--) {
      if (showNextCard && exitAnim == null && i == 0) continue;
      final idx = topIndex - i;
      final baseWidth = w - 32;

      final baseLeft = _leftInsetFor(i);
      final baseAngle = _angleFor(i);
      final baseDy = _dyFor(i);
      final baseScale = _scaleFor(i);
      final baseOp = _opacityFor(i);
      final baseCardW = _cardWidthFor(i, baseWidth);

      final targetI = max(i - 1, 0);
      final targetLeft = _leftInsetFor(targetI);
      final targetAngle = _angleFor(targetI);
      final targetDy = _dyFor(targetI);
      final targetScale = _scaleFor(targetI);
      final targetOp = _opacityFor(targetI);
      final targetCardW = _cardWidthFor(targetI, baseWidth);

      final rawT = (prevStackActive || prevStackCtrl.isAnimating)
          ? prevStackCtrl.value
          : 0.0;

      final safeT = rawT.clamp(0.0, 1.0);
      final tDown = Curves.easeOutBack.transform(safeT); // 只用于几何变化
      final tOpacity = Curves.easeInOutCubic.transform(safeT); // 用于透明度插值

      final leftInset = _lerp(baseLeft, targetLeft, tDown);
      final angle = _lerp(baseAngle, targetAngle, tDown);
      final dy = _lerp(baseDy, targetDy, tDown);
      final scale = _lerp(baseScale, targetScale, tDown);

      // 如果上滑堆叠动画正在进行，让底卡略微往上推（视觉层次）
      final dyAdjusted = dy - 20 * upT; // 数值可调：推得更明显可设为 30
      final scaleAdjusted = scale + 0.02 * upT;

      final opacity = _lerp(baseOp, targetOp, tOpacity);

      final cardWidth = _lerp(baseCardW, targetCardW, tDown);

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

      // ✅ 是否启用旋转补偿：
      // 仅在下滑堆叠推进动画中（prevStackActive 或动画中），
      // 且当前卡片不是顶层（即 i > 0）时启用
      final enableCompensation =
          (i > 0) && (prevStackActive || prevStackCtrl.isAnimating);

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
        enableCompensation: enableCompensation, // ✅ 新增：仅对非顶层补偿
      ));
    }

    if (showNextCard && exitAnim == null && topIndex < items.length - 1) {
      final nextOffset = nextCardOffsetAnim?.value ?? const Offset(0, 150);
      cards.add(
        Transform.translate(
          offset: nextOffset,
          child: _buildCardShell(
            width: w - 32,
            opacity: 0.85,
            child: _CardContent(
                item: items[topIndex], width: w - 32, isTop: false),
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

  /// 对单张卡片应用平移、缩放、旋转及必要的旋转补偿。
  /// 补偿的作用：
  /// 当卡片有旋转角度（如第2、第3层），Flutter 默认以右上角为旋转中心，
  /// 旋转后会造成卡片右上掀开、左边略收紧，看起来像“变宽”。
  /// 补偿逻辑在动画过程中适度左移卡片，抵消这种视觉偏差。
  Widget _wrapTransforms({
    required Widget child,
    required double translateX,
    required double translateY,
    required double angle,
    required double scale,
    double tDown = 0.0,
    bool enableCompensation = false, // ✅ 是否启用旋转补偿
  }) {
    // ✅ 只有当当前层有角度（非顶层）且在堆叠推进动画中时才补偿
    final compFactor =
    (enableCompensation && angle.abs() > 0.001) ? (1 - tDown) : 0.0;

    return Transform.translate(
      offset: Offset(translateX, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.topRight,
          child: Transform.translate(
            // ✅ 补偿平移：抵消旋转导致的右上角漂移
            offset: Offset(-angle * 20 * compFactor, 0),
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
              Container(color: Colors.grey.shade800.withOpacity(1)),
        ),
      ],
    );
  }
}
