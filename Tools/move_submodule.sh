#!/bin/bash

# 使用示例：
# ./move_submodule.sh fx-wallet-packages submodules/fx-wallet-packages

OLD_PATH=$1
NEW_PATH=$2

if [[ -z "$OLD_PATH" || -z "$NEW_PATH" ]]; then
  echo "用法: $0 <旧子模块路径> <新子模块路径>"
  exit 1
fi

# 1. 进入主项目根目录，确保当前目录正确
echo "当前目录: $(pwd)"

# 2. 获取子模块远程 URL 和当前分支
cd "$OLD_PATH" || { echo "找不到旧子模块目录 $OLD_PATH"; exit 1; }
REMOTE_URL=$(git config --get remote.origin.url)
BRANCH=$(git branch --show-current)
cd - >/dev/null

echo "旧子模块路径: $OLD_PATH"
echo "远程地址: $REMOTE_URL"
echo "分支: $BRANCH"

# 3. 从主项目中删除旧子模块
echo "删除旧子模块 $OLD_PATH"
git submodule deinit -f "$OLD_PATH"
git rm -f "$OLD_PATH"
rm -rf ".git/modules/$OLD_PATH"

# 4. 重新添加子模块到新路径
echo "添加子模块到新路径 $NEW_PATH"
if [ -z "$BRANCH" ]; then
  git submodule add "$REMOTE_URL" "$NEW_PATH"
else
  git submodule add -b "$BRANCH" "$REMOTE_URL" "$NEW_PATH"
fi

# 5. 初始化并更新子模块
git submodule update --init --recursive

# 6. 提交更改
git add .gitmodules "$NEW_PATH"
git commit -m "将子模块 $OLD_PATH 移动到 $NEW_PATH"
echo "完成，请执行 git push 上传变更"
