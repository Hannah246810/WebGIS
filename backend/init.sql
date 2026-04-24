-- ============================================================
-- 校园流浪猫管理系统数据库建表脚本 (与 API_doc.md 匹配)
-- DBMS: MySQL 8.0+
-- 包含主键、外键及常用查询索引设计
-- ============================================================

CREATE DATABASE IF NOT EXISTS campus_cat DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE campus_cat;

-- 1. 用户表 (含用户名密码 + 微信openid)
CREATE TABLE users (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)   NOT NULL UNIQUE COMMENT '登录用户名',
    password_hash VARCHAR(255)  NOT NULL COMMENT '密码哈希值',
    openid        VARCHAR(64)   DEFAULT NULL UNIQUE COMMENT '微信小程序openid（可选）',
    nickname      VARCHAR(50)   DEFAULT NULL,
    avatar_url    VARCHAR(500)  DEFAULT NULL,
    role          ENUM('user','admin') NOT NULL DEFAULT 'user' COMMENT '用户角色',
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME      DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role)
) ENGINE=InnoDB COMMENT='用户表';

-- 2. 猫咪档案表 (新增 archive_url)
CREATE TABLE cats (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50)    NOT NULL COMMENT '猫咪昵称',
    gender        ENUM('male','female','unknown') NOT NULL DEFAULT 'unknown',
    color         VARCHAR(50)    DEFAULT NULL COMMENT '毛色描述',
    health_status VARCHAR(100)   DEFAULT NULL COMMENT '健康状态',
    neutered      TINYINT(1)     NOT NULL DEFAULT 0 COMMENT '是否绝育：0否1是',
    description   TEXT           DEFAULT NULL COMMENT '详细描述',
    archive_url   VARCHAR(500)   DEFAULT NULL COMMENT '档案图片/详情链接',
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME       DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB COMMENT='猫咪档案表';

-- 3. 性格标签字典表
CREATE TABLE tags (
    id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE COMMENT '标签名称，如“亲人”、“社恐”'
) ENGINE=InnoDB COMMENT='性格标签字典';

-- 4. 猫咪与标签关联表
CREATE TABLE cat_tags (
    cat_id BIGINT UNSIGNED NOT NULL,
    tag_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cat_id, tag_id),
    FOREIGN KEY (cat_id) REFERENCES cats(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='猫咪-标签关联';

-- 5. 常出没点位表
CREATE TABLE points (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cat_id        BIGINT UNSIGNED NOT NULL COMMENT '关联猫咪',
    longitude     DECIMAL(10,7) NOT NULL,
    latitude      DECIMAL(10,7) NOT NULL,
    location_name VARCHAR(100)  DEFAULT NULL COMMENT '地点名称',
    description   TEXT          DEFAULT NULL,
    is_active     TINYINT(1)    DEFAULT 1 COMMENT '是否仍为该猫常出没点',
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cat_id) REFERENCES cats(id) ON DELETE CASCADE,
    INDEX idx_cat_active (cat_id, is_active),
    INDEX idx_location (longitude, latitude)
) ENGINE=InnoDB COMMENT='猫咪常出没点位';

-- 6. 打卡记录表（合并偶遇与投喂，与原 API 一致）
CREATE TABLE checkins (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT UNSIGNED NOT NULL,
    cat_id      BIGINT UNSIGNED DEFAULT NULL COMMENT 'AI识别或用户选择的猫咪ID',
    type        ENUM('encounter','feeding') NOT NULL COMMENT '打卡类型：encounter偶遇，feeding投喂',
    longitude   DECIMAL(10,7) NOT NULL,
    latitude    DECIMAL(10,7) NOT NULL,
    photo_url   VARCHAR(500)  DEFAULT NULL COMMENT '现场照片',
    comment     TEXT          DEFAULT NULL COMMENT '留言或备注',
    food_type   VARCHAR(50)   DEFAULT NULL COMMENT '投喂食物种类（仅 feeding 类型使用）',
    quantity    VARCHAR(50)   DEFAULT NULL COMMENT '投喂量',
    status      ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    reviewer_id BIGINT UNSIGNED DEFAULT NULL COMMENT '审核管理员ID',
    reviewed_at DATETIME      DEFAULT NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)     REFERENCES users(id),
    FOREIGN KEY (cat_id)      REFERENCES cats(id) ON DELETE SET NULL,
    FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_cat (cat_id),
    INDEX idx_type_status (type, status),
    INDEX idx_location (longitude, latitude),
    INDEX idx_created (created_at)
) ENGINE=InnoDB COMMENT='打卡记录（偶遇/投喂统一存储）';

-- 7. 故事墙评论表（支持回复）
CREATE TABLE comments (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cat_id     BIGINT UNSIGNED NOT NULL,
    user_id    BIGINT UNSIGNED NOT NULL,
    content    TEXT            NOT NULL,
    parent_id  BIGINT UNSIGNED DEFAULT NULL COMMENT '父评论ID，实现嵌套回复',
    created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cat_id)    REFERENCES cats(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)   REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE,
    INDEX idx_cat_created (cat_id, created_at),
    INDEX idx_parent (parent_id)
) ENGINE=InnoDB COMMENT='故事墙评论';

-- 8. 用户收藏表
CREATE TABLE user_favorites (
    user_id    BIGINT UNSIGNED NOT NULL,
    cat_id     BIGINT UNSIGNED NOT NULL,
    created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, cat_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cat_id)  REFERENCES cats(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='用户收藏猫咪';

-- 9. 徽章/图鉴集章定义表
CREATE TABLE badges (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(50)  NOT NULL COMMENT '徽章名称',
    description    VARCHAR(255) DEFAULT NULL,
    icon_url       VARCHAR(500) DEFAULT NULL,
    condition_desc VARCHAR(255) DEFAULT NULL COMMENT '获得条件说明',
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='徽章定义表';

-- 10. 用户徽章获得记录表
CREATE TABLE user_badges (
    id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id   BIGINT UNSIGNED NOT NULL,
    badge_id  INT UNSIGNED NOT NULL,
    earned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)  REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_user_badge (user_id, badge_id)
) ENGINE=InnoDB COMMENT='用户徽章记录';

-- 11. 科普知识卡片表（对应 GET /sys/knowledge-cards）
CREATE TABLE knowledge_cards (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(100) NOT NULL COMMENT '卡片标题',
    content     TEXT NOT NULL COMMENT '卡片内容',
    type        VARCHAR(50)  DEFAULT NULL COMMENT '分类，如“投喂禁忌”、“科学养猫”',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='科普知识卡片';

-- ============================================================
-- 初始化建议：插入系统默认管理员账号（需配合实际 openid）
-- INSERT INTO users (username, password_hash, nickname, role)
-- VALUES ('admin', '$2a$...', '系统管理员', 'admin');
-- ============================================================