import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 打开缓存层日志，便于你一边看源码一边观察下载、命中、驱逐这些行为。
  CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;

  runApp(const CachedNetworkImageSourceStudyApp());
}

class CachedNetworkImageSourceStudyApp extends StatelessWidget {
  const CachedNetworkImageSourceStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cached_network_image 源码学习',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0E7C66),
        scaffoldBackgroundColor: const Color(0xFFF4F8F6),
      ),
      home: const CachedNetworkImageStudyHome(),
    );
  }
}

class CachedNetworkImageStudyHome extends StatelessWidget {
  const CachedNetworkImageStudyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('cached_network_image 源码导读'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'API 示例'),
              Tab(text: '缓存实验'),
              Tab(text: '性能优化'),
              Tab(text: '面试提纲'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FeatureGalleryPage(),
            CacheLabPage(),
            PerformancePatternsPage(),
            InterviewCheatSheetPage(),
          ],
        ),
      ),
    );
  }
}

// 这个自定义 CacheManager 的作用是：
// 1. 把磁盘缓存策略显式写出来，便于你理解 stalePeriod / maxNrOfCacheObjects；
// 2. 配合 memCacheWidth / maxWidthDiskCache 观察“内存缩放”和“磁盘缩放”的区别。
class InterviewCacheManager extends CacheManager with ImageCacheManager {
  InterviewCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 40,
          ),
        );

  static const key = 'interviewImageCache';
  static final InterviewCacheManager instance = InterviewCacheManager._();
}

class DemoImageUrls {
  static const hero =
      'https://images.unsplash.com/photo-1532264523420-881a47db012d?auto=format&fit=crop&w=1400&q=80';
  static const builder =
      'https://images.unsplash.com/photo-1511497584788-876760111969?auto=format&fit=crop&w=1400&q=80';
  static const provider =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80';
  static const avatar =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80';
  static const invalid =
      'https://example.invalid/cached-network-image-demo.jpg';
  static const signedVariantA =
      'https://picsum.photos/id/1062/1600/900?signature=one';
  static const signedVariantB =
      'https://picsum.photos/id/1062/1600/900?signature=two';
  static const switchA = 'https://picsum.photos/id/1015/1200/800';
  static const switchB = 'https://picsum.photos/id/1039/1200/800';
  static const large = 'https://picsum.photos/id/1025/1800/1200';
  static final List<String> feed = List<String>.generate(
    12,
    (index) => 'https://picsum.photos/seed/feed-$index/900/600',
  );
  static final List<String> grid = List<String>.generate(
    18,
    (index) => 'https://picsum.photos/seed/grid-$index/600/600',
  );
}

class FeatureGalleryPage extends StatefulWidget {
  const FeatureGalleryPage({super.key});

  @override
  State<FeatureGalleryPage> createState() => _FeatureGalleryPageState();
}

