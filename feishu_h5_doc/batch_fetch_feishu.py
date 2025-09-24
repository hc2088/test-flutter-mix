#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量拉取 Feishu Wiki 文档
用法：
python batch_fetch_feishu.py <USER_ACCESS_TOKEN> doc_token1 doc_token2 ...
或者从文件读取：
python batch_fetch_feishu.py <USER_ACCESS_TOKEN> --file 协议.txt
文件每行可以是：
文档标题
文档 URL
或者只写 doc_token
"""

import subprocess
import sys
import os
import re

def parse_token_from_line(line):
    """
    从 URL 或 token 中提取 doc_token
    """
    line = line.strip()
    if not line:
        return None
    # 如果是 URL，取最后一段路径
    if line.startswith("http"):
        return line.rstrip("/").split("/")[-1]
    # 否则认为是 token
    return line

def run_node(doc_token, user_token):
    print(f"📄 开始处理文档: {doc_token}")
    try:
        subprocess.run(
            ["node", "fetch_feishu_wiki_full.js", doc_token, user_token],
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"❌ 文档 {doc_token} 处理失败: {e}")
    print("-----------------------------------")

def main():
    if len(sys.argv) < 3:
        print("用法: python batch_fetch_feishu.py <USER_ACCESS_TOKEN> doc_token1 doc_token2 ...")
        print("或:    python batch_fetch_feishu.py <USER_ACCESS_TOKEN> --file doc_list.txt")
        sys.exit(1)

    user_token = sys.argv[1]

    doc_tokens = []
    if sys.argv[2] == "--file":
        file_path = sys.argv[3]
        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {file_path}")
            sys.exit(1)
        with open(file_path, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip()]
        # 支持标题 + URL 两行的格式
        i = 0
        while i < len(lines):
            line = lines[i]
            if line.startswith("http"):
                token = parse_token_from_line(line)
                doc_tokens.append(token)
                i += 1
            else:
                # 非 URL 行，检查下一行是否是 URL
                if i + 1 < len(lines) and lines[i + 1].startswith("http"):
                    token = parse_token_from_line(lines[i + 1])
                    doc_tokens.append(token)
                    i += 2
                else:
                    # 单独的 token
                    token = parse_token_from_line(line)
                    doc_tokens.append(token)
                    i += 1
    else:
        doc_tokens = sys.argv[2:]

    print(f"🔑 使用的 user_access_token: {user_token}")
    print(f"📄 待处理文档数量: {len(doc_tokens)}\n")

    for doc in doc_tokens:
        run_node(doc, user_token)

if __name__ == "__main__":
    main()
