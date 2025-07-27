# 项目名称

## 快速开始

### 1. 克隆项目

> 本项目包含 Git 子模块，克隆后需要初始化并下载子模块。



# 克隆主仓库
git clone https://github.com/hc2088/test-flutter-mix.git
cd test-flutter-mix

# 初始化并拉取子模块
git submodule update --init --recursive




也可以用一条命令直接克隆主仓库和子模块：
git clone --recursive https://github.com/hc2088/test-flutter-mix.git







## 添加子模块
## 子模块管理指南

本项目使用 **Git Submodule** 管理部分依赖代码。子模块是一个独立的 Git 仓库，会以固定提交的方式被嵌入到当前项目中。以下是相关操作说明：

---

### **添加新的子模块**

```bash
# 进入主项目根目录
cd /path/to/your-project

# 添加子模块，指定仓库地址和在本项目中的路径
git submodule add https://github.com/xxx/your-submodule.git path/to/submodule

# 初始化并拉取子模块内容
git submodule update --init --recursive

# 提交 .gitmodules 和子模块路径
git add .gitmodules path/to/submodule
git commit -m "添加子模块 your-submodule"
git push

