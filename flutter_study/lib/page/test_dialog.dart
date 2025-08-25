import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: DialogExamplePage(),
  ));
}
// Dialog 是 Material 风格弹窗的基础容器，提供样式和布局支持。
//
// AlertDialog / SimpleDialog 是 Dialog 的特化，封装了常用布局和交互逻辑，方便快速使用。
//
// 普通 Widget 弹窗 更灵活，但需要自己处理样式和交互。
class DialogExamplePage extends StatefulWidget {
  @override
  _DialogExamplePageState createState() => _DialogExamplePageState();
}

class _DialogExamplePageState extends State<DialogExamplePage> {
  String _inputText = '';
  String _simpleDialogChoice = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog 综合示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SimpleDialog 选择: $_simpleDialogChoice'),
            const SizedBox(height: 10),
            Text('输入弹窗内容: $_inputText'),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    /*
          * 作用和优势

                1、遵循 Material 规范

                    Dialog 自带 圆角、阴影、背景色、边距
                    在不同平台上外观一致（Android/iOS）

                2、自动管理布局

                    居中显示，默认在屏幕中间
                    自动处理弹窗大小和屏幕边距

                3、自动处理返回键 / 点击外部关闭

                    和 showDialog 配合，可以直接设置 barrierDismissible

                4、方便扩展

                    可以在 Dialog 内部放任何 Widget，自定义内容，但仍保持 Dialog 样式
          *
          *
          * */
                    return Dialog(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: const Text('这是一个 Dialog 弹窗'),
                      ),
                    );
                  },
                );
              },
              child: const Text('  使用 Dialog 作为包裹'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        color: Colors.white,
                        child: Text('普通 Widget 弹窗'),
                      );
                    },
                  );
                },
                child: const Text('直接用普通 Widget')),
            const SizedBox(height: 20),

            // 按钮 1：普通 AlertDialog
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('普通 AlertDialog'),
                      content: const Text('这是一个 AlertDialog，适合显示标题、内容和操作按钮。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('确定'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('显示 AlertDialog'),
            ),
            const SizedBox(height: 20),

            // 按钮 2：SimpleDialog
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: const Text('SimpleDialog'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, '选项一');
                          },
                          child: const Text('选项一'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, '选项二');
                          },
                          child: const Text('选项二'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, '选项三');
                          },
                          child: const Text('选项三'),
                        ),
                      ],
                    );
                  },
                ).then((value) {
                  if (value != null) {
                    setState(() {
                      _simpleDialogChoice = value;
                    });
                  }
                });
              },
              child: const Text('显示 SimpleDialog'),
            ),
            const SizedBox(height: 20),

            // 按钮 3：带输入框的 AlertDialog
            ElevatedButton(
              onPressed: () {
                TextEditingController textController = TextEditingController();

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('请输入内容'),
                      content: TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          hintText: '在这里输入...',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _inputText = textController.text;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('确认'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('显示带输入框的 AlertDialog'),
            ),
          ],
        ),
      ),
    );
  }
}
