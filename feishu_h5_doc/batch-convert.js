// 使用方法：
// node batch-convert.js ./source ./dist
// node batch-convert.js ./source ./dist --docx4js

const fs = require("fs");
const path = require("path");
const mammoth = require("mammoth");
const Docx4js = require("docx4js"); // 3.x

// 获取参数
const [,, sourceDirArg, outputDirArg, extraFlag] = process.argv;
if (!sourceDirArg) {
  console.log("用法: node batch-convert.js <sourceDir> [outputDir] [--docx4js]");
  process.exit(1);
}

const sourceDir = path.resolve(sourceDirArg);
const outputDir = outputDirArg ? path.resolve(outputDirArg) : path.join(sourceDir, "output");
const useDocx4js = extraFlag === "--docx4js";

// 确保输出目录存在
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

/**
 * Mammoth 转 HTML
 */
async function convertWithMammoth(inputPath, outputPath, title) {
  const options = { styleMap: ["u => u"] }; // 保留下划线
  try {
    console.log(`📄 Mammoth 开始转换: ${inputPath}`);
    const result = await mammoth.convertToHtml({ path: inputPath }, options);
    const htmlBody = result.value;
    const htmlTemplate = wrapHtml(title, htmlBody);
    fs.writeFileSync(outputPath, htmlTemplate, "utf8");
    console.log(`✅ Mammoth 转换完成: ${inputPath} → ${outputPath}`);
  } catch (err) {
    console.error(`❌ Mammoth 转换失败: ${inputPath}`, err);
  }
}

/**
 * Docx4js 3.x 转 HTML
 */
async function convertWithDocx4js(inputPath, outputPath, title) {
  if (!fs.existsSync(inputPath)) {
    console.error(`❌ 文件不存在: ${inputPath}`);
    return;
  }

  console.log(`📄 Docx4js 开始加载文件: ${inputPath}`);
  try {
    // 3.x 版本直接用 Docx4js(path) 或 Docx4js.load(path)
    const doc = await Docx4js.load(inputPath); 
    const htmlBody = doc.getBodyHtml(); // 获取 HTML 内容

    const htmlTemplate = wrapHtml(title, htmlBody);
    fs.writeFileSync(outputPath, htmlTemplate, "utf8");
    console.log(`✅ Docx4js 转换完成: ${inputPath} → ${outputPath}`);
  } catch (err) {
    console.error(`❌ Docx4js 解析失败: ${inputPath}`, err);
  }
}

/**
 * HTML 模板封装
 */
function wrapHtml(title, body) {
  return `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  :root { --max-width:950px; --padding:16px; --bg:#ffffff; --text:#111827; }
  body { margin:0; padding:0; background:var(--bg); color:var(--text);
    font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",Segoe UI,Roboto,"PingFang SC",Arial,sans-serif;
    line-height:1.6; }
  .container { max-width:var(--max-width); margin:24px auto; padding:var(--padding); }
  h1,h2,h3,h4,h5,h6 { margin:18px 0 8px; }
  p { margin:0 0 12px 0; }
  table { width:100%; border-collapse:collapse; margin:12px 0; }
  th, td { border:1px solid #ddd; padding:8px; }
  img { max-width:100%; height:auto; }
  .table-wrap { overflow:auto; }
  @media (max-width:600px) { :root { --padding: 12px; } }
</style>
</head>
<body>
<div class="container">
${body}
</div>
</body>
</html>`;
}

/**
 * 批量转换
 */
async function batchConvert() {
  const files = fs.readdirSync(sourceDir).filter(f => f.endsWith(".docx"));
  for (const file of files) {
    const inputPath = path.join(sourceDir, file);
    const baseName = path.basename(file, ".docx");
    const outputPath = path.join(outputDir, baseName + ".html");

    if (useDocx4js) {
      await convertWithDocx4js(inputPath, outputPath, baseName);
    } else {
      await convertWithMammoth(inputPath, outputPath, baseName);
    }
  }
}

batchConvert();
