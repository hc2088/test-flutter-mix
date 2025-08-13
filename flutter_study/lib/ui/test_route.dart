import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FirstPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 首页页面
class FirstPage extends StatefulWidget {
  const FirstPage({super.key});
  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final GlobalKey _cardKey = GlobalKey();
  static const String heroTag = "present_card_1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero + 手势关闭 完整版 Demo")),
      body: Center(
        child: GestureDetector(
          onTap: () {
            PresentCard.show(
              context,
              cardKey: _cardKey,
              tag: heroTag,
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    "新页面内容",
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
            );
          },
          child: PresentCardAnchor(
            key: _cardKey,
            tag: heroTag,
            child: RepaintBoundary(
              child: Container(
                width: 150,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    "点我打开",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Hero包裹的卡片
class PresentCardAnchor extends StatelessWidget {
  final Widget child;
  final String tag;
  const PresentCardAnchor({super.key, required this.child, required this.tag});
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      placeholderBuilder: (context, size, widget) {
        // 防止返回时跳动，给个固定大小的占位
        return Material(
          color: Colors.transparent,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        );
      },
      flightShuttleBuilder: (ctx, anim, dir, fromCtx, toCtx) {
        return Material(
          color: Colors.transparent,
          child: toCtx.widget,
        );
      },
      child: child,
    );
  }
}

// 负责显示新页面的组件
class PresentCard extends StatefulWidget {
  final Widget child;
  final GlobalKey cardKey;
  final String tag;
  final double closeThreshold;
  final double velocityThreshold;
  final double maxScaleReduction;
  final double maxBlur;

  const PresentCard({
    super.key,
    required this.child,
    required this.cardKey,
    required this.tag,
    this.closeThreshold = 0.25,
    this.velocityThreshold = 800.0,
    this.maxScaleReduction = 0.4,
    this.maxBlur = 10.0,
  });

  static Future<void> show(
      BuildContext context, {
        required Widget child,
        required GlobalKey cardKey,
        required String tag,
        double closeThreshold = 0.25,
        double velocityThreshold = 800.0,
        double maxScaleReduction = 0.4,
        double maxBlur = 10.0,
      }) {
    return Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return PresentCard(
          child: child,
          cardKey: cardKey,
          tag: tag,
          closeThreshold: closeThreshold,
          velocityThreshold: velocityThreshold,
          maxScaleReduction: maxScaleReduction,
          maxBlur: maxBlur,
        );
      },
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: child,
        );
      },
    ));
  }

  @override
  State<PresentCard> createState() => _PresentCardState();
}

class _PresentCardState extends State<PresentCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  late AnimationController _controller;

  Offset? _cardPosition;
  Size? _cardSize;

  bool _closing = false;
  bool _opening = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCardRect();
      _startOpenAnimation();
    });
  }

  void _getCardRect() {
    final renderBox =
    widget.cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _cardPosition = renderBox.localToGlobal(Offset.zero);
        _cardSize = renderBox.size;
      });
    }
  }

  void _startOpenAnimation() {
    _controller.duration = const Duration(milliseconds: 300);
    _controller.value = 0;
    _opening = true;
    _controller.addListener(() {
      setState(() {});
    });
    _controller.forward().whenComplete(() {
      _opening = false;
    });
  }

  void _startCloseAnimation() {
    _closing = true;
    _controller.duration = const Duration(milliseconds: 200);
    _controller.reverse().whenComplete(() {
      Navigator.pop(context);
    });
  }

  double _getOpenCloseValue() {
    return _controller.value;
  }

  double _getDragScale() {
    final size = MediaQuery.of(context).size;
    final dragDistance = math.sqrt(_dragX * _dragX + _dragY * _dragY);
    final maxDistance =
    math.sqrt(size.width * size.width + size.height * size.height);
    return 1 - (dragDistance / maxDistance) * widget.maxScaleReduction;
  }

  double _getBlur() {
    final size = MediaQuery.of(context).size;
    final dragDistance = math.sqrt(_dragX * _dragX + _dragY * _dragY);
    final maxDistance =
    math.sqrt(size.width * size.width + size.height * size.height);
    final baseBlur = widget.maxBlur * _getOpenCloseValue();
    final dragBlur = widget.maxBlur * (1 - dragDistance / maxDistance);
    return _closing
        ? baseBlur * (1 - _controller.value)
        : _opening
        ? baseBlur
        : dragBlur.clamp(0.0, widget.maxBlur);
  }

  double _getOpacity() {
    final size = MediaQuery.of(context).size;
    final dragDistance = math.sqrt(_dragX * _dragX + _dragY * _dragY);
    final maxDistance =
    math.sqrt(size.width * size.width + size.height * size.height);
    if (_opening) {
      return Curves.easeOutCubic.transform(_controller.value) * 0.5;
    } else if (_closing) {
      return Curves.easeInCubic.transform(_controller.value) * 0.5;
    } else {
      return (1 - (dragDistance / maxDistance) * 1.2).clamp(0.0, 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cardPosition == null || _cardSize == null) {
      // 还没拿到卡片位置，先显示空白避免报错
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;

    final dxTarget =
        _cardPosition!.dx + _cardSize!.width / 2 - size.width / 2;
    final dyTarget =
        _cardPosition!.dy + _cardSize!.height / 2 - size.height / 2;

    final scaleTarget = _cardSize!.width / size.width;

    final openCloseValue = _getOpenCloseValue();

    final blur = _getBlur().clamp(0.0, widget.maxBlur);
    final opacity = _getOpacity().clamp(0.0, 0.5);

    Offset offset;
    double scale;

    if (_opening) {
      final animT = Curves.easeOutCubic.transform(openCloseValue);
      offset = Offset(dxTarget * (1 - animT), dyTarget * (1 - animT));
      scale = scaleTarget + (1 - scaleTarget) * animT;
    } else if (_closing) {
      final animT = Curves.easeInCubic.transform(openCloseValue);
      offset = Offset(dxTarget * animT, dyTarget * animT);
      scale = 1 - (1 - scaleTarget) * animT;
    } else {
      offset = Offset(_dragX, _dragY);
      scale = _getDragScale();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onPanUpdate: (details) {
          if (_closing || _opening) return;
          setState(() {
            _dragX += details.delta.dx;
            _dragY += details.delta.dy;
          });
        },
        onPanEnd: (details) {
          if (_closing || _opening) return;
          final velocity = details.velocity.pixelsPerSecond;
          final speed = velocity.distance;

          final shouldCloseByVelocity = speed > widget.velocityThreshold;
          final shouldCloseByDistance = _dragX.abs() >
              size.width * widget.closeThreshold ||
              _dragY.abs() > size.height * widget.closeThreshold;

          if (shouldCloseByVelocity || shouldCloseByDistance) {
            _startCloseAnimation();
          } else {
            setState(() {
              _dragX = 0;
              _dragY = 0;
            });
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(color: Colors.black.withOpacity(opacity)),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scale: scale,
                  child: Hero(
                    tag: widget.tag,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
