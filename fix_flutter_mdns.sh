#!/bin/bash

echo "=== [1/6] 检查 macOS 防火墙状态 ==="
FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
echo "防火墙状态: $FIREWALL_STATUS"

echo "=== [2/6] 允许 mDNSResponder 通过防火墙 ==="
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/mDNSResponder
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/sbin/mDNSResponder

echo "=== [3/6] 重启 mDNSResponder 服务 ==="
sudo killall -HUP mDNSResponder

echo "=== [4/6] 检查 mDNSResponder 是否运行中 ==="
if pgrep mDNSResponder >/dev/null; then
    echo "mDNSResponder 正在运行。"
else
    echo "警告: mDNSResponder 没有运行，请手动检查！"
fi

echo "=== [5/6] 检查 Flutter 本地网络权限（iPhone） ==="
echo "请确保在 iPhone 设置 > 隐私与安全性 > 本地网络中，已允许 Xcode/Flutter Debugging。"

echo "=== [6/6] 修复完成 ==="
echo "现在可以重新运行 Flutter 项目：flutter run"
