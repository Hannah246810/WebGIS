const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('校园流浪猫地图后端已启动！');
});

app.listen(port, () => {
  console.log(`服务运行在 http://localhost:${port}`);
});