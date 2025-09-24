/**
 * fetch_feishu_wiki_full.js
 * Node.js >=14
 *
 * 用法:
 * node fetch_feishu_wiki_full.js <DOC_TOKEN> <USER_ACCESS_TOKEN>
 */

const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
const showdown = require('showdown');

// 输出根目录
const OUT_DIR = path.resolve(__dirname, 'out');

// 读取命令行参数
const args = process.argv.slice(2);
if (args.length < 2) {
  console.error('❌ 用法: node fetch_feishu_wiki_full.js <DOC_TOKEN> <USER_ACCESS_TOKEN>');
  process.exit(1);
}

const DOC_TOKEN = args[0];
const USER_TOKEN = args[1]; // 直接传 user_access_token

// ----------------- 请求封装 -----------------
async function request(method, url, options = {}) {
  try {
    const res = await axios({ method, url, ...options });
    return res.data;
  } catch (err) {
    console.error('❌ 请求失败:', err.response?.status || err.message);
    console.error('  URL:', url);
    if (options.params) console.error('  params:', options.params);
    if (options.data) console.error('  data:', options.data);
    console.error('  响应内容:', err.response?.data || '无响应内容');
    throw err;
  }
}

// ----------------- 修复特殊字符 -----------------
function fixSpecialChars(content) {
  if (!content) return content;
  return content
    .replace(/\\&amp;/g, '&')
    .replace(/\\-/g, '-')
    .replace(/\\~/g, '~')
    .replace(/\\\(/g, '(')
    .replace(/\\\)/g, ')')
    .replace(/\\\\/g, '\\');
}

// ----------------- 安全文件名 -----------------
function safeFileName(title) {
  return title.replace(/[\/\\?%*:|"<>]/g, '-').slice(0, 50);
}

function safeDirName(title, token) {
  return `${safeFileName(title)}_${token}`;
}

// ----------------- 保存 JSON -----------------
async function saveJson(jsonData, docDir, title) {
  const jsonPath = path.join(docDir, `${safeFileName(title)}.json`);
  await fs.writeFile(jsonPath, JSON.stringify(jsonData, null, 2), 'utf8');
  console.log('✅ 已保存原始 JSON:', jsonPath);
  return jsonPath;
}

// ----------------- 下载图片 -----------------
async function downloadImage(url, docDir) {
  const filename = url.split('/').pop();
  const assetsDir = path.join(docDir, 'assets');
  await fs.mkdir(assetsDir, { recursive: true });
  const filePath = path.join(assetsDir, filename);
  try {
    const resp = await axios.get(url, { responseType: 'arraybuffer' });
    await fs.writeFile(filePath, resp.data);
    console.log('✅ 下载图片:', filename);
    return `assets/${filename}`;
  } catch (e) {
    console.warn('⚠️ 图片下载失败:', url, e.message);
    return url;
  }
}

// ----------------- 处理 Markdown 图片链接 -----------------
async function processImages(markdown, docDir) {
  const imgRegex = /!\[.*?\]\((.*?)\)/g;
  const matches = [...markdown.matchAll(imgRegex)];
  for (const m of matches) {
    const url = m[1];
    if (!url.startsWith('http')) continue;
    const localPath = await downloadImage(url, docDir);
    markdown = markdown.replace(url, localPath);
  }
  return markdown;
}

// ----------------- 保存 Markdown -----------------
async function saveMarkdown(content, docDir, title) {
  const mdPath = path.join(docDir, `${safeFileName(title)}.md`);
  await fs.writeFile(mdPath, content, 'utf8');
  console.log('✅ 已保存 Markdown:', mdPath);
  return mdPath;
}

// ----------------- 保存 HTML -----------------
async function saveHtml(content, docDir, title) {
  const converter = new showdown.Converter({
    tables: true,
    simplifiedAutoLink: true,
    encode: false,
    strikethrough: true
  });

  let htmlContent = converter.makeHtml(content);
  htmlContent = htmlContent.replace(/<em>(.*?)<\/em>/g, '<u>$1</u>');

  const css = `
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, Arial, sans-serif;
    line-height: 1.6;
    padding: 20px;
    max-width: 800px;
    margin: auto;
    background: #fff;
    color: #333;
  }
  h1 { font-size: 2em; margin: 1em 0 0.5em; }
  h2 { font-size: 1.75em; margin: 1em 0 0.5em; }
  h3 { font-size: 1.5em; margin: 1em 0 0.5em; }
  p { margin: 0.5em 0; }
  pre { background: #f6f8fa; padding: 10px; overflow-x: auto; border-radius: 5px; }
  code { background: #f6f8fa; padding: 2px 4px; border-radius: 4px; }
  table { border-collapse: collapse; margin: 1em 0; width: 100%; }
  th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
  ul, ol { margin: 0.5em 0 0.5em 2em; }
  a { color: #0366d6; text-decoration: none; }
  img { max-width: 100%; }
  u { text-decoration: underline; font-style: normal; }
  `;

  const htmlPath = path.join(docDir, `${safeFileName(title)}.html`);
  const html = `<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<title>${title}</title>
<style>${css}</style>
</head>
<body>
${htmlContent}
</body>
</html>`;
  await fs.writeFile(htmlPath, html, 'utf8');
  console.log('✅ 已保存 HTML:', htmlPath);

  // ---------- 新增：统一保存到 OUT_DIR/html ----------
  const htmlOutDir = path.join(OUT_DIR, 'html');
  await fs.mkdir(htmlOutDir, { recursive: true });
  const htmlOutPath = path.join(htmlOutDir, `${safeFileName(title)}.html`);
  await fs.writeFile(htmlOutPath, html, 'utf8');
  console.log('✅ 已保存 HTML 到统一目录:', htmlOutPath);

  return htmlPath;
}

// ----------------- 获取文档 Markdown -----------------
async function getDocMarkdown(docToken, userToken) {
  const url = 'https://open.feishu.cn/open-apis/docs/v1/content';
  const res = await request('get', url, {
    headers: { Authorization: `Bearer ${userToken}` },
    params: { doc_token: docToken, content_type: 'markdown', doc_type: 'docx' }
  });

  const markdownRaw = res?.data?.content || res?.data;
  if (!markdownRaw) throw new Error('文档内容为空');

  const markdown = fixSpecialChars(markdownRaw);

  // 尝试从 Markdown 第一行获取标题
  let docTitle = markdown.split('\n')[0].replace(/^#+\s*/, '').trim();
  if (!docTitle) docTitle = docToken;

  return { markdown, docTitle, jsonData: res };
}

// ----------------- main -----------------
async function main() {
  try {
    console.log('🔑 使用的 user_access_token:', USER_TOKEN);

    const { markdown, docTitle, jsonData } = await getDocMarkdown(DOC_TOKEN, USER_TOKEN);

    const docDir = path.join(OUT_DIR, safeDirName(docTitle, DOC_TOKEN));
    await fs.mkdir(docDir, { recursive: true });

    // 保存 JSON
    await saveJson(jsonData, docDir, docTitle);

    // 处理图片
    const mdWithImages = await processImages(markdown, docDir);

    // 保存 Markdown
    await saveMarkdown(mdWithImages, docDir, docTitle);

    // 保存 HTML
    await saveHtml(mdWithImages, docDir, docTitle);

    console.log('🎉 全部完成');
  } catch (err) {
    console.error('❌ 脚本执行失败:', err.message);
  }
}

main();
