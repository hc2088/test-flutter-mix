#!/bin/bash
set -e

FRAMEWORK_NAME="FFIDynamicFlutter"
SCHEME_NAME="FFIDynamicFlutter"
PROJECT_NAME="FFIDynamicFlutter.xcodeproj"
BUILD_DIR="$(pwd)/build"

DEVICE_ARCHIVE_PATH="$BUILD_DIR/$FRAMEWORK_NAME-iphoneos.xcarchive"
SIMULATOR_ARCHIVE_PATH="$BUILD_DIR/$FRAMEWORK_NAME-simulator.xcarchive"
XCFRAMEWORK_OUTPUT="$BUILD_DIR/$FRAMEWORK_NAME.xcframework"

# 清理旧构建
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> 构建真机（arm64）Framework..."
xcodebuild archive \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "$DEVICE_ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "==> 构建模拟器（arm64 + x86_64）Framework..."
xcodebuild archive \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -sdk iphonesimulator \
  -archivePath "$SIMULATOR_ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "==> 创建 XCFramework..."
xcodebuild -create-xcframework \
  -framework "$DEVICE_ARCHIVE_PATH/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "$SIMULATOR_ARCHIVE_PATH/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -output "$XCFRAMEWORK_OUTPUT"

echo "✅ 构建完成，输出路径："
echo "$XCFRAMEWORK_OUTPUT"

# 可选：检查包含的架构（需安装 `file` 工具）
echo "==> 检查架构 slice："
find "$XCFRAMEWORK_OUTPUT" -name "$FRAMEWORK_NAME" -type f -exec lipo -info {} \; || true
