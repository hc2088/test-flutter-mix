import 'dart:async';
import 'dart:ui' as ui show Codec, FrameInfo;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

/// Slows down animations by this factor to help in development.
double get timeDilation => _timeDilation;
double _timeDilation = 1;

/// An ImageStreamCompleter with support for loading multiple images.
///
/// 大多数 ImageProvider 只会 resolve 出一个 codec future。
/// cached_network_image 刻意使用“流”的形式，是因为后续可能还会有新的 codec
/// 进来，例如同一个 Widget 还活着，但它的 URL 已经被替换了。
class MultiImageStreamCompleter extends ImageStreamCompleter {
  /// The constructor to create an MultiImageStreamCompleter. The [codec]
  /// should be a stream with the images that should be shown. The
  /// [chunkEvents] should indicate the [ImageChunkEvent]s of the first image
  /// to show.
  MultiImageStreamCompleter({
    required Stream<ui.Codec> codec,
    required double scale,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
  })  : _informationCollector = informationCollector,
        _scale = scale {
    // loader 产出的是一个“随时间变化的 codec 流”。
    // 静态图通常只有一个 codec；动图或 URL 切换时则可能出现多个。
    codec.listen(
      (event) {
        if (_timer != null) {
          _nextImageCodec = event;
        } else {
          _handleCodecReady(event);
        }
      },
      onError: (Object error, StackTrace stack) {
        reportError(
          context: ErrorDescription('resolving an image codec'),
          exception: error,
          stack: stack,
          informationCollector: informationCollector,
          silent: true,
        );
      },
    );
    if (chunkEvents != null) {
      _chunkSubscription = chunkEvents.listen(
        reportImageChunkEvent,
        onError: (Object error, StackTrace stack) {
          reportError(
            context: ErrorDescription('loading an image'),
            exception: error,
            stack: stack,
            informationCollector: informationCollector,
            silent: true,
          );
        },
      );
    }
  }

  ui.Codec? _codec;
  ui.Codec? _nextImageCodec;
  final double _scale;
  final InformationCollector? _informationCollector;
  ui.FrameInfo? _nextFrame;

  // When the current was first shown.
  Duration? _shownTimestamp;

  // The requested duration for the current frame;
  Duration? _frameDuration;

  // How many frames have been emitted so far.
  int _framesEmitted = 0;
  Timer? _timer;
  StreamSubscription<ImageChunkEvent>? _chunkSubscription;

  // Used to guard against registering multiple _handleAppFrame callbacks for the same frame.
  bool _frameCallbackScheduled = false;

  /// We must avoid disposing a completer if it never had a listener, even
  /// if all [keepAlive] handles get disposed.
  bool __hadAtLeastOneListener = false;

  bool __disposed = false;

  void _switchToNewCodec() {
    _framesEmitted = 0;
    _timer = null;
    // 新 codec 会替换掉旧的帧来源，但外部监听的仍然是同一个
    // ImageStreamCompleter，这样上层 Widget 不需要重绑监听器。
    _handleCodecReady(_nextImageCodec!);
    _nextImageCodec = null;
  }

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;

    if (hasListeners) {
      _decodeNextFrameAndSchedule();
    }
  }

  void _handleAppFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!hasListeners) return;
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      // 只有当 Flutter 当前帧时钟认为“该显示了”，才真正把帧发出去。
      // 这样动图播放才能跟调度器节奏保持一致。
      _emitFrame(ImageInfo(image: _nextFrame!.image, scale: _scale));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame!.duration;
      _nextFrame = null;
      if (_framesEmitted % _codec!.frameCount == 0 && _nextImageCodec != null) {
        _switchToNewCodec();
      } else {
        final completedCycles = _framesEmitted ~/ _codec!.frameCount;
        if (_codec!.repetitionCount == -1 ||
            completedCycles <= _codec!.repetitionCount) {
          _decodeNextFrameAndSchedule();
        }
      }
      return;
    }
    final delay = _frameDuration! - (timestamp - _shownTimestamp!);
    _timer = Timer(delay * timeDilation, _scheduleAppFrame);
  }

  bool _isFirstFrame() {
    return _frameDuration == null;
  }

  bool _hasFrameDurationPassed(Duration timestamp) {
    return timestamp - _shownTimestamp! >= _frameDuration!;
  }

  Future<void> _decodeNextFrameAndSchedule() async {
    try {
      _nextFrame = await _codec!.getNextFrame();
    } on Object catch (exception, stack) {
      reportError(
        context: ErrorDescription('resolving an image frame'),
        exception: exception,
        stack: stack,
        informationCollector: _informationCollector,
        silent: true,
      );
      return;
    }
    if (_codec!.frameCount == 1) {
      // ImageStreamCompleter listeners removed while waiting for next frame to
      // be decoded.
      // There's no reason to emit the frame without active listeners.
      if (!hasListeners) {
        return;
      }

      // This is not an animated image, just return it and don't schedule more
      // frames.
      _emitFrame(ImageInfo(image: _nextFrame!.image, scale: _scale));
      return;
    }
    _scheduleAppFrame();
  }

  void _scheduleAppFrame() {
    if (_frameCallbackScheduled) {
      return;
    }
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
  }

  @override
  void addListener(ImageStreamListener listener) {
    __hadAtLeastOneListener = true;
    // 直到真的有人监听时才开始后续解码。
    // 这样能避免某些“提前 resolve 但最终没画出来”的无效开销。
    if (!hasListeners && _codec != null) _decodeNextFrameAndSchedule();
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      // 没有监听者时，继续保留动图计时器就没有意义了。
      _timer?.cancel();
      _timer = null;
      __maybeDispose();
    }
  }

  int __keepAliveHandles = 0;

  @override
  ImageStreamCompleterHandle keepAlive() {
    final delegateHandle = super.keepAlive();
    return _MultiImageStreamCompleterHandle(this, delegateHandle);
  }

  void __maybeDispose() {
    if (!__hadAtLeastOneListener ||
        __disposed ||
        hasListeners ||
        __keepAliveHandles != 0) {
      return;
    }

    __disposed = true;

    _chunkSubscription?.onData(null);
    _chunkSubscription?.cancel();
    _chunkSubscription = null;
  }
}

class _MultiImageStreamCompleterHandle implements ImageStreamCompleterHandle {
  _MultiImageStreamCompleterHandle(this._completer, this._delegateHandle) {
    _completer!.__keepAliveHandles += 1;
  }

  MultiImageStreamCompleter? _completer;
  final ImageStreamCompleterHandle _delegateHandle;

  /// Call this method to signal the [ImageStreamCompleter] that it can now be
  /// disposed when its last listener drops.
  ///
  /// This method must only be called once per object.
  @override
  void dispose() {
    assert(_completer != null);
    assert(_completer!.__keepAliveHandles > 0);
    assert(!_completer!.__disposed);

    _delegateHandle.dispose();

    _completer!.__keepAliveHandles -= 1;
    _completer!.__maybeDispose();
    _completer = null;
  }
}
