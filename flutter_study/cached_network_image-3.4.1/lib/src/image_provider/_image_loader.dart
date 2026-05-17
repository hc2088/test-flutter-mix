import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:cached_network_image_platform_interface'
        '/cached_network_image_platform_interface.dart' as platform
    show ImageLoader;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// ImageLoader class to load images on IO platforms.
///
/// 这个类的职责可以概括成三件事：
/// - 向 flutter_cache_manager 要“原图文件”或“缩放后的文件”；
/// - 把下载进度转换成 Flutter Widget 可消费的 ImageChunkEvent；
/// - 把字节解码成 Flutter 可以绘制 / 播放的 codec。
class ImageLoader implements platform.ImageLoader {
  @Deprecated('Use loadImageAsync instead')
  @override
  Stream<ui.Codec> loadBufferAsync(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback decode,
    BaseCacheManager cacheManager,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
    VoidCallback evictImage,
  ) {
    return _load(
      url,
      cacheKey,
      chunkEvents,
      (bytes) async {
        final buffer = await ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      },
      cacheManager,
      maxHeight,
      maxWidth,
      headers,
      imageRenderMethodForWeb,
      evictImage,
    );
  }

  @override
  Stream<ui.Codec> loadImageAsync(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
    BaseCacheManager cacheManager,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
    VoidCallback evictImage,
  ) {
    return _load(
      url,
      cacheKey,
      chunkEvents,
      (bytes) async {
        final buffer = await ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      },
      cacheManager,
      maxHeight,
      maxWidth,
      headers,
      imageRenderMethodForWeb,
      evictImage,
    );
  }

  Stream<ui.Codec> _load(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    Future<ui.Codec> Function(Uint8List) decode,
    BaseCacheManager cacheManager,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
    VoidCallback evictImage,
  ) async* {
    try {
      // “磁盘缓存缩放”只有在 cacheManager 混入了 ImageCacheManager 时才成立。
      // 否则这个包依然可以缓存原图，但无法把缩放后的衍生图持久化到磁盘。
      assert(
        cacheManager is ImageCacheManager ||
            (maxWidth == null && maxHeight == null),
        'To resize the image with a CacheManager the '
        'CacheManager needs to be an ImageCacheManager. maxWidth and '
        'maxHeight will be ignored when a normal CacheManager is used.',
      );

      // `getImageFile` 既能复用已有缩略图，也能在磁盘上创建新的缩略图缓存。
      // 如果 cacheManager 只支持普通文件流，就退化为原始文件流。
      final stream = cacheManager is ImageCacheManager
          ? cacheManager.getImageFile(
              url,
              maxHeight: maxHeight,
              maxWidth: maxWidth,
              withProgress: true,
              headers: headers,
              key: cacheKey,
            )
          : cacheManager.getFileStream(
              url,
              withProgress: true,
              headers: headers,
              key: cacheKey,
            );

      await for (final result in stream) {
        if (result is DownloadProgress) {
          // Flutter 图片进度条关心的是 ImageChunkEvent，
          // 而不是 flutter_cache_manager 自己的 DownloadProgress，
          // 所以在这里做一次转换。
          chunkEvents.add(
            ImageChunkEvent(
              cumulativeBytesLoaded: result.downloaded,
              expectedTotalBytes: result.totalSize,
            ),
          );
        }
        if (result is FileInfo) {
          final file = result.file;
          // 到这里，磁盘 / 网络阶段已经结束了。
          // 后面的主要成本就是“把字节解码成 codec”，这一步直接影响
          // 首帧时间以及内存占用。
          final bytes = await file.readAsBytes();
          final decoded = await decode(bytes);
          yield decoded;
        }
      }
    } on Object catch (error, stackTrace) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        evictImage();
      });
      yield* Stream.error(error, stackTrace);
    } finally {
      await chunkEvents.close();
    }
  }
}
