import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: VisibilityAnimationDemo()));
}

class VisibilityAnimationDemo extends StatefulWidget {
  @override
  _VisibilityAnimationDemoState createState() =>
      _VisibilityAnimationDemoState();
}

class _VisibilityAnimationDemoState extends State<VisibilityAnimationDemo> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visibility 动画示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AnimatedOpacity 包裹 Visibility
            AnimatedOpacity(
              duration: Duration(milliseconds: 1500),
              opacity: _isVisible ? 1 : 0,
              child: Visibility(
                visible: _isVisible,
                maintainState: true,
                // 隐藏时保持状态
                maintainAnimation: true,
                maintainSize: true,
                // 隐藏时占位
                child: Container(
                  width: 200,
                  height: 100,
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Text('Animated Visibility',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isVisible = !_isVisible; // 切换显示/隐藏
                });
              },
              child: Text(_isVisible ? '隐藏' : '显示'),
            ),
          ],
        ),
      ),
    );
  }
}
