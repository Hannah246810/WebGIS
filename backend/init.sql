-- ============================================================
-- 校园流浪猫管理系统数据库建表脚本 (PostgreSQL 版本)
-- 适配 API_doc.md 接口定义
-- ============================================================

CREATE DATABASE IF NOT EXISTS stray_cat_campus
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE stray_cat_campus;


-- 1. 用户表
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(50)   NOT NULL UNIQUE,
    password_hash VARCHAR(255)  NOT NULL,
    openid        VARCHAR(64)   UNIQUE,
    nickname      VARCHAR(50),
    avatar_url    VARCHAR(500),
    role          VARCHAR(10)   NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
    created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP
);
COMMENT ON TABLE users IS '用户表';
COMMENT ON COLUMN users.username IS '登录用户名';
COMMENT ON COLUMN users.password_hash IS '密码哈希值';
COMMENT ON COLUMN users.openid IS '微信小程序openid（可选）';
COMMENT ON COLUMN users.role IS '用户角色：user 普通用户，admin 管理员';
CREATE INDEX idx_users_role ON users(role);

-- 2. 猫咪档案表
CREATE TABLE cats (
    id            BIGSERIAL PRIMARY KEY,
    name          VARCHAR(50)    NOT NULL,
    gender        VARCHAR(10)    NOT NULL DEFAULT 'unknown' CHECK (gender IN ('male','female','unknown')),
    color         VARCHAR(50),
    health_status VARCHAR(100),
    neutered      SMALLINT      NOT NULL DEFAULT 0 CHECK (neutered IN (0,1)),
    description   TEXT,
    archive_url   VARCHAR(500),
    created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP
);
COMMENT ON TABLE cats IS '猫咪档案表';
COMMENT ON COLUMN cats.name IS '猫咪昵称';
COMMENT ON COLUMN cats.gender IS '性别：male 公，female 母，unknown 未知';
COMMENT ON COLUMN cats.color IS '毛色描述';
COMMENT ON COLUMN cats.health_status IS '健康状态';
COMMENT ON COLUMN cats.neutered IS '是否绝育：0否，1是';
COMMENT ON COLUMN cats.archive_url IS '档案图片/详情链接';
CREATE INDEX idx_cats_name ON cats(name);

-- 3. 性格标签字典表
CREATE TABLE tags (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);
COMMENT ON TABLE tags IS '性格标签字典';
COMMENT ON COLUMN tags.name IS '标签名称，如“亲人”、“社恐”';

