-- 스키마 생성
CREATE DATABASE IF NOT EXISTS `cinema_kiosk` CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

-- 사용자 생성, 권한 부여
CREATE USER IF NOT EXISTS 'task_master'@'%' IDENTIFIED BY '4444';
GRANT ALL PRIVILEGES ON `cinema_kiosk`.* TO 'task_master'@'%';

-- 권한 다시 로드, 즉시 적용하기 위해 넣음
FLUSH PRIVILEGES;

USE `cinema_kiosk`;


CREATE TABLE IF NOT EXISTS `admin` # FK (X)
(
    `admin_id`    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '관리자 인덱스',
    `login_id`    VARCHAR(30) UNIQUE NOT NULL COMMENT '관리자 아이디',
    `password`    CHAR(60)           NOT NULL COMMENT '관리자 비밀번호',
    `name`        VARCHAR(50)        NOT NULL COMMENT '관리자 이름',
    `admin_phone` VARCHAR(20) UNIQUE NOT NULL COMMENT '전화번호',
    `level`       boolean            NOT NULL COMMENT '관리자 권한 레벨 : 마스터 : 0, 알바 : 1',
    `refresh_token`        VARCHAR(512)           NULL COMMENT '자동 로그인 토큰',
    `create_at`   DATETIME           NOT NULL COMMENT '계정 생성 일자'
) COMMENT '관리자';


CREATE TABLE IF NOT EXISTS `member` # FK (X)
(
    `phone`     VARCHAR(20) PRIMARY KEY COMMENT '회원 번호',
    `grade`     ENUM ('NORMAL', 'VIP') NOT NULL DEFAULT 'NORMAL' COMMENT '회원 등급(포인트 내역 20회 이상 VIP)',
    `point`     INT UNSIGNED         NOT NULL DEFAULT 0 COMMENT '포인트',
    `create_at` DATETIME             NOT NULL COMMENT '생성일'
) COMMENT '회원(포인트)';


CREATE TABLE IF NOT EXISTS `seat_policy` # FK (X)
(
    `policy_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '좌석 아이디',
    `name`      VARCHAR(20)     NULL COMMENT '좌석 이름',
    `cost`      BIGINT UNSIGNED NULL DEFAULT 0 COMMENT '좌석 비용'
) COMMENT '좌석 정책';


CREATE TABLE IF NOT EXISTS `bonus_policy` # FK (X)
(
    `id`          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '적립 정책 인덱스',
    `policy_name` VARCHAR(20)     NOT NULL COMMENT '정책 이름',
    `give_value`  BIGINT UNSIGNED NOT NULL COMMENT '적립 비율',
    `start_at`    DATETIME        NOT NULL COMMENT '시작일',
    `end_at`      DATETIME        NULL COMMENT '만료일',
    `activation`  BOOLEAN         NOT NULL COMMENT '활성화 여부'
) COMMENT '적립 행사 정책(자체 이벤트)';


CREATE TABLE IF NOT EXISTS `movie` # FK (X)
(
    `movie_id`    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '영화 인덱스',
    `title`       VARCHAR(100)                   NOT NULL COMMENT '영화 제목',
    `genre`       VARCHAR(50)                    NOT NULL COMMENT '장르',
    `rating`      ENUM ('ALL', '12', '15', '19') NOT NULL COMMENT '관람 등급',
    `runtime`     BIGINT UNSIGNED                NOT NULL COMMENT '상영 시간(분)',
    `director`    VARCHAR(50)                    NOT NULL COMMENT '감독이름',
    `actors`      VARCHAR(255)                   NULL COMMENT '배우(쉼표로 구분)',
    `description` TEXT                           NULL COMMENT '줄거리',
    `start_at`    DATE                           NOT NULL COMMENT '상영 시작일',
    `end_at`      DATE                           NULL COMMENT '상영 종료일',
    `create_at`   DATE                           NULL COMMENT '영화 등록일',
    `poster_path` VARCHAR(255)                   NULL COMMENT '포스터경로'
) COMMENT '영화';


CREATE TABLE IF NOT EXISTS `discount_policy` # FK (X)
(
    `id`             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '할인 정책 인덱스',
    `policy_name`    VARCHAR(20)                           NOT NULL COMMENT '정책 이름',
    `discount_type`  ENUM ('RATIO', 'WON')                 NOT NULL COMMENT '할인 방식',
    `discount_value` BIGINT UNSIGNED                       NOT NULL COMMENT '할인 값',
    `condition_type` ENUM ('TIME', 'AGE', 'JOB', 'COUPON') NOT NULL COMMENT '할인 유형',
    `start_at`       DATETIME                              NOT NULL COMMENT '시작일',
    `end_at`         DATETIME                              NULL COMMENT '만료일',
    `activation`     BOOLEAN DEFAULT false                 NULL COMMENT '활성화 여부 (활성화 = True, 비활성화 = False)'
) COMMENT '할인 행사 정책(자체 이벤트)';


CREATE TABLE admin_role
(
    id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '권한 인덱스',
    role_name VARCHAR(40) UNIQUE NOT NULL COMMENT 'ROLE_REFUND, ROLE_MOVIE_REG 등 시큐리티 권한 이름',
    role_desc VARCHAR(30) UNIQUE COMMENT '권한 이름',
    group_name VARCHAR(30) NULL COMMENT '프론트 사이드바 섹션 그룹명'
) COMMENT '권한 종류 (12개 고정 데이터)';


CREATE TABLE admin_role_map
(
    id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '인덱스 (결합키 안쓰기 위해 넣음)',
    admin_id BIGINT UNSIGNED NOT NULL COMMENT '관리자 아이디',
    role_id  BIGINT UNSIGNED NOT NULL COMMENT '권한 아이디',
    CONSTRAINT `uq_admin_role_map` UNIQUE (admin_id, role_id), -- 복합 UNIQUE
    CONSTRAINT `fk_admin_role_map_admin` FOREIGN KEY (admin_id) REFERENCES admin (admin_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_admin_role_map_admin_role` FOREIGN KEY (role_id) REFERENCES admin_role (id)
) COMMENT '관리자 계정의 권한 내역 (매핑 테이블)';


