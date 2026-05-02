<template>
  <div id="app">
    <div id="map"></div>
    <div class="info-panel">
      <h2>🐱 校园流浪猫地图</h2>
      <p>后端状态：<span :class="statusClass">{{ dbStatus }}</span></p>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import L from 'leaflet';
import axios from 'axios';

const dbStatus = ref('正在检测...');
const statusClass = ref('');

onMounted(async () => {
  // 1. 初始化地图 (设置中心点为学校的大致经纬度，这里以 116, 40 为例)
  const map = L.map('map').setView([40.00, 116.30], 15);

  // 2. 加载底图 (使用 OpenStreetMap 免密钥版)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap'
  }).addTo(map);

  // 3. 去后端拿猫咪数据
  try {
    const res = await axios.get('http://localhost:3000/api/cats');
    dbStatus.value = '已连接';
    statusClass.value = 'success';
    
    // 假设猫咪数据里有点位，这里先在中心点画个演示标记
    L.marker([40.00, 116.30]).addTo(map)
      .bindPopup(`<b>${res.data.data[0].name}</b><br>${res.data.data[0].description}`)
      .openPopup();
  } catch (err) {
    dbStatus.value = '连接失败';
    statusClass.value = 'error';
  }
});
</script>

<style>
/* 必须给地图容器设置高度，否则它会隐身 */
#map {
  height: 100vh;
  width: 100%;
  position: absolute;
  top: 0;
  left: 0;
}

.info-panel {
  position: absolute;
  top: 20px;
  right: 20px;
  z-index: 1000;
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.2);
}

.success { color: green; }
.error { color: red; }
</style>