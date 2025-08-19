import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Route1(),
  ));
}

// 示例数据模型
class Item {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;

  Item(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.imageUrl});
}

// Route1：列表页面
class Route1 extends StatelessWidget {
  final List<Item> items = List.generate(
    10,
    (index) => Item(
      id: index,
      title: 'Card $index',
      subtitle: 'Subtitle $index',
      imageUrl: [
        "http://e.hiphotos.baidu.com/image/pic/item/a1ec08fa513d2697e542494057fbb2fb4316d81e.jpg",
        "http://c.hiphotos.baidu.com/image/pic/item/30adcbef76094b36de8a2fe5a1cc7cd98d109d99.jpg",
        "http://h.hiphotos.baidu.com/image/pic/item/7c1ed21b0ef41bd5f2c2a9e953da81cb39db3d1d.jpg",
        "http://g.hiphotos.baidu.com/image/pic/item/55e736d12f2eb938d5277fd5d0628535e5dd6f4a.jpg",
        "http://e.hiphotos.baidu.com/image/pic/item/4e4a20a4462309f7e41f5cfe760e0cf3d6cad6ee.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/9d82d158ccbf6c81b94575cfb93eb13533fa40a2.jpg",
        "http://e.hiphotos.baidu.com/image/pic/item/4bed2e738bd4b31c1badd5a685d6277f9e2ff81e.jpg",
        "http://g.hiphotos.baidu.com/image/pic/item/0d338744ebf81a4c87a3add4d52a6059252da61e.jpg",
        "http://a.hiphotos.baidu.com/image/pic/item/f2deb48f8c5494ee5080c8142ff5e0fe99257e19.jpg",
        "http://f.hiphotos.baidu.com/image/pic/item/4034970a304e251f503521f5a586c9177e3e53f9.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/279759ee3d6d55fbb3586c0168224f4a20a4dd7e.jpg",
        "http://a.hiphotos.baidu.com/image/pic/item/e824b899a9014c087eb617650e7b02087af4f464.jpg",
        "http://c.hiphotos.baidu.com/image/pic/item/9c16fdfaaf51f3de1e296fa390eef01f3b29795a.jpg",
        "http://d.hiphotos.baidu.com/image/pic/item/b58f8c5494eef01f119945cbe2fe9925bc317d2a.jpg",
        "http://h.hiphotos.baidu.com/image/pic/item/902397dda144ad340668b847d4a20cf430ad851e.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/359b033b5bb5c9ea5c0e3c23d139b6003bf3b374.jpg",
        "http://a.hiphotos.baidu.com/image/pic/item/8d5494eef01f3a292d2472199d25bc315d607c7c.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/e824b899a9014c08878b2c4c0e7b02087af4f4a3.jpg",
        "http://g.hiphotos.baidu.com/image/pic/item/6d81800a19d8bc3e770bd00d868ba61ea9d345f2.jpg",
      ][index],
    ),
  );

/*
  ListView 中的 Hero Widget：每个可见 item 对应 独立 Element + State。

      同类型、key null 的 Hero 不会在不同索引间复用。

      Hero tag 仅用于 跨路由动画匹配，不控制 Element 复用。

      ListView 滚动时，Flutter 可能复用滚出屏幕的 Element 给新 Item，但这属于 Sliver 缓存优化，而不是 Hero 自己的复用。
* */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route1 - ListView')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (index.isEven) {
            //Flutter 会为每个 Widget 创建一个 Element，因为 key 都是 null，
            //Flutter 会用 父 Widget 的子元素顺序（index）来匹配 Element。
            //当滚动列表，旧的元素可能被回收（ListView 的 SliverChildBuilderDelegate 会缓存一定数量的 Element，超过就销毁）
            //所以 每个可视的列表项对应一个 Hero Element，并不会因为 type 相同复用其他索引的 Hero。

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Route2(item: item),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Hero(
                      //同一个 ListView 下，index 不同的 Item（即使类型相同，key 为 null）：
                      //不会复用同一个 Element，每个可见 Item 都有自己的 Hero Element。
                      tag: 'card_${item.id}', //  每个卡片唯一 tag
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.imageUrl),
                  ),
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Route2(item: item),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Hero(
                      tag: 'card_${item.id}',
                      flightShuttleBuilder: (
                        flightContext,
                        animation,
                        flightDirection,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final t =
                                Curves.easeInOut.transform(animation.value);
                            final scale = 1.0 + 0.2 * t; // 飞行时轻微缩放

                            return Transform.scale(
                              scale: scale,
                              child: Material(
                                type: MaterialType.transparency,
                                child:
                                    flightDirection == HeroFlightDirection.push
                                        ? toHeroContext.widget
                                        : fromHeroContext.widget,
                              ),
                            );
                          },
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text("自定义Hero  ${item.title}"),
                    subtitle: Text(item.imageUrl),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// Route2：详情页面
class Route2 extends StatelessWidget {
  final Item item;

  Route2({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route2 - Detail')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'card_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: double.maxFinite,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(item.title, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(item.subtitle, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
