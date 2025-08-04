#!/bin/bash
set -e

FRAMEWORK_NAME="FFIDynamicFlutter"
PROJECT_NAME="FFIDynamicFlutter.xcodeproj"
SCHEME_NAME="FFIDynamicFlutter"
BUILD_DIR="$(pwd)/build"

# 清理旧构建
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> 构建模拟器版本..."
xcodebuild clean build \
 -project "$PROJECT_NAME" \
 -scheme "$SCHEME_NAME" \
 -configuration Release \
 -sdk iphonesimulator \
 ARCHS="arm64 x86_64" \
 BUILD_DIR="$BUILD_DIR/simulator" \
 BUILD_ROOT="$BUILD_DIR/simulator/build" \
 ONLY_ACTIVE_ARCH=NO \
 SKIP_INSTALL=NO

echo "==> 构建真机版本..."
xcodebuild clean build \
 -project "$PROJECT_NAME" \
 -scheme "$SCHEME_NAME" \
 -configuration Release \
 -sdk iphoneos \
 ARCHS="arm64" \
 BUILD_DIR="$BUILD_DIR/device" \
 BUILD_ROOT="$BUILD_DIR/device/build" \
 ONLY_ACTIVE_ARCH=NO \
 SKIP_INSTALL=NO

# 路径
SIMULATOR_FRAMEWORK="$BUILD_DIR/simulator/Release-iphonesimulator/$FRAMEWORK_NAME.framework"
DEVICE_FRAMEWORK="$BUILD_DIR/device/Release-iphoneos/$FRAMEWORK_NAME.framework"
UNIVERSAL_OUTPUT_DIR="$BUILD_DIR/universal"

echo "==> 创建通用目录 $UNIVERSAL_OUTPUT_DIR"
mkdir -p "$UNIVERSAL_OUTPUT_DIR"

# 复制真机的framework作为基础
cp -R "$DEVICE_FRAMEWORK" "$UNIVERSAL_OUTPUT_DIR"

# 合并二进制文件
echo "==> 合并二进制文件"
lipo -create \
 "$SIMULATOR_FRAMEWORK/$FRAMEWORK_NAME" \
 "$DEVICE_FRAMEWORK/$FRAMEWORK_NAME" \
 -output "$UNIVERSAL_OUTPUT_DIR/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"


#lipo 合并的两个 .framework 文件（一个是模拟器构建，一个是真机构建）都包含了相同的架构 arm64，
#而 lipo 无法将两个相同架构的二进制合并到一个 fat binary 中
#lipo 合并时要求每个架构只能存在一次，否则就会报这个错。
#==> 合并二进制文件
#fatal error: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo: /Users/huchu/Desktop/test-flutter-mix/flutter_study/FFIDynamicFlutter/build/simulator/Release-iphonesimulator/FFIDynamicFlutter.framework/FFIDynamicFlutter and /Users/huchu/Desktop/test-flutter-mix/flutter_study/FFIDynamicFlutter/build/device/Release-iphoneos/FFIDynamicFlutter.framework/FFIDynamicFlutter have the same architectures (arm64) and can't be in the same fat output file




echo "==> 完成！合并的 Framework 在："
echo "$UNIVERSAL_OUTPUT_DIR/$FRAMEWORK_NAME.framework"

# 检查架构
lipo -info "$UNIVERSAL_OUTPUT_DIR/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"


