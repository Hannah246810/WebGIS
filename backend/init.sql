-- 1. 彻底删除旧表，防止残留干扰
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS checkins CASCADE;
DROP TABLE IF EXISTS cats CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 2. 创建猫咪主表 (统一字段名)
CREATE TABLE cats (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(10) DEFAULT '未知',
    color VARCHAR(50),
    health_status VARCHAR(100) DEFAULT '健康', -- 修复你提到的报错字段
    description TEXT,
    avatar_url VARCHAR(500)
);

-- 3. 创建打卡记录表 (统一字段名)
CREATE TABLE checkins (
    id SERIAL PRIMARY KEY,
    cat_id INTEGER REFERENCES cats(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location_name VARCHAR(100),
    comment TEXT,
    status VARCHAR(20) DEFAULT 'approved', -- 修复你提到的报错字段
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. 插入基础数据进行测试
INSERT INTO cats (name, gender, color, health_status, description) VALUES 
('大黄', '公', '橘色', '已绝育', '常在食堂门口，爱吃香肠'),
('小黑', '母', '纯黑', '健康', '比较怕人，通常在小树林出现');

INSERT INTO checkins (cat_id, latitude, longitude, location_name, comment) VALUES 
(1, 30.548, 114.367, '学生第一食堂', '它又在等饭了');

-- 给 checkins 表增加类型字段
-- encounter: 偶遇, feeding: 投喂
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS type VARCHAR(20) DEFAULT 'encounter';

-- 顺便完善猫咪档案的字段，增加“性格标签”，这在需求文档里也是重点
ALTER TABLE cats ADD COLUMN IF NOT EXISTS tags VARCHAR(200); -- 存性格，如 "亲人, 社恐"

-- 更新一下测试数据
UPDATE cats SET tags = '亲人, 话痨' WHERE name = '大黄';
UPDATE cats SET tags = '高冷, 躲闪' WHERE name = '小黑';