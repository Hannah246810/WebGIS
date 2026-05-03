<template>
  <div class="mobile-container">
    <div id="map"></div>

    <div class="header-glass">
      <span>🐾 校园流浪猫地图</span>
    </div>

    <div class="bottom-sheet" :class="{ expanded: isExpanded }">
      <div class="drag-bar" @click="isExpanded = !isExpanded"></div>
      
      <div v-if="!isReporting" class="sheet-content">
        <div class="cat-scroll-box">
          <div v-for="cat in catList" :key="cat.id" class="cat-item" @click="focusCat(cat)">
            <div class="cat-avatar">🐱</div>
            <div class="cat-detail">
              <div class="name">{{ cat.name }} <span class="tag">{{ cat.health_status }}</span></div>
              <div class="loc">📍 {{ cat.location_name || '暂无位置' }}</div>
            </div>
          </div>
        </div>
        <button class="main-fab" @click="startReport">我发现了猫</button>
      </div>

      <div v-else class="sheet-content report-form">
        <div class="form-title">
          <span>📍 标记位置</span>
          <button class="text-btn" @click="isReporting = false">取消</button>
        </div>
        
        <div class="info-tip" v-if="!reportData.latitude">第一步：请在地图上点击猫咪所在位置</div>
        <div class="info-tip success" v-else>✅ 位置已选中</div>

        <div class="type-selector">
  <button 
    :class="{ active: reportData.type === 'encounter' }" 
    @click="reportData.type = 'encounter'"
  >🐾 偶遇</button>
  <button 
    :class="{ active: reportData.type === 'feeding' }" 
    @click="reportData.type = 'feeding'"
  >🍖 投喂</button>
</div>

        <select v-model="reportData.cat_id">
          <option value="" disabled>选择哪只猫？</option>
          <option v-for="cat in catList" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
        </select>
        <input v-model="reportData.location_name" placeholder="在哪里看到的？(如：图书馆后院)" />
        <textarea v-model="reportData.comment" placeholder="它现在的状况如何？"></textarea>
        
        <button class="submit-btn" :disabled="!reportData.latitude" @click="submitReport">立即上报</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.mobile-container { position: relative; width: 100vw; height: 100vh; overflow: hidden; font-family: -apple-system, sans-serif; }
#map { width: 100%; height: 100%; z-index: 1; }

/* 顶部玻璃拟态 */
.header-glass {
  position: absolute; top: 15px; left: 15px; right: 15px; z-index: 10;
  background: rgba(255, 255, 255, 0.8); backdrop-filter: blur(10px);
  padding: 12px; border-radius: 20px; text-align: center; font-weight: bold; box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}

/* 底部抽屉设计 */
.bottom-sheet {
  position: absolute; bottom: 0; left: 0; right: 0; z-index: 20;
  background: white; border-radius: 24px 24px 0 0;
  transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 -5px 20px rgba(0,0,0,0.1);
  max-height: 80vh; padding-bottom: 20px;
}
.expanded { transform: translateY(0); }
/* 默认只露出一小块 */
.bottom-sheet:not(.expanded) { transform: translateY(calc(100% - 100px)); }

.drag-bar { width: 40px; height: 4px; background: #ddd; margin: 12px auto; border-radius: 2px; }

.cat-scroll-box { max-height: 300px; overflow-y: auto; padding: 0 20px; }
.cat-item { display: flex; align-items: center; padding: 15px 0; border-bottom: 1px solid #f5f5f5; }
.cat-avatar { width: 45px; height: 45px; background: #fff4e6; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
.cat-detail { margin-left: 15px; }
.name { font-weight: 600; font-size: 16px; }
.tag { font-size: 11px; background: #e3f2fd; color: #2196f3; padding: 2px 6px; border-radius: 4px; margin-left: 5px; }
.loc { font-size: 13px; color: #888; margin-top: 4px; }

.main-fab { width: calc(100% - 40px); margin: 20px; padding: 15px; background: #ff9800; color: white; border: none; border-radius: 15px; font-size: 16px; font-weight: bold; }

.report-form { padding: 0 20px; display: flex; flex-direction: column; gap: 12px; }
.info-tip { font-size: 14px; color: #ff9800; background: #fffbe6; padding: 10px; border-radius: 8px; }
.info-tip.success { color: #52c41a; background: #f6ffed; }
input, select, textarea { width: 100%; padding: 12px; border: 1px solid #eee; border-radius: 10px; font-size: 15px; box-sizing: border-box; }
.submit-btn { background: #4caf50; color: white; padding: 15px; border: none; border-radius: 15px; font-weight: bold; }
.submit-btn:disabled { background: #ccc; }

.type-selector {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
}
.type-selector button {
  flex: 1;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 10px;
  background: #f9f9f9;
  cursor: pointer;
  transition: 0.3s;
}
.type-selector button.active {
  background: #ff9800;
  color: white;
  border-color: #ff9800;
  font-weight: bold;
}
</style>

<script setup>
import { ref, onMounted } from 'vue';
import L from 'leaflet';
import axios from 'axios';

const catList = ref([]);
const isExpanded = ref(false);
const isReporting = ref(false);
const reportData = ref({ 
  cat_id: '', 
  latitude: null, 
  longitude: null, 
  location_name: '', 
  comment: '',
  type: 'encounter' // 默认选中“偶遇”
});
let map, markerLayer;

const initMap = () => {
  map = L.map('map', { zoomControl: false }).setView([30.548, 114.367], 16);
  L.tileLayer('https://{s}.tile.osm.org/{z}/{x}/{y}.png').addTo(map);
  markerLayer = L.layerGroup().addTo(map);

  map.on('click', (e) => {
    if (isReporting.value) {
      reportData.value.latitude = e.latlng.lat;
      reportData.value.longitude = e.latlng.lng;
    }
  });
};

const fetchData = async () => {
  try {
    const res = await axios.get('http://localhost:3000/api/cats');
    catList.value = res.data.data;
    renderMarkers();
  } catch (err) { alert('后端连接失败，请检查 server.js 是否运行'); }
};

const renderMarkers = () => {
  markerLayer.clearLayers();
  catList.value.forEach(cat => {
    if (cat.latitude) {
      L.marker([cat.latitude, cat.longitude])
        .bindPopup(`<b>${cat.name}</b><br>${cat.location_name}`)
        .addTo(markerLayer);
    }
  });
};

const startReport = () => {
  isReporting.value = true;
  isExpanded.value = true;
};

const submitReport = async () => {
  try {
    await axios.post('http://localhost:3000/api/checkins', reportData.value);
    alert('🎉 上报成功！');
    isReporting.value = false;
    reportData.value = { cat_id: '', latitude: null, longitude: null, location_name: '', comment: '' };
    fetchData();
  } catch (err) { alert('提交失败：' + err.response.data.error); }
};

const focusCat = (cat) => {
  if (cat.latitude) {
    map.flyTo([cat.latitude, cat.longitude], 18);
    isExpanded.value = false;
  } else { alert('该猫咪暂无位置记录'); }
};

onMounted(() => {
  initMap();
  fetchData();
});
</script>