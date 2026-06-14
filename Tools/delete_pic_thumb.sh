#!/bin/bash

# 检查是否传入目录参数
if [ -z "$1" ]; then
    echo "用法: $0 <目标目录>"
    exit 1
fi

TARGET_DIR="$1"

# 确认目录存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目录不存在 -> $TARGET_DIR"
    exit 1
fi

# 递归删除所有以 pic_thumb.jpg 结尾的文件
find "$TARGET_DIR" -type f -name "*pic_thumb.jpg" -exec rm -f {} \;

echo "删除完成: $TARGET_DIR"
