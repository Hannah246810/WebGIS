require('dotenv').config(); 
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
// 访问 http://localhost:3000 时显示的欢迎页
app.get('/', (req, res) => {
  res.send(`
    <div style="font-family: sans-serif; text-align: center; padding-top: 50px;">
      <h1>🐱 校园流浪猫后端服务已就绪</h1>
      <p>状态：<span style="color: green;">运行中</span></p>
      <hr style="width: 300px;">
      <p>尝试访问数据接口：<a href="/api/cats">/api/cats</a></p>
    </div>
  `);
});

// 1. 数据库连接（确保你的 .env 文件里信息是正确的）
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

/**
 * 接口 A: 获取猫咪列表及其【最新】位置信息
 * 用于：首页地图打点和侧边栏列表
 */
app.get('/api/cats', async (req, res) => {
  try {
    const query = `
      SELECT DISTINCT ON (c.id) 
        c.id, c.name, c.gender, c.color, c.health_status, c.description,
        ck.latitude, ck.longitude, ck.location_name, ck.created_at as last_seen
      FROM cats c
      LEFT JOIN checkins ck ON c.id = ck.cat_id
      ORDER BY c.id, ck.created_at DESC;
    `;
    const result = await pool.query(query);
    res.json({ code: 200, data: result.rows });
  } catch (err) {
    console.error('查询出错:', err.message);
    res.status(500).json({ code: 500, error: '数据库查询失败，请检查字段名' });
  }
});

/**
 * 接口 B: 提交打卡信息（我发现了猫）
 * 用于：手机端点击地图提交位置
 */
app.post('/api/checkins', async (req, res) => {
  // 增加接收 type 参数
  const { cat_id, latitude, longitude, location_name, comment, type } = req.body;

  if (!cat_id || !latitude || !longitude) {
    return res.status(400).json({ code: 400, error: '位置信息不完整' });
  }

  try {
    const insertQuery = `
      INSERT INTO checkins (cat_id, latitude, longitude, location_name, comment, type, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'approved')
      RETURNING id;
    `;
    // 将 type (第6个参数) 存入数据库
    const result = await pool.query(insertQuery, [
      cat_id, 
      latitude, 
      longitude, 
      location_name, 
      comment, 
      type || 'encounter' // 如果前端没传，默认是偶遇
    ]);

    res.json({ code: 200, message: '打卡记录已保存！' });
  } catch (err) {
    console.error('提交打卡失败:', err.message);
    res.status(500).json({ code: 500, error: '服务器内部错误' });
  }
});

// 启动后端服务
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`校园流浪猫后端服务已启动: http://localhost:${PORT}`);
});