-- ============================================
-- 项目：校园流浪猫地图系统
-- 数据库：stray_cat_campus
-- 版本：v1.0
-- 说明：包含流浪猫档案、目击记录、投喂记录、
--        领养申请、反馈预警 5 张核心表
-- ============================================

CREATE DATABASE IF NOT EXISTS stray_cat_campus
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE stray_cat_campus;

-- --------------------------------------------
-- 1. 流浪猫主表
-- --------------------------------------------
CREATE TABLE cat (
  cat_id          VARCHAR(32)   NOT NULL COMMENT '猫咪唯一ID（UUID）',
  cat_name        VARCHAR(50)   NOT NULL COMMENT '昵称',
  cat_gender      ENUM('公','母','未知') NOT NULL DEFAULT '未知',
  cat_breed       VARCHAR(30)   DEFAULT NULL COMMENT '品种/花色类型',
  coat_color      VARCHAR(50)   NOT NULL COMMENT '毛色描述',
  appearance      TEXT          DEFAULT NULL COMMENT '外貌特征',
  personality     VARCHAR(100)  DEFAULT NULL COMMENT '性格描述',
  first_seen_date DATE          NOT NULL COMMENT '首次目击日期',
  main_area       VARCHAR(100)  DEFAULT NULL COMMENT '主要活动区域（文字）',
  location        POINT         NOT NULL COMMENT '常驻经纬度（空间点）',
  sterilization_status ENUM('已绝育','未绝育','未知') NOT NULL DEFAULT '未知',
  health_status   VARCHAR(50)   NOT NULL DEFAULT '未知' COMMENT '健康状态',
  health_note     TEXT          DEFAULT NULL COMMENT '健康备注/疫苗记录',
  cat_status      ENUM('在校','已领养','休学','喵星') NOT NULL DEFAULT '在校',
  tnr_record      TEXT          DEFAULT NULL COMMENT 'TNR时间与医院',
  relationship    TEXT          DEFAULT NULL COMMENT '社交关系描述',
  profile_image   VARCHAR(255)  NOT NULL COMMENT '头像URL',
  gallery_images  JSON          DEFAULT NULL COMMENT '相册（JSON数组）',
  adoptable_flag  BOOLEAN       NOT NULL DEFAULT FALSE COMMENT '是否可领养',
  create_time     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (cat_id),
  SPATIAL INDEX idx_location (location),          -- 空间索引，加速周边搜索
  INDEX idx_status_color (cat_status, coat_color), -- 组合索引，优化筛选
  INDEX idx_name (cat_name),
  INDEX idx_health (health_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流浪猫档案主表';

-- --------------------------------------------
-- 2. 目击记录表（含外键）
-- --------------------------------------------
CREATE TABLE sighting (
  sighting_id    VARCHAR(32)  NOT NULL COMMENT '目击记录ID',
  cat_id         VARCHAR(32)  NOT NULL COMMENT '关联猫咪ID',
  user_id        VARCHAR(32)  NOT NULL COMMENT '上报用户ID',
  location       POINT        NOT NULL COMMENT '目击坐标',
  sighting_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  photo_url      VARCHAR(255) DEFAULT NULL COMMENT '目击照片',
  remark         TEXT         DEFAULT NULL COMMENT '备注',
  create_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sighting_id),
  INDEX idx_cat (cat_id),
  INDEX idx_user (user_id),
  INDEX idx_time (sighting_time),
  SPATIAL INDEX idx_sighting_location (location),
  CONSTRAINT fk_sighting_cat FOREIGN KEY (cat_id) REFERENCES cat(cat_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='猫咪目击记录';

-- --------------------------------------------
-- 3. 投喂记录表
-- --------------------------------------------
CREATE TABLE feeding (
  feeding_id     VARCHAR(32)  NOT NULL COMMENT '投喂记录ID',
  spot_id        VARCHAR(32)  NOT NULL COMMENT '投喂点ID',
  user_id        VARCHAR(32)  NOT NULL COMMENT '投喂用户ID',
  food_type      VARCHAR(20)  DEFAULT NULL COMMENT '粮类型',
  amount         VARCHAR(20)  DEFAULT NULL COMMENT '投喂量',
  feeding_time   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status         ENUM('充足','不足','空盘') NOT NULL DEFAULT '充足',
  remark         TEXT         DEFAULT NULL,
  create_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (feeding_id),
  INDEX idx_spot (spot_id),
  INDEX idx_user (user_id),
  INDEX idx_time (feeding_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='投喂记录';

-- --------------------------------------------
-- 4. 领养申请表（含外键）
-- --------------------------------------------
CREATE TABLE adoption (
  application_id   VARCHAR(32)  NOT NULL COMMENT '申请ID',
  cat_id           VARCHAR(32)  NOT NULL COMMENT '猫咪ID',
  applicant_name   VARCHAR(50)  NOT NULL,
  applicant_phone  VARCHAR(20)  NOT NULL,
  applicant_email  VARCHAR(100) DEFAULT NULL,
  message          TEXT         DEFAULT NULL COMMENT '申请留言',
  status           ENUM('待审核','已通过','已拒绝','已完成') NOT NULL DEFAULT '待审核',
  home_visit_note  TEXT         DEFAULT NULL COMMENT '家访记录',
  reviewed_by      VARCHAR(32)  DEFAULT NULL COMMENT '审核管理员ID',
  reviewed_at      DATETIME     DEFAULT NULL,
  create_time      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (application_id),
  INDEX idx_cat (cat_id),
  INDEX idx_status (status),
  CONSTRAINT fk_adoption_cat FOREIGN KEY (cat_id) REFERENCES cat(cat_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='领养申请记录';

-- --------------------------------------------
-- 5. 反馈预警表（含外键）
-- --------------------------------------------
CREATE TABLE feedback (
  feedback_id    VARCHAR(32)  NOT NULL COMMENT '反馈ID',
  cat_id         VARCHAR(32)  DEFAULT NULL COMMENT '关联猫咪ID（可选）',
  user_id        VARCHAR(32)  NOT NULL,
  feedback_type  ENUM('伤人','受虐','伤病','异常聚集','设施损坏','其他') NOT NULL,
  location       POINT        DEFAULT NULL COMMENT '事件发生坐标',
  description    TEXT         NOT NULL,
  image_url      VARCHAR(255) DEFAULT NULL,
  status         ENUM('待处理','处理中','已解决','已关闭') NOT NULL DEFAULT '待处理',
  handler_id     VARCHAR(32)  DEFAULT NULL COMMENT '处理人ID',
  handle_note    TEXT         DEFAULT NULL,
  create_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (feedback_id),
  INDEX idx_cat (cat_id),
  INDEX idx_type (feedback_type),
  INDEX idx_status (status),
  SPATIAL INDEX idx_feedback_location (location),
  CONSTRAINT fk_feedback_cat FOREIGN KEY (cat_id) REFERENCES cat(cat_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='反馈预警记录';