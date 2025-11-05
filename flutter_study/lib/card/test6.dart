import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: CardStackLeakEffect()));

class CardStackLeakEffect extends StatefulWidget {
  const CardStackLeakEffect({super.key});

  @override
  State<CardStackLeakEffect> createState() => _CardStackLeakEffectState();
}

class _CardStackLeakEffectState extends State<CardStackLeakEffect> with TickerProviderStateMixin {
  final List<Color> colors = [Colors.pink, Colors.green, Colors.blue, Colors.orange, Colors.purple];
  int topIndex = 0;
  Offset dragOffset = Offset.zero;
  bool animating = false;
  bool showOK = false;

  late AnimationController animCtrl;
  Animation<Offset>? offsetAnim;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            dragOffset = Offset.zero;
            animating = false;
          });
        }
      });
  }

  void _animateTo(Offset end, {VoidCallback? onEnd}) {
    animating = true;
    offsetAnim = Tween(begin: dragOffset, end: end)
        .animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOut));
    animCtrl.forward(from: 0).then((_) {
      if (onEnd != null) onEnd();
    });
  }

  void _swipeUp() {
    if (topIndex >= colors.length - 1) return;
    _animateTo(const Offset(0, -600), onEnd: () {
      setState(() {
        topIndex++;
      });
    });
  }

  void _swipeDown() {
    if (topIndex == 0) return;
    _animateTo(const Offset(0, 600), onEnd: () {
      setState(() {
        topIndex--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final offset = animating && offsetAnim != null ? offsetAnim!.value : dragOffset;
    final stack = <Widget>[];

    const cardHeight = 520.0;
    const visibleLeak = 60.0; // 每层漏出高度

    for (int i = 2; i >= 0; i--) {
      int idx = topIndex + i;
      if (idx >= colors.length) continue;

      double translateY = -i * visibleLeak; // 向上偏移漏出
      double scale = 1 - i * 0.03;
      double opacity = 1 - i * 0.25;

      stack.add(
        _buildCard(
          color: colors[idx],
          index: i,
          translateY: translateY,
          scale: scale,
          opacity: opacity,
          isTop: i == 0,
          offset: offset,
          cardHeight: cardHeight,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: stack,
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color color,
    required int index,
    required double translateY,
    required double scale,
    required double opacity,
    required bool isTop,
    required Offset offset,
    required double cardHeight,
  }) {
    final transformOffset = isTop ? offset : Offset.zero;

    return Transform.translate(
      offset: Offset(transformOffset.dx, transformOffset.dy + translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Opacity(
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
              const threshold = 100;
              if (dragOffset.dy < -threshold || vy < -800) {
                _swipeUp();
              } else if (dragOffset.dy > threshold || vy > 800) {
                _swipeDown();
              } else {
                _animateTo(Offset.zero);
              }
            },
            onTap: () => debugPrint('Tap card'),
            onLongPress: () async {
              setState(() => showOK = true);
              await Future.delayed(const Duration(milliseconds: 600));
              setState(() => showOK = false);
            },
            child: Container(
              width: 330,
              height: cardHeight,
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 40,
                    right: 40,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (showOK && isTop)
                    const Positioned(
                      right: 24,
                      bottom: 24,
                      child: _OKAnimation(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OKAnimation extends StatefulWidget {
  const _OKAnimation();

  @override
  State<_OKAnimation> createState() => _OKAnimationState();
}

class _OKAnimationState extends State<_OKAnimation> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> scale;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    scale = CurvedAnimation(parent: ctrl, curve: Curves.elasticOut);
    fade = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);
    ctrl.forward();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
          alignment: Alignment.center,
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
      ),
    );
  }
}