CREATE TABLE IF NOT EXISTS `coupon`
(
    `coupon_num` VARCHAR(12) PRIMARY KEY NOT NULL COMMENT '쿠폰 번호',
    `policy_id`  BIGINT UNSIGNED         NOT NULL COMMENT '할인 정책 인덱스 FK',
#     `end_at`     DATETIME    NOT NULL COMMENT '유효기간',
    `status`     BOOLEAN                 NOT NULL DEFAULT FALSE COMMENT '사용여부 (사용가능 = true, 불가능 = false)',
    CONSTRAINT `fk_discount_policy_coupon_id` FOREIGN KEY (`policy_id`) REFERENCES discount_policy (`id`)
) COMMENT '쿠폰 내역';


CREATE TABLE IF NOT EXISTS `theater`
(
    `no`           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '상영관 번호',
    `policy_id`    BIGINT UNSIGNED NOT NULL COMMENT '좌석 정책 FK',
    `cleanup_time` BIGINT UNSIGNED NULL DEFAULT 0 COMMENT '정리시간',
    CONSTRAINT `fk_theater_policy_id` FOREIGN KEY (`policy_id`) REFERENCES seat_policy (`policy_id`)
) COMMENT '상영관';


CREATE TABLE IF NOT EXISTS `schedule`
(
    `id`         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '스케줄 인덱스',
    `no`         BIGINT UNSIGNED      NOT NULL COMMENT '상영관 번호 FK',
    `movie_id`   BIGINT UNSIGNED      NOT NULL COMMENT '영화 번호 FK',
    `start_at`   DATETIME             NULL COMMENT '상영 시작 시간',
    `end_at`     DATETIME             NULL COMMENT '상영 종료 시간',
    `activation` BOOLEAN DEFAULT TRUE NULL COMMENT '스케줄 활성화 여부 (활성화=True, 만료=False)',
    CONSTRAINT `fk_schedule_theater_no` FOREIGN KEY (`no`) REFERENCES theater (`no`),
    CONSTRAINT `fk_schedule_movie_id` FOREIGN KEY (`movie_id`) REFERENCES movie (`movie_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT '상영 스케줄';


CREATE TABLE IF NOT EXISTS statistics
(
    `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '통계 고유 번호',
    `schedule_id`    BIGINT UNSIGNED                                                                     NOT NULL COMMENT '스케쥴 아이디 FK',
    `day`            ENUM ('SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY') NOT NULL COMMENT '요일',
    `revenue`        BIGINT UNSIGNED                                                                     NOT NULL COMMENT '수익',
    `customer_count` BIGINT UNSIGNED                                                                     NOT NULL COMMENT '관람객 수',
    `date`           DATE                                                                                NOT NULL COMMENT '통계 일자',
    CONSTRAINT `fk_statistics_schedule_id` FOREIGN KEY (`schedule_id`) REFERENCES schedule (`id`)
) COMMENT '통계';


CREATE TABLE IF NOT EXISTS `reservation_details`
(
    `id`          CHAR(36) PRIMARY KEY COMMENT '예매 고유번호',
    `schedule_id` BIGINT UNSIGNED                    NOT NULL COMMENT '스케쥴 아이디 FK',
    `phone`       VARCHAR(20)                        NULL COMMENT '회원 번호 FK',
    `returned`    BOOLEAN  DEFAULT FALSE             NOT NULL COMMENT '',
    `create_at`   DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT '예매 기준시',
    CONSTRAINT `fk_reservation_details_schedule_id` FOREIGN KEY (`schedule_id`) REFERENCES schedule (`id`),
    CONSTRAINT `fk_reservation_details_member_phone` FOREIGN KEY (`phone`) REFERENCES member (`phone`)
        ON UPDATE CASCADE
) COMMENT '예매 내역';


CREATE TABLE IF NOT EXISTS `reservation_seat`
(
    `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '고유번호',
    `reservation_id` CHAR(36) NOT NULL COMMENT '예매 내역 FK',
    `seat_number`    VARCHAR(10) NOT NULL COMMENT '좌석 번호',
    CONSTRAINT `fk_reservation_seat_reservation_id` FOREIGN KEY (`reservation_id`) REFERENCES reservation_details (`id`)
) COMMENT '예매 좌석';


CREATE TABLE IF NOT EXISTS `payment_details`
(
    `id`              CHAR(36) PRIMARY KEY COMMENT '결제 고유번호',
    `reservation_id`  CHAR(36)                  NOT NULL COMMENT '예매 내역 FK',
    `bonus_policy_id` BIGINT UNSIGNED              NULL COMMENT '적립 정책 FK',
    `coupon_num`      VARCHAR(12)                  NULL COMMENT '할인 쿠폰 FK',
    `cost`            BIGINT UNSIGNED              NOT NULL COMMENT '결제 금액',
    `create_at`       DATETIME                     NOT NULL COMMENT '결제 시간',
    `payment_key`     VARCHAR(100)                 NOT NULL COMMENT '환불을 위한 키',
    `use_point`       BIGINT UNSIGNED              NULL DEFAULT 0 COMMENT '사용 포인트',
    `status`          ENUM ('PAY','RETURN','FAIL') NOT NULL COMMENT '결제 내용',
    CONSTRAINT `fk_payment_details_reservation_id` FOREIGN KEY (`reservation_id`) REFERENCES reservation_details (`id`),
    CONSTRAINT `fk_payment_details_bonus_policy_id` FOREIGN KEY (`bonus_policy_id`) REFERENCES bonus_policy (`id`),
    CONSTRAINT `fk_payment_details_coupon_num` FOREIGN KEY (`coupon_num`) REFERENCES coupon (coupon_num)
) COMMENT '결제 내역';


CREATE TABLE IF NOT EXISTS `point_history`
(
    `point_id`     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '포인트 인덱스',
    `payment_id`   char(36)                                          NOT NULL COMMENT '결제 고유번호 FK',
    `phone`        VARCHAR(20)                                       NOT NULL COMMENT '회원 번호 FK',
    `type`         ENUM ('EARN', 'USE', 'REFUND_EARN', 'REFUND_USE') NOT NULL COMMENT '적립 / 사용 / 환불-적립 / 환불-사용',
    `amount_point` INT UNSIGNED                                      NOT NULL COMMENT '적립/사용 포인트',
    `create_at`    DATETIME DEFAULT CURRENT_TIMESTAMP                NOT NULL COMMENT '포인트 변경일',
    CONSTRAINT `fk_point_history_payment_id` FOREIGN KEY (`payment_id`) REFERENCES payment_details (`id`),
    CONSTRAINT `fk_point_history_phone` FOREIGN KEY (`phone`) REFERENCES member (`phone`)
        ON UPDATE CASCADE
) COMMENT '포인트 내역';
