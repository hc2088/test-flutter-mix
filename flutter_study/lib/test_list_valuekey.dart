import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: EditableListViewDemo()));
}

class EditableListViewDemo extends StatefulWidget {
  const EditableListViewDemo({Key? key}) : super(key: key);

  @override
  State<EditableListViewDemo> createState() => _EditableListViewDemoState();
}

class _EditableListViewDemoState extends State<EditableListViewDemo> {
  final List<String> _items = ['Item 1', 'Item 2', 'Item 3'];

  void _addItem() {
    setState(() {
      _items.add('New Item');
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, String newText) {
    setState(() {
      _items[index] = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editable ListView'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, index) {
          return EditableItemWidget(
            // key: ValueKey(index),
            title: _items[index],
            onChanged: (value) => _updateItem(index, value),
            onDelete: () => _removeItem(index),
          );
        },
      ),
    );
  }
}

class EditableItemWidget extends StatefulWidget {
  final String title;
  final void Function(String) onChanged;
  final VoidCallback onDelete;

  const EditableItemWidget({
    Key? key,
    required this.title,
    required this.onChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<EditableItemWidget> createState() => _EditableItemWidgetState();
}

class _EditableItemWidgetState extends State<EditableItemWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 初始化编辑器，初始值从 props 中来
    _controller = TextEditingController(text: widget.title);

    // 实时同步到外部数据源
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void didUpdateWidget(covariant EditableItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果父级更新 title，我们也要更新 controller
    if (oldWidget.title != widget.title) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextField(
        controller: _controller,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: widget.onDelete,
      ),
    );
  }
}
