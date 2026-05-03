# 🐱 校园流浪猫地图系统 (Campus Cat Map)

本项目是一个为校园流浪猫设计的管理与互动平台。支持查看猫咪电子档案、地图定位出没点、以及用户偶遇/投喂打卡功能。

---

## 🛠 技术栈
* **前端**: Vue 3 + Axios + Leaflet (地图引擎)
* **后端**: Node.js + Express
* **数据库**: PostgreSQL 18+

---



## 🚀 快速启动指南

为了让程序在您的环境中成功运行，请按照以下步骤配置：

### 1. 数据库准备 (PostgreSQL)
1.  打开 **pgAdmin 4** 或使用命令行。
2.  新建一个数据库，命名为：`campus_cat_db`。
3.  在该数据库中执行项目根目录下的 `init.sql` 脚本。
    * 此操作将自动创建 `cats`（档案表）和 `checkins`（记录表）。
    * 脚本中已包含部分测试数据（大黄、小黑等）。

### 2. 后端配置 (Backend)
1.  进入 `backend` 目录。
2.  找到 `.env.example` 文件（如果没有，请手动创建 `.env`）。
3.  **关键步骤**：修改 `.env` 文件中的数据库连接信息：
    ```env
    DB_USER=postgres
    DB_HOST=localhost
    DB_DATABASE=campus_cat_db
    DB_PASSWORD=您的数据库密码  <-- 修改这里
    DB_PORT=5432
    ```
4.  安装依赖并启动：
    ```bash
    npm install
    node server.js
    ```
    *后端默认运行在: http://localhost:3000*

### 3. 前端配置 (Frontend)
1.  进入 `frontend` 目录。
2.  安装依赖并启动：
    ```bash
    npm install
    npm run dev
    ```
3.  在浏览器中打开显示的本地链接（通常是 `http://localhost:5173`）。

---

## 📂 项目结构说明

- `/backend`
  - `server.js`: 基于 Express 的 API 服务器，包含猫咪查询与打卡接口。
  - `.env`: 环境变量配置文件（包含数据库密码）。
  - `init.sql`: 数据库初始化脚本（含表结构和初始数据）。
- `/frontend`
  - `src/App.vue`: 前端主页面，集成 Leaflet 地图与移动端交互面板。
  - `package.json`: 前端依赖管理。
- `API_doc.md`: 详细的后端接口定义文档。

---

## 💡 功能亮点
- **实时定位**：用户在地图上点击即可获取经纬度，精准上报猫咪位置。
- **动态更新**：前端上报位置后，后端同步更新，地图图标实时刷新。
- **分类统计**：支持“偶遇”与“投喂”两种类型的打卡记录。
- **响应式设计**：适配移动端高度的交互面板（Bottom Sheet）。

---

## ✉️ 备注
如果在运行过程中遇到数据库连接失败，请确认 PostgreSQL 服务已开启且 `.env` 中的端口与密码正确。