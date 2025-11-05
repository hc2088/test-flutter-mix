import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'card_item.dart';

class CardContent extends StatefulWidget {
  final CardItem item;
  final double width;
  final bool isTop;

  const CardContent({
    required this.item,
    required this.width,
    required this.isTop,
  });

  @override
  State<CardContent> createState() => CardContentState();
}

class CardContentState extends State<CardContent>
    with SingleTickerProviderStateMixin {
  bool imageLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final width = widget.width;

    return Stack(
      children: [
        Container(
          width: width,
          height: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4A4A4A),
              width: 0.5,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ✅ 背景渐变层
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF050505), Color(0xFF050505)],
                      ),
                    ),
                  ),
                ),

                // 🌟 ✅ 模糊金色光晕层（仅在图片加载成功后显示）
                if (imageLoaded)
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 80, // 控制模糊强度
                        sigmaY: 80,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0.0, -0.15),
                            radius: 2,
                            colors: [
                              Color(0xCC8C753B), // 中心金色发光（稍微更亮）
                              Color(0x008C753B), // 边缘透明
                            ],
                            stops: [0.0, 0.35],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ✅ 内容层
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 10,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF7A7573),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/hot.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                                const Text('#日常分享',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: const Color(0xFF363636),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Image.asset(
                              'assets/images/ok.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      Text(item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 25),

                      // ✅ 图片加载监听
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            fadeOutDuration: const Duration(milliseconds: 0),
                            fadeInDuration: const Duration(milliseconds: 0),
                            imageBuilder: (context, imageProvider) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    imageLoaded = true;
                                  });
                                }
                              });
                              return Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              );
                            },
                            placeholder: (context, url) => Container(
                              color: Colors.transparent,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ 底部提示文案
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('让你的表达被看见',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
