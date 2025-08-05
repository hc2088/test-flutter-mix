import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ListPage());
  }
}

class ListPage extends StatelessWidget {
  final List<bool> selectedList = List.generate(200, (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ListView Item Toggle")),
      body: ListView.builder(
        itemCount: selectedList.length,
        itemBuilder: (context, index) {
          return StatefulBuilder(
            builder: (context, setState) {
              return ListTile(
                title: Text(
                  'Item: $index',
                  style: TextStyle(
                    color: selectedList[index] ? Colors.blue : Colors.black,
                  ),
                ),
                trailing: Icon(
                  selectedList[index]
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                onTap: () {
                  setState(() {
                    selectedList[index] = !selectedList[index];
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