class _FeatureGalleryPageState extends State<FeatureGalleryPage> {
  String _latestError = '当前还没有捕获到图片加载错误。';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _IntroCard(
          title: '先建立整体链路',
          message: '建议你一边点这个 demo，一边看 cached_network_image 源码。'
              '最重要的链路是：CachedNetworkImage（Widget 层）'
              ' -> CachedNetworkImageProvider（接入 Flutter ImageProvider）'
              ' -> ImageLoader（下载、磁盘缓存、解码）'
              ' -> MultiImageStreamCompleter（把 frame 发给 Flutter）。',
        ),
        _StudyPanel(
          title: '1. placeholder / fadeIn / errorWidget',
          note: '这是业务里最常见的入口。图片真正解析前，先显示占位态；'
              '解码完成后再淡入替换。如果失败，则走错误态。',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: CachedNetworkImage(
                imageUrl: DemoImageUrls.hero,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 500),
                placeholderFadeInDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) => const _PosterPlaceholder(
                  title: 'placeholder',
                  subtitle: '首屏先给用户一个稳定结构，避免白屏和抖动。',
                ),
                errorWidget: (context, url, error) => const _ErrorState(),
              ),
            ),
          ),
        ),
        _StudyPanel(
          title: '2. progressIndicatorBuilder',
          note: 'ImageLoader 会把底层下载进度转换成 Flutter 的 ImageChunkEvent，'
              '然后这里再包装成 DownloadProgress 暴露给业务层。',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: CachedNetworkImage(
                imageUrl: DemoImageUrls.builder,
                fit: BoxFit.cover,
                httpHeaders: const {'x-demo-request': 'progress-panel'},
                progressIndicatorBuilder: (context, url, progress) {
                  final percent = progress.progress;
                  return DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7F3EE),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(value: percent),
                          const SizedBox(height: 12),
                          Text(
                            percent == null
                                ? '正在接收图片字节...'
                                : '已下载 ${(percent * 100).round()}%',
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) => const _ErrorState(),
              ),
            ),
          ),
        ),
        _StudyPanel(
          title: '3. imageBuilder 和 provider 复用',
          note: '这个包真正的核心不是“只能显示一张网络图”，而是把缓存能力做进了'
              ' ImageProvider。这样同一个 provider 可以复用给 Image、'
              'DecorationImage、CircleAvatar、precacheImage。',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 190,
                        child: CachedNetworkImage(
                          imageUrl: DemoImageUrls.builder,
                          fit: BoxFit.cover,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                                colorFilter: const ColorFilter.mode(
                                  Colors.black26,
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.bottomLeft,
                            child: const Text(
                              'imageBuilder 的价值是：\n'
                              '缓存逻辑照旧，但 UI 壳子你可以完全自定义。',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          placeholder: (context, url) =>
                              const _PosterPlaceholder(
                            title: 'imageBuilder',
                            subtitle: '这里最终渲染的并不是默认 Image，而是自定义容器。',
                          ),
                          errorWidget: (context, url, error) =>
                              const _ErrorState(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('适合圆角卡片、带蒙层封面、背景图容器这类场景。'),
                  ],
                ),
              ),
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 190,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundImage: CachedNetworkImageProvider(
                              DemoImageUrls.avatar,
                              cacheKey: 'provider-avatar-demo',
                            ),
                            backgroundColor: Color(0xFFD9E9E3),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '这里直接用了 CachedNetworkImageProvider。\n'
                              '这就是为什么源码重点要看 provider 层，而不只是 widget 层。',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: const SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image(
                          image: CachedNetworkImageProvider(
                            DemoImageUrls.provider,
                            cacheKey: 'provider-landscape-demo',
                            maxWidth: 1200,
                            maxHeight: 800,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _StudyPanel(
          title: '4. errorListener',
          note: 'UI 错误态和日志上报最好分离。errorWidget 负责“用户看什么”，'
              'errorListener 负责“开发者记录什么”。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 180,
                  child: CachedNetworkImage(
                    imageUrl: DemoImageUrls.invalid,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const _PosterPlaceholder(
                      title: '错误示例',
                      subtitle: '这里故意给一个错误地址，观察 UI 回退和日志回调。',
                    ),
                    errorWidget: (context, url, error) => const _ErrorState(),
                    errorListener: (error) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _latestError = '${error.runtimeType}: $error';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectionArea(
                child: Text(
                  '最近一次错误回调：\n$_latestError',
                  style: _monoStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CacheLabPage extends StatefulWidget {
  const CacheLabPage({super.key});

  @override
  State<CacheLabPage> createState() => _CacheLabPageState();
}

class _CacheLabPageState extends State<CacheLabPage> {
  static const _stableCacheKey = 'signed-hero-demo';
  static const _diskCacheWidth = 1280;
  static const _diskCacheHeight = 720;

  int _variantIndex = 0;
  String _memoryStatus = '等图片加载完以后，点击“查看缓存状态”。';
  String _diskStatus = '等图片加载完以后，点击“查看缓存状态”。';
  String _lastAction = '当前还没有执行缓存操作。';

  String get _variantUrl => _variantIndex == 0
      ? DemoImageUrls.signedVariantA
      : DemoImageUrls.signedVariantB;

  String get _resizedCacheKey =>
      'resized_w${_diskCacheWidth}_h${_diskCacheHeight}_$_stableCacheKey';

  CachedNetworkImageProvider _provider() {
    return CachedNetworkImageProvider(
      _variantUrl,
      cacheManager: InterviewCacheManager.instance,
      cacheKey: _stableCacheKey,
      maxWidth: _diskCacheWidth,
      maxHeight: _diskCacheHeight,
      headers: const {'x-demo-auth': 'interview-token'},
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDiagnostics();
    });
  }

  Future<void> _refreshDiagnostics() async {
    final provider = _provider();
    final imageCache = PaintingBinding.instance.imageCache;
    final status = await provider.obtainCacheStatus(
      configuration: createLocalImageConfiguration(context),
    );
    final original = await InterviewCacheManager.instance.getFileFromCache(
      _stableCacheKey,
      ignoreMemCache: true,
    );
    final resized = await InterviewCacheManager.instance.getFileFromCache(
      _resizedCacheKey,
      ignoreMemCache: true,
    );

    final memoryStatus = [
      'Provider 在 Flutter ImageCache 中的状态：${_formatCacheStatus(status)}',
      'ImageCache 当前条目数：${imageCache.currentSize}',
      'liveImageCount：${imageCache.liveImageCount}',
      'pendingImageCount：${imageCache.pendingImageCount}',
      '解码后位图占用：${_formatBytes(imageCache.currentSizeBytes)}',
    ].join('\n');

    final diskStatus = [
      '当前 URL 变体：$_variantUrl',
      '稳定 cacheKey：$_stableCacheKey',
      '缩略图磁盘 key：$_resizedCacheKey',
      '',
      await _describeFileInfo('原图缓存项', original),
      '',
      await _describeFileInfo('缩放缓存项', resized),
    ].join('\n');

    if (!mounted) {
      return;
    }
    setState(() {
      _memoryStatus = memoryStatus;
      _diskStatus = diskStatus;
    });
  }

  Future<String> _describeFileInfo(String label, FileInfo? fileInfo) async {
    if (fileInfo == null) {
      return '$label：未命中。';
    }
    final fileSize = await fileInfo.file.length();
    return '$label：\n'
        'path: ${fileInfo.file.path}\n'
        'validTill: ${fileInfo.validTill.toLocal().toIso8601String()}\n'
        'bytes: ${_formatBytes(fileSize)}';
  }

  void _setAction(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _lastAction = message;
    });
  }

  Future<void> _precacheExactProvider() async {
    await precacheImage(_provider(), context);
    _setAction(
      '已经 precache 当前 provider。理论上接下来再次显示它时，会优先命中内存缓存。',
    );
    await _refreshDiagnostics();
  }

  Future<void> _inspectCaches() async {
    _setAction('已刷新缓存诊断信息。');
    await _refreshDiagnostics();
  }

  Future<void> _evictExactProvider() async {
    await InterviewCacheManager.instance.removeFile(_stableCacheKey);
    await InterviewCacheManager.instance.removeFile(_resizedCacheKey);
    await _provider().evict();
    _setAction(
      '已删除原图磁盘缓存、缩放后的磁盘缓存，以及对应的 Flutter 内存缓存。',
    );
    await _refreshDiagnostics();
  }

  Future<void> _clearDiskCache() async {
    await InterviewCacheManager.instance.emptyCache();
    _setAction('已清空自定义 CacheManager 的磁盘缓存。');
    await _refreshDiagnostics();
  }

  Future<void> _clearFlutterMemoryCache() async {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
    _setAction('已清空 Flutter 的全局图片内存缓存。');
    await _refreshDiagnostics();
  }

  Future<void> _switchSignedUrlVariant() async {
    setState(() {
      _variantIndex = (_variantIndex + 1) % 2;
      _lastAction = '已在两个“看起来像签名 URL”的地址之间切换，但保持了同一 cacheKey。'
          '只有当两个 URL 真的是同一张图时，这种做法才安全。';
    });
    await _refreshDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _IntroCard(
          title: '磁盘缓存 vs 内存缓存',
          message: '面试里经常会被问到：磁盘缓存和 Flutter ImageCache 到底是什么关系？'
              '这一页就是专门拿来做实验的。你可以直接观察 cacheKey、'
              '缩放后的磁盘文件、以及全局 ImageCache 的状态变化。',
        ),
        _StudyPanel(
          title: '交互式缓存实验',
          note: '下面这张图同时用了自定义 CacheManager、稳定 cacheKey、'
              'memCacheWidth、maxWidthDiskCache。按钮的目的不是“演示 API”，'
              '而是帮助你把源码里的缓存逻辑和运行时现象对应起来。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 240,
                  child: CachedNetworkImage(
                    imageUrl: _variantUrl,
                    cacheManager: InterviewCacheManager.instance,
                    cacheKey: _stableCacheKey,
                    httpHeaders: const {'x-demo-auth': 'interview-token'},
                    fit: BoxFit.cover,
                    memCacheWidth: 720,
                    memCacheHeight: 405,
                    maxWidthDiskCache: _diskCacheWidth,
                    maxHeightDiskCache: _diskCacheHeight,
                    // 注意：底层的 octo_image 要求 placeholder 和
                    // progressIndicatorBuilder 只能二选一，不能同时传。
                    // 这里把“占位底图 + 进度层”合并进 progress builder，
                    // 这样既能保留演示效果，也符合组件约束。
                    progressIndicatorBuilder: (context, url, progress) =>
                        _ProgressPosterState(
                      progress: progress.progress,
                      title: '缓存实验图',
                      subtitle: '观察 cacheKey、驱逐、precache、缩放后的磁盘缓存。',
                    ),
                    errorWidget: (context, url, error) => const _ErrorState(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip('stalePeriod: 7 天'),
                  _InfoChip('max objects: 40'),
                  _InfoChip('memCacheWidth: 720'),
                  _InfoChip('disk resize: 1280 x 720'),
                ],
              ),
              const SizedBox(height: 12),
              SelectionArea(
                child: Text(
                  '当前 cacheKey：$_stableCacheKey\n'
                  '当前 URL 变体：$_variantUrl',
                  style: _monoStyle,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonal(
                    onPressed: _switchSignedUrlVariant,
                    child: const Text('切换签名 URL'),
                  ),
                  FilledButton.tonal(
                    onPressed: _precacheExactProvider,
                    child: const Text('precache 当前 provider'),
                  ),
                  FilledButton.tonal(
                    onPressed: _inspectCaches,
                    child: const Text('查看缓存状态'),
                  ),
                  FilledButton.tonal(
                    onPressed: _evictExactProvider,
                    child: const Text('精确驱逐当前图'),
                  ),
                  FilledButton.tonal(
                    onPressed: _clearDiskCache,
                    child: const Text('清空磁盘缓存'),
                  ),
                  FilledButton.tonal(
                    onPressed: _clearFlutterMemoryCache,
                    child: const Text('清空 Flutter 内存缓存'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_lastAction),
            ],
          ),
        ),
        _StudyPanel(
          title: 'Flutter 内存缓存诊断',
          note: '这里看到的是 Flutter ImageCache，也就是“解码后位图缓存”。'
              '即使磁盘命中了，如果解码尺寸太大、频繁被清掉重建，依然会卡。',
          child: SelectionArea(
            child: Text(_memoryStatus, style: _monoStyle),
          ),
        ),
        _StudyPanel(
          title: '磁盘缓存诊断',
          note: '当你使用 maxWidthDiskCache / maxHeightDiskCache 时，'
              '磁盘上可能同时存在“原图缓存项”和“缩放缓存项”。'
              '这也是为什么驱逐缓存时，经常不能只删一个 key。',
          child: SelectionArea(
            child: Text(_diskStatus, style: _monoStyle),
          ),
        ),
      ],
    );
  }
}

class PerformancePatternsPage extends StatefulWidget {
  const PerformancePatternsPage({super.key});

  @override
  State<PerformancePatternsPage> createState() =>
      _PerformancePatternsPageState();
}

class _PerformancePatternsPageState extends State<PerformancePatternsPage> {
  int _switchIndex = 0;

  String get _switchUrl =>
      _switchIndex == 0 ? DemoImageUrls.switchA : DemoImageUrls.switchB;

  void _toggleUrl() {
    setState(() {
      _switchIndex = (_switchIndex + 1) % 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _IntroCard(
          title: '把 API 翻译成性能结论',
          message: '这一页不是为了记 API 名字，而是为了把“参数”翻译成'
              '“性能影响”。尤其要关注：减少解码像素、减少列表过度预构建、'
              '减少 URL 切换闪烁、减少重复下载和重复解码。',
        ),
        _StudyPanel(
          title: '1. useOldImageOnUrlChange',
          note: '当同一个位置的图片 URL 发生变化时，默认行为可能会先闪空；'
              'useOldImageOnUrlChange 会在新图完成前继续显示旧图，提升感知稳定性。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.tonal(
                onPressed: _toggleUrl,
                child: const Text('切换 URL'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _PreviewCard(
                    title: '默认行为',
                    subtitle: '旧图先消失，新图 resolve 完再出现。',
                    child: CachedNetworkImage(
                      imageUrl: _switchUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 500),
                      placeholder: (context, url) => const _PosterPlaceholder(
                        title: '默认切换',
                        subtitle: 'URL 变化时更容易出现闪烁感。',
                      ),
                      errorWidget: (context, url, error) => const _ErrorState(),
                    ),
                  ),
                  _PreviewCard(
                    title: '开启 useOldImageOnUrlChange',
                    subtitle: '新图没准备好前，先保持旧图可见。',
                    child: CachedNetworkImage(
                      imageUrl: _switchUrl,
                      useOldImageOnUrlChange: true,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 500),
                      placeholder: (context, url) => const _PosterPlaceholder(
                        title: 'gapless',
                        subtitle: '更适合轮播图、详情页封面、头像切换。',
                      ),
                      errorWidget: (context, url, error) => const _ErrorState(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _StudyPanel(
          title: '2. 少解码像素，才是真的省内存',
          note: 'memCacheWidth / memCacheHeight 控制“内存里的解码尺寸”；'
              'maxWidthDiskCache / maxHeightDiskCache 控制“落到磁盘里的缩放尺寸”。'
              '缩略图、列表卡片、网格图，千万别直接解码原图。',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ResizeComparisonCard(
                title: '原始解码',
                subtitle: '真的需要原始大图时再这么做，否则容易浪费内存和上传成本。',
                memCacheWidth: null,
                memCacheHeight: null,
                maxWidthDiskCache: null,
                maxHeightDiskCache: null,
              ),
              _ResizeComparisonCard(
                title: '按 UI 尺寸缩放',
                subtitle: '更适合卡片和列表：更小的解码、更小的磁盘衍生图。',
                memCacheWidth: 360,
                memCacheHeight: 240,
                maxWidthDiskCache: 720,
                maxHeightDiskCache: 480,
              ),
            ],
          ),
        ),
        _StudyPanel(
          title: '3. 列表缩略图策略',
          note: '面试里回答列表图片优化时，尽量同时提三点：'
              'builder 列表、固定 item 尺寸、按缩略图尺寸解码。',
          child: SizedBox(
            height: 320,
            child: ListView.builder(
              cacheExtent: 420,
              itemCount: DemoImageUrls.feed.length,
              itemExtent: 104,
              itemBuilder: (context, index) {
                final url = DemoImageUrls.feed[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                            memCacheWidth: 240,
                            memCacheHeight: 160,
                            maxWidthDiskCache: 240,
                            maxHeightDiskCache: 160,
                            placeholder: (context, url) =>
                                const _SmallPlaceholder(),
                            errorWidget: (context, url, error) =>
                                const _ErrorState(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '列表项 $index\n'
                            '固定尺寸 + builder + 缩略图解码。',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _StudyPanel(
          title: '4. GridView 缩略图策略',
          note: '网格比列表更容易把图片数量堆上去，所以也更容易在面试里被追问：'
              '为什么小格子不能直接解码全尺寸原图？',
          child: SizedBox(
            height: 320,
            child: GridView.builder(
              cacheExtent: 240,
              itemCount: DemoImageUrls.grid.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: DemoImageUrls.grid[index],
                    fit: BoxFit.cover,
                    memCacheWidth: 220,
                    memCacheHeight: 220,
                    maxWidthDiskCache: 220,
                    maxHeightDiskCache: 220,
                    placeholder: (context, url) => const _SmallPlaceholder(),
                    errorWidget: (context, url, error) => const _ErrorState(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class InterviewCheatSheetPage extends StatelessWidget {
  const InterviewCheatSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: const [
          _IntroCard(
            title: '如何把这套源码讲成面试答案',
            message: '面试里最忌讳的是只会背 API，不会讲原理。'
                '这一页就是把“源码结构”、“运行时现象”和“性能优化建议”'
                '整理成你可以直接复述的答案骨架。',
          ),
          _BulletPanel(
            title: '推荐源码阅读顺序',
            note: '这几个文件分别回答不同层面的问题。',
            bullets: [
              'lib/src/cached_image_widget.dart：看 Widget 层 API、placeholder / progress / error 怎么串起来。',
              'lib/src/image_provider/cached_network_image_provider.dart：看这个包是怎么接进 Flutter ImageProvider 管线的。',
              'lib/src/image_provider/_image_loader.dart：看真正的下载、磁盘缓存、缩放、解码发生在哪里。',
              'lib/src/image_provider/multi_image_stream_completer.dart：看 frame 是怎么继续交给 Flutter 调度和绘制的。',
            ],
          ),
          _BulletPanel(
            title: '一段简洁但有层次的架构回答',
            note: '这段话非常适合用在“你理解 cached_network_image 原理吗？”这种问题上。',
            bullets: [
              'cached_network_image 并不是重写了一套 Flutter 图片体系，而是通过 ImageProvider 接进现有体系。',
              'flutter_cache_manager 负责缓存原始图片文件到磁盘；Flutter ImageCache 负责缓存解码后的位图到内存。',
              'ImageLoader 负责把磁盘 / 网络阶段的结果转换成 codec 流；MultiImageStreamCompleter 再把 frame 发给 Flutter。',
              '所以它解决的不只是“网络图显示”，而是“下载复用、缓存复用、加载反馈、解码交付”这一整条链路。',
            ],
          ),
          _BulletPanel(
            title: '必须点名的性能杠杆',
            note: '这些参数和策略，是最能体现你不是只会背 API 的部分。',
            bullets: [
              'memCacheWidth / memCacheHeight：控制内存里的解码尺寸，直接影响 RAM 和 GPU 上传成本。',
              'maxWidthDiskCache / maxHeightDiskCache：把更小的衍生图落盘，后续重复进入页面时不必总拿原图。',
              'cacheKey：当签名 URL 或埋点参数变化，但资源本体没变时，用稳定 key 避免重复缓存。',
              'precacheImage：用空间换时间，让下一屏或下一次展示更顺滑。',
              'useOldImageOnUrlChange：避免 URL 切换时闪烁，提升感知稳定性。',
            ],
          ),
          _BulletPanel(
            title: '面试时最好主动指出的常见错误',
            note: '会主动指出坑点，往往比单纯讲功能更像高级工程师。',
            bullets: [
              '把 4K 大图直接解码进一个很小的头像或缩略图控件。',
              '以为磁盘缓存命中就万事大吉，却忽略了解码后的内存缓存仍然可能频繁抖动。',
              '大列表里既不限制 item 尺寸，也不给缩略图解码尺寸，还把 cacheExtent 开得很大。',
              '忽略了“同一张图可能对应多个缓存对象”：原图文件、缩放文件、解码后的内存帧。',
            ],
          ),
          _BulletPanel(
            title: '建议你怎么继续练',
            note: '最好的巩固方式，是把这个 demo 和 Flutter 自带 Image.network 对照着看。',
            bullets: [
              '运行这个 demo 时打开控制台，看 CacheManagerLogLevel.debug 的输出和页面操作如何对应。',
              '把列表 / 网格里的 memCacheWidth 和 maxWidthDiskCache 删掉，再观察滚动和缓存诊断变化。',
              '把 stable cacheKey 改成随 URL 一起变化，再观察磁盘缓存项是如何重复生成的。',
              '把同一套思路迁移到 Image.network，比较它缺少了哪些用户体验和缓存控制能力。',
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyPanel extends StatelessWidget {
  const _StudyPanel({
    required this.title,
    required this.note,
    required this.child,
  });

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(note),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF0E7C66),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPanel extends StatelessWidget {
  const _BulletPanel({
    required this.title,
    required this.note,
    required this.bullets,
  });

  final String title;
  final String note;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(note),
            const SizedBox(height: 12),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('• $bullet'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResizeComparisonCard extends StatelessWidget {
  const _ResizeComparisonCard({
    required this.title,
    required this.subtitle,
    required this.memCacheWidth,
    required this.memCacheHeight,
    required this.maxWidthDiskCache,
    required this.maxHeightDiskCache,
  });

  final String title;
  final String subtitle;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      title: title,
      subtitle: subtitle,
      child: CachedNetworkImage(
        imageUrl: DemoImageUrls.large,
        fit: BoxFit.cover,
        // 约束“解码后放进 Flutter 内存缓存”的位图尺寸。
        // 这是控制内存峰值最直接的手段之一，特别适合列表缩略图。
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        // 约束“写入磁盘缓存文件”的尺寸上限。
        // 开启后磁盘里保存的是缩小后的文件，而不一定是原始大图。
        maxWidthDiskCache: maxWidthDiskCache,
        maxHeightDiskCache: maxHeightDiskCache,
        // 缩放采样质量。质量越高通常越平滑，但采样成本也会略高一些。
        filterQuality: FilterQuality.medium,
        placeholder: (context, url) => const _PosterPlaceholder(
          title: '解码尺寸对比',
          subtitle: '重点观察的是内存解码成本，而不是只看网络请求。',
        ),
        errorWidget: (context, url, error) => const _ErrorState(),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFE2F0EB),
      side: BorderSide.none,
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBEEE7), Color(0xFFC7E2D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Icon(Icons.image_outlined,
                size: 30, color: Color(0xFF0E7C66)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  const _SmallPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFDCECE6),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ProgressPosterState extends StatelessWidget {
  const _ProgressPosterState({
    required this.title,
    required this.subtitle,
    this.progress,
  });

  final String title;
  final String subtitle;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PosterPlaceholder(
          title: title,
          subtitle: subtitle,
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0x330E7C66),
          ),
          child: Center(
            child: CircularProgressIndicator(value: progress),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFDECEC),
      child: Center(
        child: Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final fractionDigits = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
}

String _formatCacheStatus(ImageCacheStatus? status) {
  if (status == null) {
    return 'untracked';
  }
  return 'pending=${status.pending}, live=${status.live}, keepAlive=${status.keepAlive}';
}

const _monoStyle = TextStyle(
  fontFamily: 'monospace',
  height: 1.4,
);
