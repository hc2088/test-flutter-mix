import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: DraggableListDemo(),
  ));
}

class DraggableListDemo extends StatefulWidget {
  @override
  _DraggableListDemoState createState() => _DraggableListDemoState();
}

class _DraggableListDemoState extends State<DraggableListDemo> {
  List<String> items = List.generate(10, (index) => 'Item $index');

  void _editItem(int index) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: items[index]);
        return AlertDialog(
          title: Text('编辑项目'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
    if (newText != null && newText != items[index]) {
      setState(() {
        items[index] = newText;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _addItem() {
    setState(() {
      items.add('Item ${items.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('可拖动列表'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            key: ValueKey(item), //必须要key
            title: Text(item),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editItem(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
                Icon(Icons.drag_handle), // 用于拖动提示
              ],
            ),
          );
        },
      ),
    );
  }
}
