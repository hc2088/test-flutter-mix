import 'package:flutter/material.dart';

void main() => runApp(const MemoryOptimizationDemoApp());

class MemoryOptimizationDemoApp extends StatelessWidget {
  const MemoryOptimizationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Optimization Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MemoryOptimizationDemoPage(),
    );
  }
}

class MemoryOptimizationDemoPage extends StatefulWidget {
  const MemoryOptimizationDemoPage({super.key});

  @override
  State<MemoryOptimizationDemoPage> createState() =>
      _MemoryOptimizationDemoPageState();
}

class _MemoryOptimizationDemoPageState extends State<MemoryOptimizationDemoPage>
    with TickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Memory Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bad Case'),
            Tab(text: 'Optimized'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MemoryListCase(mode: DemoMode.bad),
          _MemoryListCase(mode: DemoMode.optimized),
        ],
      ),
    );
  }
}

enum DemoMode { bad, optimized }

class _MemoryListCase extends StatefulWidget {
  const _MemoryListCase({required this.mode});

  final DemoMode mode;

  @override
  State<_MemoryListCase> createState() => _MemoryListCaseState();
}

class _MemoryListCaseState extends State<_MemoryListCase> {
  static const double _itemHeight = 168;

  final ScrollController _scrollController = ScrollController();

  // 用一组重复图片模拟“很多列表卡片都带图”的真实业务场景。
  // 这样更容易在 DevTools 里观察图片缓存和列表预构建对内存的影响。
  late final List<_DemoItem> _items = List.generate(
    90,
    (index) => _DemoItem(
      id: index,
      title: 'Image card #$index',
      subtitle: 'Observe DevTools memory while scrolling this list.',
      assetPath: _assetPool[index % _assetPool.length],
    ),
  );

  late final int _oldMaximumSize =
      PaintingBinding.instance.imageCache.maximumSize;
  late final int _oldMaximumSizeBytes =
      PaintingBinding.instance.imageCache.maximumSizeBytes;

