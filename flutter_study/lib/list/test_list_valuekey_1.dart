import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ListPage());
  }
}

class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<bool> selectedList = List.generate(200, (_) => false);

  void toggleItem(int index) {
    setState(() {
      selectedList[index] = !selectedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ListView Item Toggle")),
      body: ListView.builder(
        itemCount: selectedList.length,
        itemBuilder: (context, index) {
          return ItemWidget(
            key: ValueKey(index),
            selected: selectedList[index],
            index: index,
            onTap: () => toggleItem(index),
          );
        },
      ),
    );
  }
}

class ItemWidget extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final int index;

  const ItemWidget({
    Key? key,
    required this.selected,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  @override
  void didUpdateWidget(covariant ItemWidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget Item:${widget.index}");
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Item:${widget.index}',
          style:
              TextStyle(color: widget.selected ? Colors.blue : Colors.black)),
      trailing: Icon(
          widget.selected ? Icons.check_box : Icons.check_box_outline_blank),
      onTap: widget.onTap,
    );
  }
}
