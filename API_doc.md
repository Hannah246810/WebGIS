
# 校园流浪猫管理系统 API 接口文档

## 1. 项目概览
[cite_start]本接口文档基于《校园流浪猫需求分析》编写，旨在为前端（小程序/Web）与后端提供统一的通信协议 [cite: 1, 2]。

- **Base URL**: `https://api.campus-cat.edu/v1`
- **数据格式**: `application/json`
- **认证方式**: 在 Header 中携带 `Authorization: Bearer <token>`

---

## 2. 身份认证与权限 (Auth & Roles)

### 2.1 用户登录
- **接口**: `POST /auth/login`
- [cite_start]**功能**: 普通用户及管理员登录 [cite: 3]。
- **请求体**:
| 参数名 | 类型 | 必填 | 描述 |
| :--- | :--- | :--- | :--- |
| username | String | 是 | 用户名 |
| password | String | 是 | 密码 |

- **返回示例**:
```json
{
  "code": 200,
  "data": {
    "token": "eyJhbG...",
    "role": "admin",  // 普通用户: user, 管理员: admin
    "user_info": { "id": 1, "nickname": "张三" }
  }
}
```

---

## [cite_start]3. 猫咪档案模块 (Cat Archive) [cite: 6]

### 3.1 获取猫咪列表
- **接口**: `GET /cats`
- **查询参数**: `gender`, `health_status`, `is_neutered` (可选)。
- **返回**: 猫咪简要信息列表。

### 3.2 获取猫咪详情
- **接口**: `GET /cats/{id}`
- [cite_start]**功能**: 查看猫咪详细信息、性格标签及健康状态 [cite: 6]。
- **返回示例**:
```json
{
  "id": 101,
  "nickname": "大黄",
  "gender": "公",
  "color": "橘黄色",
  "tags": ["亲人", "贪吃"],
  "health_status": "健康",
  "is_neutered": true,
  "archive_url": "https://..."
}
```

### 3.3 新增/更新档案 (仅管理员)
- **接口**: `POST /cats` 或 `PUT /cats/{id}`
- [cite_start]**功能**: 管理员维护档案内容 [cite: 5]。

---

## [cite_start]4. 地图与打卡模块 (GIS & Check-in) [cite: 2, 7]

### 4.1 获取地图点位
- **接口**: `GET /map/points`
- [cite_start]**功能**: 获取校园内猫咪常出没的点位坐标，用于 2D/卫星底图展示 [cite: 2, 7]。

### 4.2 偶遇/投喂一键打卡
- **接口**: `POST /checkins`
- [cite_start]**功能**: 用户调用 GPS 和摄像头上传记录。系统支持 AI 自动识别并关联档案 [cite: 8, 9, 10]。
- **请求体**:
| 参数名 | 类型 | 必填 | 描述 |
| :--- | :--- | :--- | :--- |
| type | String | 是 | `encounter` (偶遇) 或 `feeding` (投喂) |
| latitude | Float | 是 | GPS 纬度 |
| longitude | Float | 是 | GPS 经度 |
| image_url | String | 是 | 现场照片 URL |
| cat_id | Int | 否 | AI 识别或用户手动选择的猫咪 ID |
| comment | String | 否 | [cite_start]用户留言或评论 [cite: 8] |

### 4.3 审核上报记录 (仅管理员)
- **接口**: `PATCH /checkins/{id}/audit`
- [cite_start]**功能**: 管理员审核通过后，地图点位和档案记录才会正式更新 [cite: 5, 8]。

---

## [cite_start]5. 社交互动功能 (Interaction) [cite: 11]

### 5.1 故事墙留言
- **接口**: `POST /cats/{id}/comments`
- [cite_start]**功能**: 师生分享互动轶事 [cite: 11]。

### 5.2 趣味榜单
- **接口**: `GET /ranks`
- [cite_start]**参数**: `type` (`star_cats` 明星猫榜, `active_users` 积极用户榜) [cite: 16]。

---

## [cite_start]6. 进阶分析功能 (Advanced Analysis) [cite: 13]

### 6.1 获取行踪可视化数据
- **接口**: `GET /analysis/trace/{cat_id}`
- [cite_start]**功能**: 返回特定猫咪的“校园巡游轨迹”坐标数组 [cite: 14]。

### 6.2 校园出没热力图
- **接口**: `GET /analysis/heatmap`
- [cite_start]**功能**: 获取全局出没热力数据及高概率投喂点分布 [cite: 14]。

---

## 7. 系统与看板 (System & Dashboard)

### 7.1 数据看板 (仅管理员)
- **接口**: `GET /dashboard/statistics`
- [cite_start]**功能**: 统计校园猫咪总数、点位投喂频次等核心指标 [cite: 18]。

### 7.2 科普引导
- **接口**: `GET /sys/knowledge-cards`
- [cite_start]**功能**: 在打卡界面随机获取科学养猫、投喂禁忌等卡片 [cite: 17]。

---

## 8. 错误码定义 (Error Codes)
- `200`: 成功 (Success)
- `400`: 参数错误 (Invalid Params)
- `401`: 未登录 (Unauthorized)
- `403`: 权限不足 (Forbidden)
- `500`: 服务器错误 (Internal Error)