import 'dart:async' show Future, StreamController;
import 'dart:ui' as ui show Codec;

import 'package:cached_network_image/src/image_provider/multi_image_stream_completer.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ErrorListener, ImageRenderMethodForWeb;
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    if (dart.library.io) '_image_loader.dart'
    if (dart.library.js_interop) 'package:cached_network_image_web/cached_network_image_web.dart'
    show ImageLoader;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// IO implementation of the CachedNetworkImageProvider; the ImageProvider to
/// load network images using a cache.
///
/// 这个类是“包内缓存逻辑”和“Flutter 图像管线”之间的桥梁。
/// 当 Widget 请求 Flutter 去 resolve 这个 provider 时，它会创建
/// [ImageStreamCompleter]，并持续把解码后的图像帧往外发。
@immutable
class CachedNetworkImageProvider
    extends ImageProvider<CachedNetworkImageProvider> {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const CachedNetworkImageProvider(
    this.url, {
    this.maxHeight,
    this.maxWidth,
    this.scale = 1.0,
    this.errorListener,
    this.headers,
    this.cacheManager,
    this.cacheKey,
    this.imageRenderMethodForWeb = ImageRenderMethodForWeb.HtmlImage,
  });

  /// CacheManager from which the image files are loaded.
  final BaseCacheManager? cacheManager;

  /// The default cache manager used for image caching.
  static BaseCacheManager defaultCacheManager = DefaultCacheManager();

  /// Web url of the image to load
  final String url;

  /// Cache key of the image to cache
  final String? cacheKey;

  /// Scale of the image
  final double scale;

  /// Listener to be called when images fails to load.
  final ErrorListener? errorListener;

  /// Set headers for the image provider, for example for authentication
  final Map<String, String>? headers;

  /// Maximum height of the loaded image. If not null and using an
  /// [ImageCacheManager] the image is resized on disk to fit the height.
  final int? maxHeight;

  /// Maximum width of the loaded image. If not null and using an
  /// [ImageCacheManager] the image is resized on disk to fit the width.
  final int? maxWidth;

  /// Render option for images on the web platform.
  final ImageRenderMethodForWeb imageRenderMethodForWeb;

  @override
  Future<CachedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<CachedNetworkImageProvider>(this);
  }

  @Deprecated('loadBuffer is deprecated, use loadImage instead')
  @override
  ImageStreamCompleter loadBuffer(
    CachedNetworkImageProvider key,
    DecoderBufferCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    // Flutter Widget 最终监听的是 ImageStreamCompleter。
    // MultiImageStreamCompleter 会接住 ImageLoader 产出的 codec 流，
    // 再把解码帧按 Flutter 约定继续分发出去。
    final imageStreamCompleter = MultiImageStreamCompleter(
      codec: _loadBufferAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<CachedNetworkImageProvider>('Image key', key),
      ],
    );

    if (errorListener != null) {
      imageStreamCompleter.addListener(
        ImageStreamListener(
          (image, synchronousCall) {},
          onError: (Object error, StackTrace? trace) {
            errorListener?.call(error);
          },
        ),
      );
    }

    return imageStreamCompleter;
  }

  @Deprecated('_loadBufferAsync is deprecated, use _loadImageAsync instead')
  Stream<ui.Codec> _loadBufferAsync(
    CachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback decode,
  ) {
    assert(key == this);
    // 把 evict 回调继续往下传。
    // 这样异步加载失败时，loader 就可以顺手清掉可能只记录了一半的内存缓存项。
    return ImageLoader().loadBufferAsync(
      url,
      cacheKey,
      chunkEvents,
      decode,
      cacheManager ?? defaultCacheManager,
      maxHeight,
      maxWidth,
      headers,
      imageRenderMethodForWeb,
      () => PaintingBinding.instance.imageCache.evict(key),
    );
  }

  @override
  ImageStreamCompleter loadImage(
    CachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    // 和 loadBuffer 是同一条链路，只是走的是 Flutter 当前推荐的 loadImage API。
    final imageStreamCompleter = MultiImageStreamCompleter(
      codec: _loadImageAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<CachedNetworkImageProvider>('Image key', key),
      ],
    );

    if (errorListener != null) {
      imageStreamCompleter.addListener(
        ImageStreamListener(
          (image, synchronousCall) {},
          onError: (Object error, StackTrace? trace) {
            errorListener?.call(error);
          },
        ),
      );
    }

    return imageStreamCompleter;
  }

  Stream<ui.Codec> _loadImageAsync(
    CachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) {
    assert(key == this);
    // ImageLoader 屏蔽了平台差异（IO / Web）。
    // 一旦底层拿到字节并完成解码，就会立刻把 codec 往上游产出。
    return ImageLoader().loadImageAsync(
      url,
      cacheKey,
      chunkEvents,
      decode,
      cacheManager ?? defaultCacheManager,
      maxHeight,
      maxWidth,
      headers,
      imageRenderMethodForWeb,
      () => PaintingBinding.instance.imageCache.evict(key),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is CachedNetworkImageProvider) {
      // 这里的相等性，决定了 Flutter 内存 ImageCache 用什么 key 来区分图片。
      // 因此 cacheKey/url、scale、resize 尺寸都必须参与比较，
      // 否则同一 URL 的不同变体会互相覆盖。
      return ((cacheKey ?? url) == (other.cacheKey ?? other.url)) &&
          scale == other.scale &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(cacheKey ?? url, scale, maxHeight, maxWidth);

  @override
  String toString() => 'CachedNetworkImageProvider("$url", scale: $scale)';
}