  // 这个 demo 的核心对比：
  // 1. Bad Case：一次性预缓存全部图片 + 很大的 cacheExtent + 更大的解码尺寸
  // 2. Optimized：只预缓存首屏和下一小段图片 + 较小的 cacheExtent + 页面退出时主动清理
  bool get _isBadCase => widget.mode == DemoMode.bad;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    // 等首帧渲染完以后再做预缓存。
    // 否则 context 还没稳定，precacheImage 的使用时机会比较差。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_isBadCase) {
        // 反例：页面一进来就把所有图片都塞进缓存。
        // 这样短时间内会拉高内存峰值，列表还没滑到的内容也提前占掉内存。
        _runAggressivePrecache();
      } else {
        // 正例：先把当前页面 imageCache 的容量收紧，避免这个场景无限吃内存。
        _configureScopedImageCache();

        // 只预缓存首屏附近的几张图。
        // 用户马上要看到的图提前准备好，既能减少白屏，也不会一次性占太多内存。
        _precacheWindow(startIndex: 0, count: 6);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    if (!_isBadCase) {
      // 退出页面时把 imageCache 的全局限制恢复掉，避免影响别的页面。
      _restoreImageCache();

      // 再把这个页面用到的图片从缓存里移除。
      // 这就是“按场景清理缓存”的一个常见做法。
      _evictCurrentSceneImages();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = _isBadCase
        ? '反例：页面一打开就预缓存全部图片，并把列表预构建范围拉得很大。'
        : '优化版：只预缓存首屏和下一小段内容，同时限制当前页面的图片缓存。';

    return Column(
      children: [
        _CaseHeader(
          title: _isBadCase ? 'Bad Case 反例' : 'Optimized 优化版',
          description: description,
          bullets: _isBadCase
              ? const [
                  '首帧后把全部列表图片都 precache 进缓存',
                  'cacheExtent 故意设得很大，列表会提前构建更多 item',
                  '页面退出时不做场景级图片清理',
                ]
              : const [
                  '只预缓存当前可见区域和接下来几张图',
                  '使用更小的 cacheExtent，避免过度预构建',
                  '限制 imageCache 容量，并在退出时 evict 当前场景图片',
                ],
          actions: [
            TextButton(
              onPressed: () => _precacheWindow(startIndex: 0, count: 4),
              child: const Text('预缓存前 4 张'),
            ),
            TextButton(
              onPressed: _evictCurrentSceneImages,
              child: const Text('清理当前场景图片'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            // cacheExtent 越大，ListView 越会“提前”构建更多还没滚到屏幕里的子项。
            // 如果 item 里还有图片、复杂布局、视频缩略图，就会放大内存压力。
            //
            // 这里故意做两个值：
            // Bad Case = 1800，接近提前缓存 10 个以上 item
            // Optimized = 280，只保留更小的预构建范围
            cacheExtent: _isBadCase ? 1800 : 280,
            itemCount: _items.length,
            itemExtent: _itemHeight,
            itemBuilder: (context, index) {
              final item = _items[index];
              final provider = _imageProviderFor(item);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                        child: Image(
                          image: provider,
                          width: 140,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isBadCase
                                    ? 'Large decode + aggressive cache'
                                    : 'Small decode + scoped cache',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleScroll() {
    if (_isBadCase) {
      return;
    }

    // 优化版在滚动时只预取“即将进入屏幕”的几张图。
    // 这样做的目标是：既保证滑动流畅，又避免把整页图片一次性都缓存起来。
    final currentIndex = (_scrollController.offset / _itemHeight).floor();
    _precacheWindow(startIndex: currentIndex + 1, count: 3);
  }

  // 反例方法：
  // 页面刚展示完，就把所有 item 对应图片都做 precache。
  //
  // precacheImage 的含义：
  // “提前把图片解码并放入 Flutter 的图片缓存里”，这样真正显示时更快。
  //
  // 它的问题不在于 API 本身，而在于“过度使用”：
  // 你明明只会先看到首屏 5~6 张图，却把 90 张图都缓存了，内存会明显升高。
  Future<void> _runAggressivePrecache() async {
    for (final item in _items) {
      await precacheImage(_imageProviderFor(item), context);
    }
  }

  // 把当前页面的 imageCache 收紧。
  // maximumSize: 最多缓存多少个图片对象
  // maximumSizeBytes: 最多缓存多少字节
  //
  // 这不是唯一标准值，只是 demo 里用来演示“页面级限流”的思路。
  void _configureScopedImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 30;
    imageCache.maximumSizeBytes = 20 << 20;
  }

  // 页面销毁后恢复之前的全局配置，避免这个示例页影响别的页面。
  void _restoreImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = _oldMaximumSize;
    imageCache.maximumSizeBytes = _oldMaximumSizeBytes;
  }

  // 优化版方法：
  // 只预缓存一个“窗口范围”内的图片，而不是全部预缓存。
  //
  // 例如：
  // startIndex = 10, count = 3
  // 就表示：只预缓存第 10、11、12 这三张图。
  //
  // 这样做的收益：
  // 1. 首屏和即将出现的图片展示更快
  // 2. 没滚到的远处图片不会提前占掉大量内存
  Future<void> _precacheWindow({
    required int startIndex,
    required int count,
  }) async {
    final endIndex = (startIndex + count).clamp(0, _items.length);
    for (var index = startIndex; index < endIndex; index++) {
      await precacheImage(_imageProviderFor(_items[index]), context);
    }
  }

  // “按场景清理缓存”的示例方法。
  //
  // evict() 的含义：
  // 把这个 ImageProvider 对应的图片从 Flutter 图片缓存中移除。
  //
  // 你可以把它理解成：
  // precacheImage(...) = 提前放进缓存
  // provider.evict()    = 主动从缓存里移走
  //
  // 为什么这里要循环所有 item？
  // 因为这个页面里每个 item 都可能把自己的图片放进过缓存，
  // 退出页面时，我们就把“这个场景用过的图片”统一清掉。
  //
  // 注意：
  // evict 只是“让缓存不再持有它”，不是立刻强制回收内存。
  // 真正回收还要等这些图片没有别的引用后，由 GC 和底层内存机制处理。
  Future<void> _evictCurrentSceneImages() async {
    for (final item in _items) {
      await _imageProviderFor(item).evict();
    }
  }

  // 这里故意让 Bad Case 和 Optimized 使用不同的解码宽度。
  //
  // cacheWidth 越大，图片解码后的内存占用通常越高。
  // 所以 Bad Case 不只是“缓存更多张”，还故意“每张图解码得更大”，
  // 这样在 DevTools 里更容易观察出差异。
  ImageProvider<Object> _imageProviderFor(_DemoItem item) {
    final asset = AssetImage(item.assetPath);
    final cacheWidth =
        _isBadCase ? 1200 + (item.id % 8) * 120 : 320 + (item.id % 3) * 40;

    return ResizeImage.resizeIfNeeded(cacheWidth, null, asset);
  }
}

class _CaseHeader extends StatelessWidget {
  const _CaseHeader({
    required this.title,
    required this.description,
    required this.bullets,
    required this.actions,
  });

  final String title;
  final String description;
  final List<String> bullets;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF4FBF8),
        border: Border.all(color: const Color(0xFFD3ECE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $bullet'),
            ),
          Wrap(spacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _DemoItem {
  const _DemoItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  final int id;
  final String title;
  final String subtitle;
  final String assetPath;
}

const List<String> _assetPool = [
  'assets/images/1.png',
  'assets/images/hot.png',
  'assets/images/ok.png',
  'assets/simform.png',
];
