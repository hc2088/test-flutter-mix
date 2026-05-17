/// Flutter library to load and cache network images.
/// Can also be used with placeholder and error widgets.
///
/// 给源码阅读者的整体视角：
/// - [CachedNetworkImage] 是给业务层直接使用的 Widget API。
/// - [CachedNetworkImageProvider] 负责把这个包接入 Flutter 标准的
///   `ImageProvider -> ImageStream -> Image` 图像管线。
/// - 平台侧的 `ImageLoader` 负责和 `flutter_cache_manager` 协作，完成
///   下载、磁盘缓存复用、以及分块进度事件上报。
/// - [MultiImageStreamCompleter] 负责把解码后的 codec / frame 继续交给
///   Flutter 的图像流体系。
///
/// 这里实际存在两层缓存：
/// - `flutter_cache_manager` 负责“磁盘上的原始图片字节缓存”。
/// - Flutter 全局 `ImageCache` 负责“内存中的解码后位图缓存”。
library cached_network_image;

export 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show CacheManagerLogLevel, DownloadProgress;

export 'src/cached_image_widget.dart';
export 'src/image_provider/cached_network_image_provider.dart';
export 'src/image_provider/multi_image_stream_completer.dart';
