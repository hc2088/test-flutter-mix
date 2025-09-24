 # # 指定输入目录，输出默认到 <sourceDir>/output
# python batch_convert.py ./source

# # 指定输入和输出目录
# python batch_convert.py ./source ./dist

#!/usr/bin/env python3
import os
import sys
import mammoth

def sanitize_filename(name):
    """去掉文件名中非法字符"""
    return "".join(c for c in name if c.isalnum() or c in (" ", "_", "-")).rstrip()

def convert_docx_to_html(input_path, output_path, title):
    # Mammoth style map 保留加粗、斜体、下划线
    style_map_text = "\n".join([
        "b => b",
        "strong => b",
        "i => i",
        "em => i",
        "u => u"
    ])
    try:
        with open(input_path, "rb") as docx_file:
            result = mammoth.convert_to_html(
                docx_file,
                style_map=style_map_text,
                ignore_numbering=True   # 忽略列表，避免 KeyError: 'w:ilvl'
            )
            html_body = result.value

        html_template = f"""<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
  body {{
    font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",Segoe UI,Roboto,"PingFang SC",Arial,sans-serif;
    line-height:1.6;
    margin:16px;
    color:#111827;
  }}
  .table-wrap {{ overflow:auto; }}
  table {{ border-collapse:collapse; width:100%; margin:12px 0; }}
  th, td {{ border:1px solid #ddd; padding:8px; }}
  img {{ max-width:100%; height:auto; }}
</style>
</head>
<body>
<div class="container">
{html_body}
</div>
</body>
</html>"""

        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(html_template)

        print(f"✅ 转换完成: {input_path} → {output_path}")
    except Exception as e:
        print(f"❌ 转换失败: {input_path} -> {e}")

def batch_convert(source_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    for root, _, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".docx"):
                input_path = os.path.join(root, file)
                base_name = sanitize_filename(os.path.splitext(file)[0])
                rel_path = os.path.relpath(root, source_dir)
                target_dir = os.path.join(output_dir, rel_path)
                os.makedirs(target_dir, exist_ok=True)
                output_path = os.path.join(target_dir, base_name + ".html")
                convert_docx_to_html(input_path, output_path, base_name)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python batch_convert.py <sourceDir> [outputDir]")
        sys.exit(1)

    source_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(source_dir, "output")

    batch_convert(source_dir, output_dir)
