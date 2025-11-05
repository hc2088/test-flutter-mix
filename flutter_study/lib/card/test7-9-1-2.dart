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

  /// 固定三层的索引（不 rebuild，只换数据）
  List<int> visibleIndices = [0, 1, 2];

  Offset dragOffset = Offset.zero;
  bool animating = false;
  bool showNextCard = false;

  late AnimationController exitCtrl; // 顶卡飞出
  Animation<Offset>? exitAnim;

  late AnimationController animCtrl; // 拖拽回弹
  Animation<Offset>? offsetAnim;

  late AnimationController nextCardCtrl; // 上滑：下一张推入
  Animation<Offset>? nextCardOffsetAnim;

  late AnimationController prevStackCtrl; // 下滑：堆叠整体前推
  bool prevStackActive = false;

  @override
  void initState() {
    super.initState();

    animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..addListener(() => setState(() {}));

    exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260))
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

  bool get canSwipeDown => visibleIndices.first > 0;
  bool get canSwipeUp => visibleIndices.last < items.length - 1;

  void _reset() {
    animCtrl.reset();
    setState(() => dragOffset = Offset.zero);
  }

  /// ✅ 向上滑动：查看下一张
  void _swipeUpFast() {
    if (!canSwipeUp || animating) return;
    animating = true;

    exitCtrl.reset();
    exitAnim = Tween(begin: dragOffset, end: const Offset(0, -800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    nextCardCtrl.reset();
    nextCardOffsetAnim =
        Tween(begin: const Offset(0, 150), end: Offset.zero).animate(
          CurvedAnimation(parent: nextCardCtrl, curve: Curves.easeOutCubic),
        );

    exitCtrl.forward(from: 0).then((_) {
      setState(() {
        exitAnim = null;
        dragOffset = Offset.zero;
      });

      nextCardCtrl.forward(from: 0).then((_) {
        _onSwipeUpComplete();
      });
    });
  }

  /// ✅ 向下滑动：查看上一张
  void _swipeDownFast() {
    if (!canSwipeDown || animating) return;
    animating = true;
    prevStackActive = true;

    prevStackCtrl.reset();
    exitCtrl.reset();

    exitAnim = Tween(begin: dragOffset, end: const Offset(0, 800))
        .animate(CurvedAnimation(parent: exitCtrl, curve: Curves.easeOutCubic));

    Future.wait([
      exitCtrl.forward(from: 0),
      prevStackCtrl.forward(from: 0),
    ]).then((_) {
      setState(() {
        prevStackCtrl.value = 1.0;
        prevStackActive = false;
        exitAnim = null;
        dragOffset = Offset.zero;
      });

      // 延迟一帧，确保动画终点帧绘制完成再切换索引
      Future.delayed(const Duration(milliseconds: 30), () {
        _onSwipeDownComplete();
      });
    });
  }

  void _onSwipeUpComplete() {
    if (!canSwipeUp) return;
    setState(() {
      for (int i = 0; i < visibleIndices.length; i++) {
        visibleIndices[i]++;
      }
      animating = false;
    });
  }

  void _onSwipeDownComplete() {
    if (!canSwipeDown) return;
    setState(() {
      for (int i = 0; i < visibleIndices.length; i++) {
        visibleIndices[i]--;
      }
      prevStackCtrl.value = 0.0;
      animating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final currentOffset = exitAnim?.value ?? dragOffset;

    final cards = <Widget>[];

    // 固定三层复用
    for (int i = 2; i >= 0; i--) {
      final idx = visibleIndices[i];
      if (idx < 0 || idx >= items.length) continue;
      final item = items[idx];

      double leftInset = 0;
      double baseAngle = 0;
      double baseDy = 0;
      double baseScale = 1.0 - i * 0.05;
      double baseOpacity = 1.0;
      double cardWidth = w - 32;

      if (i == 1) {
        leftInset = 4;
        cardWidth -= 8;
        baseAngle = 3.8 * pi / 180;
        baseDy = -20;
        baseOpacity = 0.6;
      } else if (i == 2) {
        leftInset = 14;
        cardWidth -= 28;
        baseAngle = 7.6 * pi / 180;
        baseDy = -40;
        baseOpacity = 0.3;
      }

      // ✅ 下滑时整体联动推进（像素级终点对齐）
      double t = (prevStackActive || prevStackCtrl.isAnimating)
          ? prevStackCtrl.value
          : 0.0;
      t = Curves.easeInOutCubic.transform(t);
      if (t > 0.995) t = 1.0; // 防止浮点偏差

      double angle = baseAngle;
      double dy = baseDy;
      double scale = baseScale;
      double opacity = baseOpacity;

      if (t > 0) {
        if (i == 1) {
          // 第二层 → 第一层
          angle = _lerp(baseAngle, 0.0, t);
          dy = _lerp(baseDy, 0.0, t);
          scale = _lerp(baseScale, 1.0, t);
          opacity = _lerp(baseOpacity, 1.0, t);
        } else if (i == 2) {
          // 第三层 → 第二层
          angle = _lerp(baseAngle, 3.8 * pi / 180, t);
          dy = _lerp(baseDy, -20, t);
          scale = _lerp(baseScale, 0.95, t);
          opacity = _lerp(baseOpacity, 0.6, t);
        }
      }

      // ✅ 末帧强制像素级对齐静态堆叠参数
      if (t >= 1.0 - 1e-4) {
        if (i == 1) {
          angle = 0.0;
          dy = 0.0;
          scale = 1.0;
          opacity = 1.0;
        } else if (i == 2) {
          angle = 3.8 * pi / 180;
          dy = -20;
          scale = 0.95;
          opacity = 0.6;
        }
      }

      final isTop = (i == 0);
      final offset = isTop ? currentOffset : Offset.zero;

      cards.add(_wrapTransforms(
        translateX: leftInset + offset.dx,
        translateY: offset.dy + dy,
        angle: angle,
        scale: scale,
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
              _swipeUpFast();
            } else if (dragOffset.dy > threshold || vy > 800) {
              _swipeDownFast();
            } else {
              _reset();
            }
          },
          child: _buildCardShell(
            width: cardWidth,
            opacity: opacity,
            child: _CardContent(item: item, width: cardWidth, isTop: isTop),
          ),
        ),
      ));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
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
              strokeAlign: BorderSide.strokeAlignOutside),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
      ),
    );
  }

  Widget _wrapTransforms({
    required double translateX,
    required double translateY,
    required double angle,
    required double scale,
    required Widget child,
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
            offset: Offset(-angle * 20, 0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final CardItem item;
  final double width;
  final bool isTop;

  const _CardContent({
    required this.item,
    required this.width,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Stack(
        children: [
          // CachedNetworkImage(
          //   imageUrl: item.imageUrl,
          //   fit: BoxFit.cover,
          //   width: width,
          //   height: 520,
          //   placeholder: (_, __) =>
          //       Container(color: Colors.grey.shade800.withOpacity(0.3)),
          // ),
          // Positioned.fill(
          //   child: DecoratedBox(
          //     decoration: const BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [Color(0x66000000), Color(0x00000000), Color(0xAA000000)],
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
