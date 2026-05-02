require('dotenv').config(); // 必须在第一行
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const port = 3000;

// 1. 中间件
app.use(cors());
app.use(express.json());

// 2. 数据库连接配置
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// 3. 路由定义

// 解决你的 "Cannot GET /" 问题：访问首页时显示的提示
app.get('/', (req, res) => {
  res.send('<h1>校园流浪猫后端已启动</h1><p>请访问 <a href="/api/cats">/api/cats</a> 查看数据</p>');
});

// 测试数据库连接的接口
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ success: true, message: '数据库连接成功！', time: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 获取猫咪列表接口 (对应你的 cats 表)
app.get('/api/cats', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, gender, color, description FROM cats');
    res.json({
      code: 200,
      data: result.rows
    });
  } catch (err) {
    console.error('查询出错:', err.message);
    res.status(500).json({ code: 500, error: '查询猫咪列表失败' });
  }
});

// 4. 启动服务
app.listen(port, () => {
  console.log(`✅ 服务运行成功!`);
  console.log(`🏠 首页地址: http://localhost:${port}`);
  console.log(`🐱 猫咪接口: http://localhost:${port}/api/cats`);
});