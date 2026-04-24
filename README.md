# WebGIS
# 校园流浪猫地图系统 (Campus Cat Map)

## 📖 项目简介
本项目是一个旨在改善校园流浪猫管理、促进人猫和谐共处的综合服务平台。通过 GIS 地图技术标注猫咪出没点位，结合 AI 识别技术建立精准的猫咪电子档案，并提供打卡、投喂记录及科普引导功能。

## 🛠 技术栈
* [cite_start]**前端**: HTML5, CSS3, JavaScript (Vite 驱动) [cite: 4, 8]
* [cite_start]**后端**: Node.js, Express 框架 [cite: 4, 6]
* [cite_start]**数据库**: PostgreSQL [cite: 3, 4]
* [cite_start]**关键库**: `pg` (PostgreSQL client), `cors`, `dotenv` 

## 🚀 启动步骤

### 1. 数据库配置
1.  确保本地已安装 **PostgreSQL**。
2.  使用命令行或 pgAdmin 创建数据库 `campus_cat_db`。
3.  [cite_start]导入项目根目录下的 `init.sql` 文件以初始化表结构（猫咪档案、打卡记录、评论等）：
    ```bash
    # 使用 psql 导入
    psql -U postgres -d campus_cat_db -f init.sql
    ```
4.  [cite_start]在 `sever.js` 中检查并修改 `Pool` 的连接配置（包括 `user`, `host`, `database`, `password`, `port`）。

### 2. 后端启动
```bash
# 安装依赖
npm install
# 启动 Express 服务器
node sever.js
[cite_start]后端服务将运行在 `http://localhost:3000` [cite: 6]。

### 3. 前端运行
```bash
# 使用 Vite 启动开发服务器
npm run dev
```
[cite_start]访问生成的本地地址即可预览界面 [cite: 4]。

## 📄 接口入口
- [cite_start]**接口文档**: 参考项目根目录下的 `API_doc.md` [cite: 1, 2]。
- **基础访问**: `http://localhost:3000/api`