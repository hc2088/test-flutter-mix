import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '局部刷新 Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ListPage(),
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<String> items = List.generate(20, (index) => 'Item $index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('局部刷新 Demo')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListItemWidget(
            // 不要valuekey 依然能看起来正常更新
            key: ValueKey(index),
            // 保证唯一性，避免复用冲突

            //     没有指定 key 时，Flutter 会**根据 widget 的类型和位置（slot）**来匹配旧 widget 和新 widget。
            //
            // 在 ListView.builder 中，若你修改了某个列表项的内容并 setState，位置不变时大概率会复用成功，所以看起来没问题。
            //
            // 但当列表项的顺序变动、插入、删除时，没有 Key 的复用机制就会发生错位更新、错乱 UI、状态泄露等问题。
            text: items[index],
            onTextChanged: (newText) {
              setState(() {
                items[index] = newText;
              });
            },
          );
        },
      ),
    );
  }
}

/// 每个列表项
class ListItemWidget extends StatefulWidget {
  final String text;
  final ValueChanged<String> onTextChanged;

  const ListItemWidget({
    super.key,
    required this.text,
    required this.onTextChanged,
  });

  @override
  State<ListItemWidget> createState() => _ListItemWidgetState();
}

class _ListItemWidgetState extends State<ListItemWidget> {
  late String text;

  @override
  void initState() {
    super.initState();
    text = widget.text;
  }

  void _editText() async {
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => _EditDialog(initialText: text),
    );

    if (newText != null && newText != text) {
      // setState(() {
      //   text = newText;
      // });
      widget.onTextChanged(newText); // 通知父 widget 更新原始列表
    }
  }

  @override
  void didUpdateWidget(covariant ListItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      text = widget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text),
      trailing: TextButton(
        onPressed: _editText,
        child: const Text('编辑'),
      ),
    );
  }
}

/// 编辑弹窗
class _EditDialog extends StatefulWidget {
  final String initialText;

  const _EditDialog({required this.initialText});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑文本'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: '内容'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
