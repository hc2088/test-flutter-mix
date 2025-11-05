import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// 从图片中提取主色调（默认取 Vibrant 或 Dominant）
Future<Color> extractDominantColor(ImageProvider imageProvider) async {
  final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      size: const Size(200, 200),
      maximumColorCount: 8 // 限制提取数量，加快速度
      );

  // 优先返回 Vibrant，其次 Dominant，最后 fallback
  return palette.vibrantColor?.color ??
      palette.dominantColor?.color ??
      const Color(0xFF666666);
}