-- 4. 猫咪与标签关联表
CREATE TABLE cat_tags (
    cat_id BIGINT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (cat_id, tag_id),
    FOREIGN KEY (cat_id) REFERENCES cats(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
COMMENT ON TABLE cat_tags IS '猫咪-标签关联';

-- 5. 常出没点位表
CREATE TABLE points (
    id            BIGSERIAL PRIMARY KEY,
    cat_id        BIGINT NOT NULL,
    longitude     DECIMAL(10,7) NOT NULL,
    latitude      DECIMAL(10,7) NOT NULL,
    location_name VARCHAR(100),
    description   TEXT,
    is_active     SMALLINT DEFAULT 1 CHECK (is_active IN (0,1)),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cat_id) REFERENCES cats(id) ON DELETE CASCADE
);
COMMENT ON TABLE points IS '猫咪常出没点位';
COMMENT ON COLUMN points.cat_id IS '关联猫咪';
COMMENT ON COLUMN points.location_name IS '地点名称';
COMMENT ON COLUMN points.is_active IS '是否仍为该猫常出没点：1是，0否';
CREATE INDEX idx_points_cat_active ON points(cat_id, is_active);
CREATE INDEX idx_points_location ON points(longitude, latitude);

-- 6. 打卡记录表（偶遇与投喂合并）
CREATE TABLE checkins (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    cat_id      BIGINT,
    type        VARCHAR(10) NOT NULL CHECK (type IN ('encounter','feeding')),
    longitude   DECIMAL(10,7) NOT NULL,
    latitude    DECIMAL(10,7) NOT NULL,
    photo_url   VARCHAR(500),
    comment     TEXT,
    food_type   VARCHAR(50),
    quantity    VARCHAR(50),
    status      VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    reviewer_id BIGINT,
    reviewed_at TIMESTAMP,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)     REFERENCES users(id),
    FOREIGN KEY (cat_id)      REFERENCES cats(id) ON DELETE SET NULL,
    FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE SET NULL
);
COMMENT ON TABLE checkins IS '打卡记录（偶遇/投喂统一存储）';
COMMENT ON COLUMN checkins.type IS '打卡类型：encounter偶遇，feeding投喂';
COMMENT ON COLUMN checkins.comment IS '留言或备注';
COMMENT ON COLUMN checkins.food_type IS '投喂食物种类（仅feeding类型使用）';
COMMENT ON COLUMN checkins.quantity IS '投喂量';
COMMENT ON COLUMN checkins.status IS '审核状态：pending待审，approved通过，rejected拒绝';
COMMENT ON COLUMN checkins.reviewer_id IS '审核管理员ID';
CREATE INDEX idx_checkins_user ON checkins(user_id);
CREATE INDEX idx_checkins_cat ON checkins(cat_id);
CREATE INDEX idx_checkins_type_status ON checkins(type, status);
CREATE INDEX idx_checkins_location ON checkins(longitude, latitude);
CREATE INDEX idx_checkins_created ON checkins(created_at);

-- 7. 故事墙评论表（支持回复）
CREATE TABLE comments (
    id         BIGSERIAL PRIMARY KEY,
    cat_id     BIGINT NOT NULL,
    user_id    BIGINT NOT NULL,
    content    TEXT NOT NULL,
    parent_id  BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cat_id)    REFERENCES cats(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)   REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE
);
COMMENT ON TABLE comments IS '故事墙评论';
COMMENT ON COLUMN comments.parent_id IS '父评论ID，实现嵌套回复';
CREATE INDEX idx_comments_cat_created ON comments(cat_id, created_at);
CREATE INDEX idx_comments_parent ON comments(parent_id);

-- 8. 用户收藏表
CREATE TABLE user_favorites (
    user_id    BIGINT NOT NULL,
    cat_id     BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, cat_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cat_id)  REFERENCES cats(id) ON DELETE CASCADE
);
COMMENT ON TABLE user_favorites IS '用户收藏猫咪';

-- 9. 徽章/图鉴集章定义表
CREATE TABLE badges (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(50) NOT NULL,
    description    VARCHAR(255),
    icon_url       VARCHAR(500),
    condition_desc VARCHAR(255),
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE badges IS '徽章定义表';
COMMENT ON COLUMN badges.name IS '徽章名称';
COMMENT ON COLUMN badges.condition_desc IS '获得条件说明';

-- 10. 用户徽章获得记录表
CREATE TABLE user_badges (
    id        BIGSERIAL PRIMARY KEY,
    user_id   BIGINT NOT NULL,
    badge_id  INT NOT NULL,
    earned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)  REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE,
    UNIQUE (user_id, badge_id)
);
COMMENT ON TABLE user_badges IS '用户徽章记录';

-- 11. 科普知识卡片表
CREATE TABLE knowledge_cards (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    content     TEXT NOT NULL,
    type        VARCHAR(50),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE knowledge_cards IS '科普知识卡片';
COMMENT ON COLUMN knowledge_cards.type IS '分类，如“投喂禁忌”、“科学养猫”';

-- ============================================================
-- 初始化建议：插入系统默认管理员账号
-- INSERT INTO users (username, password_hash, nickname, role)
-- VALUES ('admin', '加密后的密码', '系统管理员', 'admin');
-- ============================================================