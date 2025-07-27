#!/bin/bash
set -e

# === 工具函数 ===

function copyPlugins() {
    local source=$1
    local target=$2
    for plugin in "$source"/*; do
        ios_dir="$plugin/ios"
        if [[ -d $ios_dir ]]; then
            plugin_name=$(basename "$plugin")
            mkdir -p "$target/plugins/$plugin_name"
            cp -R "$ios_dir" "$target/plugins/$plugin_name"
        fi
    done
}

function patchGeneratedXcconfig() {
    local file=".ios/Flutter/Generated.xcconfig"
    echo "🔧 正在 patch $file ..."

    if [[ ! -f $file ]]; then
        echo "⚠️ $file 不存在，跳过补丁。"
        return
    fi

    patch_or_add() {
        local key="$1"
        local value="$2"
        if grep -q "^${key} =" "$file"; then
            sed -i '' "s|^${key} =.*|${key} = ${value}|" "$file"
        else
            echo "${key} = ${value}" >> "$file"
        fi
    }

#    patch_or_add "EXCLUDED_ARCHS[sdk=iphonesimulator*]" "arm64"
#    patch_or_add "IPHONEOS_DEPLOYMENT_TARGET" "12.0"
    patch_or_add "ENABLE_BITCODE" "NO"

    echo "✅ 已更新 Generated.xcconfig"
}

# === 参数检查 ===

if [[ $# -lt 1 ]]; then
    echo "❗ 请输入构建模式: 1 (debug), 2 (release), 3 (all)"
    echo "示例: sh buildFlutter.sh 3"
    exit 1
fi

mode=$1
if [[ "$mode" != "1" && "$mode" != "2" && "$mode" != "3" ]]; then
    echo "❌ 无效的 mode：$mode"
    exit 1
fi

# === 环境变量定义 ===

WORKSPACE=$(cd ../../my_flutter && pwd)
cur_dir=$(pwd)
COMPONENT_NAME='TestFlutterModule'
out=$WORKSPACE/.build_ios

echo "📁 WORKSPACE: $WORKSPACE"
echo "📦 COMPONENT: $COMPONENT_NAME"
echo "📂 OUT: $out"
echo "🔧 MODE: $mode"

# === 进入模块目录 ===

cd "$WORKSPACE"

echo "🧹 清理 Flutter 缓存..."
rm -rf .ios
flutter clean
rm -rf pubspec.lock
flutter pub get

# === 修改 xcconfig（构建成功后） ===
patchGeneratedXcconfig


# === 拷贝 Podfile 到 .ios ===
cp -f "$cur_dir/Podfile" .ios/

# === 执行构建 ===

echo "🚀 开始构建 Flutter iOS Framework..."

if [[ $mode -eq 1 ]]; then
    flutter build ios-framework --no-profile --no-release --cocoapods  --no-tree-shake-icons --dart-define=EnableBitcode=false
elif [[ $mode -eq 2 ]]; then
    flutter build ios-framework --no-profile  --no-debug  --cocoapods  --no-tree-shake-icons --dart-define=EnableBitcode=false
else
    flutter build ios-framework --no-profile --cocoapods --no-tree-shake-icons --dart-define=EnableBitcode=false
fi

# === 校验构建产物是否存在 ===
debug_framework="build/ios/framework/Debug/App.xcframework"
release_framework="build/ios/framework/Release/App.xcframework"

if [[ "$mode" == "1" && ! -d "$debug_framework" ]]; then
    echo "❌ Debug 构建失败：未找到 $debug_framework"
    exit 101
elif [[ "$mode" == "2" && ! -d "$release_framework" ]]; then
    echo "❌ Release 构建失败：未找到 $release_framework"
    exit 102
elif [[ "$mode" == "3" && (! -d "$debug_framework" || ! -d "$release_framework") ]]; then
    echo "❌ 构建失败：Debug 或 Release 的 App.xcframework 不完整"
    exit 103
fi



# === 拷贝构建产物 ===

echo "📦 拷贝构建产物到 $out ..."

rm -rf "$out"
mkdir -p "$out/framework/Debug"
mkdir -p "$out/framework/Release"

cp -r .ios/Flutter/FlutterPluginRegistrant "$out"
cp -f .flutter-plugins-dependencies "$out/flutter-plugins-dependencies"

cp -rf build/ios/framework/Debug/Flutter.podspec "$out/framework/Debug"
cp -rf build/ios/framework/Debug/App.xcframework "$out/framework/Debug"

cp -rf build/ios/framework/Release/Flutter.podspec "$out/framework/Release"
cp -rf build/ios/framework/Release/App.xcframework "$out/framework/Release"

cp -f "$cur_dir/TestFlutterModule.podspec" "$out"
cp -f "$cur_dir/podhelper.rb" "$out"

copyPlugins "$WORKSPACE/.ios/.symlinks/plugins" "$out"

echo "✅ ✅ ✅ Flutter iOS Framework 打包完成 ✅ ✅ ✅"
