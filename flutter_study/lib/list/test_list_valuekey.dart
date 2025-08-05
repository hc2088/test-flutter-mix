import 'package:flutter/material.dart';

// | Key 类型         | 构造函数                      | 用途/适用场景                                                  |
// | -------------- | ------------------------- | -------------------------------------------------------- |
// | 1. `Key`（抽象基类） | `const Key(String key)`   | 所有 Key 的基类，通常不直接使用。
// |
// | 2. `ValueKey`  | `ValueKey<T>(T value)`    | 通过值判断是否为同一组件，适合列表中对某个值唯一标识。
//   @override
//   bool operator ==(Object other) {
//     if (other.runtimeType != runtimeType) {
//       return false;
//     }
//     return other is ValueKey<T>
//         && other.value == value;//用于根据某个具体值判断组件是否相同。
//   }
//
//   |

// | 3. `ObjectKey` | `ObjectKey(Object value)` | 通过对象引用标识组件，适合对象唯一但值可能相同的情况。                              |
// @override
// bool operator ==(Object other) {
// if (other.runtimeType != runtimeType) {
// return false;
// }
// return other is ObjectKey
// && identical(other.value, value); //比是不是同一个内存地址 ， 用对象本身作为 key，使用的是对象引用（地址）判断。
// }

// | 4. `UniqueKey` | `UniqueKey()`             | 每次都生成唯一 key，适合强制重建组件（如动态插入的动画项）。                         |

// | 5. `GlobalKey` | `GlobalKey<T>()`          | 跨 widget 层级访问其 `State`、`Context`，
// 通常用于表单、动画、导航等需要全局访问的场景。 局唯一，可用于跨 widget 访问 State。|

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
            key: ValueKey(index),
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
