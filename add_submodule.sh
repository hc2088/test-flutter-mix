#!/bin/bash

# 使用示例：
# ./add_submodule.sh https://github.com/alibaba/flutter_boost.git submodules/flutter_boost

REPO_URL=$1
LOCAL_PATH=$2

if [[ -z "$REPO_URL" || -z "$LOCAL_PATH" ]]; then
  echo "用法: $0 <远程仓库地址> <本地子模块路径>"
  exit 1
fi

echo "添加子模块："
echo "远程仓库：$REPO_URL"
echo "本地路径：$LOCAL_PATH"

# 添加子模块
git submodule add "$REPO_URL" "$LOCAL_PATH"

# 初始化并更新子模块
git submodule update --init --recursive

# 提交更改
git add .gitmodules "$LOCAL_PATH"
git commit -m "添加子模块 $LOCAL_PATH"

echo "完成！请执行 git push 上传变更。"
