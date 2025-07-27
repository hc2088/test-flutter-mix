#!/bin/bash

set -e

# === 配置 ===
REMOTE_URL=$(git remote get-url origin)

echo "🚀 开始修复仓库..."

# 1. 确保 Pods 加入 .gitignore
if ! grep -q "ios_flutter_app/Pods/" .gitignore 2>/dev/null; then
  echo "ios_flutter_app/Pods/" >> .gitignore
  echo "✅ 已将 ios_flutter_app/Pods/ 添加到 .gitignore"
fi

# 2. 移除当前索引中的 Pods
git rm -r --cached ios_flutter_app/Pods || true
git commit -m "Remove Pods directory from repository" || true

# 3. 清理历史记录
echo "🧹 使用 git-filter-repo 清理历史..."
brew install git-filter-repo >/dev/null 2>&1 || true
git filter-repo --path ios_flutter_app/Pods/ --invert-paths --force

# 4. 重新添加远端
git remote add origin "$REMOTE_URL"

# 5. 强制推送
echo "⬆️ 正在强制推送到远端..."
git push origin main --force

echo "🎉 修复完成！"
