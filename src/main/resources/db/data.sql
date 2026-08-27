-- JPA가 생성한 movie.rating ENUM을 DB 기준값으로 변경
-- JPA는 ENUM 이름(FIFTEEN 등)으로 생성하므로 실제 서비스 값(15 등)으로 ALTER
ALTER TABLE movie
    MODIFY COLUMN rating ENUM ('ALL', '12', '15', '19') NOT NULL;

-- 초기 데이터
-- 총관리자(admin) 비밀번호 1234
INSERT IGNORE INTO admin (login_id, password, name, admin_phone, level, refresh_token, create_at)
values ('admin', '$2a$10$b0wSz0F5vuSpu5nZFdao1.vMfsXNgS6UTMCIs.g/NNWqaChn.IIju', '관리자', '010-1234-5678', 0, null,
        now());

-- 직원1 비밀번호 비밀번호 1111
INSERT IGNORE INTO admin (login_id, password, name, admin_phone, level, refresh_token, create_at)
VALUES ('staff01', '$2a$10$hOcZ/CS62ll2L6LJuRDKkepyjE4ldp9l3Dwz3LSY7rBI54/MKjZ8m', '직원1', '010-1111-2222', 1, null,
        now());

-- 직원2 비밀번호 2222
INSERT IGNORE INTO admin (login_id, password, name, admin_phone, level, refresh_token, create_at)
VALUES ('staff02', '$2a$10$hJyoakWqW5R2Fn0VB5xC8.ksNIn7P8gi4dsCM3km8cSIckiw9Ocbe', '직원2', '010-3333-4444', 1, null,
        now());

-- 운영 권한 (일반 관리자 부여 가능) - 8개
-- ON DUPLICATE KEY UPDATE: 이미 행이 존재해도 role_desc/group_name이 갱신됨
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_REFUND', '환불 처리', '정책/환불')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_MOVIE_LIST', '영화 목록', '영화 관리')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
-- 영화 등록: 영화 등록 페이지 접근 + 등록 버튼
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_MOVIE_REGISTER', '영화 등록', '영화 관리')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
-- 영화 편집: 영화 목록에서 수정 / 삭제 버튼
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_MOVIE_EDIT', '영화 편집', '영화 관리')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
-- 상영 관리: 스케줄 등록 / 수정 / 만료 처리
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_MOVIE_DELETE', '상영 관리', '영화 관리')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_THEATER_LIST', '좌석 목록', '상영관/좌석')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_THEATER_EDIT', '상영관 편집', '상영관/좌석')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);

-- 최고 관리자 전용 권한 - 5개
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_POLICY_LIST', '정책 목록', '정책/환불')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_POLICY_EDIT', '정책 편집', '정책/환불')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_STATISTICS', '대시보드', '통계')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_MEMBER_MANAGEMENT', '회원 정보 관리', '회원/계정 관리')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);
INSERT INTO admin_role (role_name, role_desc, group_name)
VALUES ('ROLE_ADMIN_MANAGEMENT', '계정 및 권한', '회원/계정 관리')
ON DUPLICATE KEY UPDATE role_desc  = VALUES(role_desc),
                        group_name = VALUES(group_name);

-- 일반 관리자 권한 자동 주입
-- 직원1 (staff01, admin_id=2) 권한 부여
INSERT IGNORE INTO admin_role_map (admin_id, role_id)
VALUES (2, 1), -- ROLE_REFUND (환불 처리)
       (2, 2), -- ROLE_MOVIE_LIST (영화 목록)
       (2, 6), -- ROLE_THEATER_LIST (좌석 목록)
       (2, 8), -- ROLE_POLICY_LIST (정책 목록)
       (2, 11); -- ROLE_MEMBER_MANAGEMENT (회원 정보 관리)

-- 직원2 (staff02, admin_id=3) 권한 부여
INSERT IGNORE INTO admin_role_map (admin_id, role_id)
VALUES (3, 1), -- ROLE_REFUND (환불 처리)
       (3, 2), -- ROLE_MOVIE_LIST (영화 목록)
       (3, 6), -- ROLE_THEATER_LIST (좌석 목록)
       (3, 8), -- ROLE_POLICY_LIST (정책 목록)
       (3, 11); -- ROLE_MEMBER_MANAGEMENT (회원 정보 관리)

-- 1. 인터스텔라
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '인터스텔라',
       'SF',
       '12',
       169,
       '크리스토퍼 놀란',
       '매슈 매코너히, 앤 해서웨이',
       '우주를 넘어 인류의 미래를 향한 위대한 여정',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/gDN2NWtHbs8ZWEBQM8Dh5OVXdb4.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '인터스텔라');

-- 2. 더 퍼스트 슬램덩크
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '더 퍼스트 슬램덩크',
       '애니메이션',
       'ALL',
       124,
       '이노우에 다케히코',
       '강백호, 서태웅, 채치수',
       '북산고의 전국 최강 팀과의 결전',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/coiJrdXAXuBkSGDvp9bZ7mkuU6E.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '더 퍼스트 슬램덩크');

-- 3. 다크 나이트 라이즈
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '다크 나이트 라이즈',
       '액션',
       '12',
       164,
       '크리스토퍼 놀란',
       '크리스찬 베일, 톰 하디',
       '고담시를 구하기 위한 배트맨의 마지막 사투',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/eq5P71YHwwaacEYKaQ72Wxy6BlT.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '다크 나이트 라이즈');

-- 4. 기생충
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '기생충',
       '드라마',
       '15',
       132,
       '봉준호',
       '송강호, 이선균, 조여정',
       '두 가족의 만남이 만들어낸 예측 불가의 이야기',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/jjHccoFjbqlfr4VGLVLT7yek0Xn.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '기생충');

-- 5. 어벤져스: 인피니티 워
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '어벤져스: 인피니티 워',
       '액션',
       '12',
       149,
       '앤서니 루소, 조 루소',
       '로버트 다우니 주니어, 크리스 에반스',
       '전 우주를 건 어벤져스의 최대 전투',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/kmP6viwzcEkZeoi1LaVcQemcvZh.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '어벤져스: 인피니티 워');

-- 6. 헤어질 결심
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '헤어질 결심',
       '멜로',
       '15',
       138,
       '박찬욱',
       '박해일, 탕웨이',
       '산 위에서 발견된 시신, 그 아내를 향한 형사의 감정',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/rXEJ28XDQsogIGqwVEgwM2oDdpl.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '헤어질 결심');

-- 7. 범죄도시 4
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '범죄도시 4',
       '범죄',
       '15',
       109,
       '허명행',
       '마동석, 김무열',
       '마석도가 또 다시 나쁜 놈들을 쓸어버린다',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/jucHQwnRSma1O9V2bM007e4eSd7.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '범죄도시 4');

-- 8. 신과함께: 죄와 벌
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '신과함께: 죄와 벌',
       '판타지',
       '12',
       139,
       '김용화',
       '하정우, 차태현, 주지훈',
       '사후 세계 49일간의 7번의 재판',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/z54zrEXAKd5u1SCPNOIAKgvGXte.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '신과함께: 죄와 벌');

-- 9. 듄: 파트 2
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '듄: 파트 2',
       'SF',
       '12',
       166,
       '드니 빌뇌브',
       '티모시 샬라메, 젠데이아',
       '폴 아트레이데스의 운명과 아라키스의 전쟁',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/8AsDR2o5AC3V8Jmj6JH6cpta7dz.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '듄: 파트 2');

-- 10. 부산행
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '부산행',
       '호러',
       '15',
       118,
       '연상호',
       '공유, 정유미, 마동석',
       '좀비 바이러스가 창궐한 열차 안에서의 생존기',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/6XvEZVBFFjybvb1yQd1qfOC6F2S.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '부산행');

-- 11. 탑건: 매버릭
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '탑건: 매버릭',
       '액션',
       '12',
       130,
       '조셉 코신스키',
       '톰 크루즈, 마일스 텔러',
       '30년 만에 다시 소환된 전설의 파일럿',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/jeqXUwNilvNqNXqAHsdwm5pEfae.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '탑건: 매버릭');

-- 12. 곡성
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '곡성',
       '미스터리',
       '15',
       156,
       '나홍진',
       '곽도원, 황정민, 천우희',
       '외지인이 나타난 뒤 마을을 덮친 기이한 사건들',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/k9AKtgRErXjz14lFHL2IJVCgwOT.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '곡성');

-- 13. 너의 이름은
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '너의 이름은',
       '애니메이션',
       'ALL',
       106,
       '신카이 마코토',
       '카미키 류노스케, 카미시라이시 모네',
       '서로의 몸이 뒤바뀐 두 소년소녀의 신비로운 이야기',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/2DJCufz3Oa703PbLjNX1pM6MCG2.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '너의 이름은');

-- 14. 한산: 용의 출현
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '한산: 용의 출현',
       '사극',
       '12',
       129,
       '김한민',
       '박해일, 변요한',
       '이순신 장군의 한산도 대첩',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/9zPOnQfvWJde1bLR9Y6DF1WUlnJ.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '한산: 용의 출현');

-- 15. 조커
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '조커',
       '스릴러',
       '15',
       122,
       '토드 필립스',
       '호아킨 피닉스, 로버트 드 니로',
       '광기로 물들어가는 한 남자의 비극적 탄생',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/6OnFzi7nU6t4j1rmX9QI8EYDWb4.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '조커');

-- 16. 인셉션
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '인셉션',
       'SF',
       '12',
       148,
       '크리스토퍼 놀란',
       '레오나르도 디카프리오, 조셉 고든-레빗',
       '꿈속에 침투해 생각을 훔치는 자들의 이야기',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/atSxEGstxXRoSKDQFBgqQ5lpGSt.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '인셉션');

-- 17. 매트릭스: 리저렉션
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '매트릭스: 리저렉션',
       'SF',
       '15',
       148,
       '라나 워쇼스키',
       '키아누 리브스, 캐리-앤 모스',
       '다시 소환된 네오, 현실과 가상의 경계에서',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/AvWlbyLk32HdvSrrSTYpjmXHEXC.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '매트릭스: 리저렉션');

-- 18. 올드보이
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '올드보이',
       '스릴러',
       '19',
       120,
       '박찬욱',
       '최민식, 유지태, 강혜정',
       '15년 감금 후 풀려난 남자의 복수와 진실',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/e8xZvpCS2cHIPSc5WojNaSNvJJS.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '올드보이');

-- 19. 라이온 킹
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '라이온 킹',
       '가족',
       'ALL',
       118,
       '존 파브로',
       '도널드 글로버, 비욘세',
       '왕의 자리를 되찾기 위한 심바의 여정',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/9Y048zYw66TWvpUtsiNK0uReiVX.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '라이온 킹');

-- 20. 반지의 제왕: 반지 원정대
INSERT INTO movie (title, genre, rating, runtime, director, actors, description, start_at, end_at, create_at,
                   poster_path)
SELECT '반지의 제왕: 반지 원정대',
       '판타지',
       '12',
       178,
       '피터 잭슨',
       '일라이저 우드, 이언 매켈런',
       '절대반지를 파괴하기 위한 원정대의 출발',
       CURDATE(),
       DATE_ADD(CURDATE(), INTERVAL 90 DAY),
       CURDATE(),
       'https://image.tmdb.org/t/p/w500/r18JdjImbWDRwkbVDIzWoLQqkCo.jpg'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE title = '반지의 제왕: 반지 원정대');

-- 서버 재시작 시에도 초기 영화 20편의 상영 기간을 오늘 기준으로 유지
UPDATE movie
SET start_at = CURDATE(),
    end_at = DATE_ADD(CURDATE(), INTERVAL 90 DAY)
WHERE title IN ('인터스텔라', '더 퍼스트 슬램덩크', '다크 나이트 라이즈', '기생충',
                '어벤져스: 인피니티 워', '헤어질 결심', '범죄도시 4', '신과함께: 죄와 벌',
                '듄: 파트 2', '부산행', '탑건: 매버릭', '곡성', '너의 이름은',
                '한산: 용의 출현', '조커', '인셉션', '매트릭스: 리저렉션',
                '올드보이', '라이온 킹', '반지의 제왕: 반지 원정대');


-- 좌석 정책 (일반, 리클라이너 2개 고정)
INSERT IGNORE INTO seat_policy (policy_id, cost, name)
VALUES (1, 5000, '일반'),
       (2, 10000, '리클라이너');

-- 상영관 (1,2번 일반석 / 3,4번 리클라이너)
INSERT IGNORE INTO theater (no, cleanup_time, policy_id)
VALUES (1, 10, 1),
       (2, 10, 1),
       (3, 15, 2),
       (4, 15, 2);

-- 회원
-- 일반 회원: 01012345678 (포인트 0)
-- 포인트 부자 회원: 01099999999 (포인트 100000 - 전액결제 가능)
INSERT IGNORE INTO member (phone, create_at, point, grade)
VALUES ('01012345678', current_timestamp, 0, 'NORMAL'),
       ('01099999999', current_timestamp, 100000, 'VIP'),
       ('01011111111', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -3 YEAR), 500, 'NORMAL'),
       ('01055550001', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 YEAR), 1000, 'VIP'), -- 강등 대상
       ('01055550002', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 YEAR), 2000, 'VIP'), -- 강등 대상
       ('01055550003', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 YEAR), 500, 'VIP');
-- 강등 제외 (최근 포인트 내역 있음)
-- 강등 제외 (최근 포인트 내역 있음)


-- 할인 정책
INSERT IGNORE INTO discount_policy (id, activation, condition_type, discount_type, discount_value, end_at, policy_name,
                                    start_at)
VALUES (1, 1, 'AGE', 'WON', 2000, DATE_ADD(current_timestamp, INTERVAL 200 DAY), '청소년 할인', current_timestamp),
       (3, 1, 'TIME', 'WON', 1000, DATE_ADD(current_timestamp, INTERVAL 200 DAY), '조조 할인', current_timestamp),
       (4, 1, 'COUPON', 'WON', 5000, DATE_ADD(current_timestamp, INTERVAL 200 DAY), '쿠폰 할인', current_timestamp),
       (5, 1, 'JOB', 'RATIO', 20, DATE_ADD(current_timestamp, INTERVAL 200 DAY), '직업 할인', current_timestamp);

UPDATE discount_policy
SET start_at = CURRENT_TIMESTAMP,
    end_at = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 200 DAY),
    activation = TRUE
WHERE id IN (1, 3, 4, 5);

-- 쿠폰 (policy_id=2 : 쿠폰 할인 5000원)
INSERT IGNORE INTO coupon (coupon_num, policy_id, status)
VALUES ('testCoupon01', 4, TRUE),  -- 사용 가능
       ('testCoupon02', 4, TRUE),
       ('testCoupon03', 4, TRUE),
       ('testCoupon04', 4, TRUE),
       ('testCoupon05', 4, TRUE),
       ('testCoupon06', 4, FALSE), -- 사용 불가 (이미 사용됨)
       ('testCoupon07', 4, FALSE),
       ('usedCoupon01', 4, FALSE),
       ('usedCoupon02', 4, FALSE);

-- 적립 정책
-- 고정 정책은 재시작할 때 기간이 만료되지 않도록 아래 UPDATE에서 갱신
INSERT IGNORE INTO bonus_policy (id, activation, end_at, give_value, policy_name, start_at)
VALUES (1, 1, DATE_ADD(current_timestamp, INTERVAL 100 DAY), 5, 'NORMAL', current_timestamp),
       (2, 1, DATE_ADD(current_timestamp, INTERVAL 100 DAY), 10, 'VIP', current_timestamp);

UPDATE bonus_policy
SET start_at = CURRENT_TIMESTAMP,
    end_at = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 100 DAY),
    activation = TRUE
WHERE id IN (1, 2);

-- 스케줄 (영화 1~4번 각 상영관에 3타임씩)
INSERT IGNORE INTO schedule (id, end_at, start_at, movie_id, no, activation)
VALUES
-- 상영관 1 (일반석) - 영화1
(1, DATE_ADD(current_timestamp, INTERVAL 210 MINUTE), DATE_ADD(current_timestamp, INTERVAL 10 MINUTE), 1, 1, TRUE),
(2, DATE_ADD(current_timestamp, INTERVAL 440 MINUTE), DATE_ADD(current_timestamp, INTERVAL 240 MINUTE), 1, 1, TRUE),
(3, DATE_ADD(current_timestamp, INTERVAL 670 MINUTE), DATE_ADD(current_timestamp, INTERVAL 470 MINUTE), 1, 1, TRUE),
-- 상영관 2 (일반석) - 영화2
(4, DATE_ADD(current_timestamp, INTERVAL 210 MINUTE), DATE_ADD(current_timestamp, INTERVAL 10 MINUTE), 2, 2, TRUE),
(5, DATE_ADD(current_timestamp, INTERVAL 440 MINUTE), DATE_ADD(current_timestamp, INTERVAL 240 MINUTE), 2, 2, TRUE),
(6, DATE_ADD(current_timestamp, INTERVAL 670 MINUTE), DATE_ADD(current_timestamp, INTERVAL 470 MINUTE), 2, 2, TRUE),
-- 상영관 3 (리클라이너) - 영화3
(7, DATE_ADD(current_timestamp, INTERVAL 210 MINUTE), DATE_ADD(current_timestamp, INTERVAL 10 MINUTE), 3, 3, TRUE),
(8, DATE_ADD(current_timestamp, INTERVAL 440 MINUTE), DATE_ADD(current_timestamp, INTERVAL 240 MINUTE), 3, 3, TRUE),
(9, DATE_ADD(current_timestamp, INTERVAL 670 MINUTE), DATE_ADD(current_timestamp, INTERVAL 470 MINUTE), 3, 3, TRUE),
-- 상영관 4 (리클라이너) - 영화4
(10, DATE_ADD(current_timestamp, INTERVAL 210 MINUTE), DATE_ADD(current_timestamp, INTERVAL 10 MINUTE), 4, 4, TRUE),
(11, DATE_ADD(current_timestamp, INTERVAL 440 MINUTE), DATE_ADD(current_timestamp, INTERVAL 240 MINUTE), 4, 4, TRUE),
(12, DATE_ADD(current_timestamp, INTERVAL 670 MINUTE), DATE_ADD(current_timestamp, INTERVAL 470 MINUTE), 4, 4, TRUE),
-- 추가 스케줄 (영화 5~8)
(13, DATE_ADD(current_timestamp, INTERVAL 1000 MINUTE), DATE_ADD(current_timestamp, INTERVAL 800 MINUTE), 5, 1, TRUE),
(14, DATE_ADD(current_timestamp, INTERVAL 1240 MINUTE), DATE_ADD(current_timestamp, INTERVAL 1040 MINUTE), 5, 2, TRUE),
(15, DATE_ADD(current_timestamp, INTERVAL 1000 MINUTE), DATE_ADD(current_timestamp, INTERVAL 800 MINUTE), 6, 3, TRUE),
(16, DATE_ADD(current_timestamp, INTERVAL 1240 MINUTE), DATE_ADD(current_timestamp, INTERVAL 1040 MINUTE), 6, 4, TRUE),
(17, DATE_ADD(current_timestamp, INTERVAL 1000 MINUTE), DATE_ADD(current_timestamp, INTERVAL 800 MINUTE), 7, 1, TRUE),
(18, DATE_ADD(current_timestamp, INTERVAL 1240 MINUTE), DATE_ADD(current_timestamp, INTERVAL 1040 MINUTE), 8, 3, TRUE),
-- 뱃치 통계 집계를 위한 스케줄
(19, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1410 MINUTE), DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1580 MINUTE), 1, 1, FALSE),
(20, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1410 MINUTE), DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1580 MINUTE), 2, 2, FALSE),
(21, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1410 MINUTE), DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1580 MINUTE), 3, 3, FALSE),
(22, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1410 MINUTE), DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1580 MINUTE), 4, 4, FALSE);

-- 예매 내역
INSERT IGNORE INTO reservation_details (id, phone, schedule_id, returned, create_at)
VALUES ('kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', '01011111111', 1, FALSE,
        DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -3 YEAR)),                                      -- 케이스1
       ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '01012345678', 1, FALSE, CURRENT_TIMESTAMP), -- 케이스1
       ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '01012345678', 2, FALSE, CURRENT_TIMESTAMP), -- 케이스2
       ('cccccccc-cccc-cccc-cccc-cccccccccccc', '01012345678', 3, FALSE, CURRENT_TIMESTAMP), -- 케이스3
       ('dddddddd-dddd-dddd-dddd-dddddddddddd', '01012345678', 4, FALSE, CURRENT_TIMESTAMP), -- 케이스4
       ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '01012345678', 5, FALSE, CURRENT_TIMESTAMP), -- 케이스5
       ('ffffffff-ffff-ffff-ffff-ffffffffffff', '01012345678', 6, TRUE, CURRENT_TIMESTAMP),  -- 케이스6
       ('gggggggg-gggg-gggg-gggg-gggggggggggg', '01099999999', 7, FALSE, CURRENT_TIMESTAMP), -- 케이스7
       ('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', '01099999999', 8, FALSE, CURRENT_TIMESTAMP), -- 케이스8
       ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', NULL, 9, FALSE, CURRENT_TIMESTAMP),          -- 케이스9
       ('jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', NULL, 10, FALSE, CURRENT_TIMESTAMP),
       -- 강등 되지 않는 회원 예매 내역
       ('aabb0001-0000-0000-0000-000000000001', '01055550001', 1, FALSE,
        DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 MONTH)),
       ('aabb0002-0000-0000-0000-000000000002', '01055550002', 1, FALSE,
        DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 MONTH)),
       ('aabb0003-0000-0000-0000-000000000003', '01055550003', 1, FALSE, CURRENT_TIMESTAMP),
       -- 뱃치 통계 집계를 위한 스케줄
       ('stat0001-0000-0000-0000-000000000001', '01012345678', 19, FALSE, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY)),
       ('stat0002-0000-0000-0000-000000000002', '01012345678', 19, FALSE, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY)),
       ('stat0003-0000-0000-0000-000000000003', '01099999999', 20, FALSE, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY)),
       ('stat0004-0000-0000-0000-000000000004', '01099999999', 21, FALSE, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY)),
       ('stat0005-0000-0000-0000-000000000005', NULL, 22, FALSE, DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY));

-- 케이스10

-- 예매 좌석
INSERT IGNORE INTO reservation_seat (id, seat_number, reservation_id)
VALUES (1, 'A1', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
       (2, 'A2', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
       (34, 'A1', 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk'),
       (3, 'A1', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
       (4, 'A2', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
       (5, 'A1', 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
       (6, 'A2', 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
       (7, 'A1', 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
       (8, 'A2', 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
       (9, 'A3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'),
       (10, 'A4', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'),
       (11, 'A3', 'ffffffff-ffff-ffff-ffff-ffffffffffff'),
       (12, 'A4', 'ffffffff-ffff-ffff-ffff-ffffffffffff'),
       (13, 'B1', 'gggggggg-gggg-gggg-gggg-gggggggggggg'),
       (14, 'B2', 'gggggggg-gggg-gggg-gggg-gggggggggggg'),
       (15, 'B1', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh'),
       (16, 'B2', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh'),
       (17, 'A1', 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii'),
       (18, 'A2', 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii'),
       (19, 'A3', 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj'),
       (20, 'A4', 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj'),
       -- 뱃치 통계 집계를 위한 스케줄
       (21, 'C1', 'stat0001-0000-0000-0000-000000000001'),
       (22, 'C2', 'stat0001-0000-0000-0000-000000000001'),
       (23, 'C3', 'stat0002-0000-0000-0000-000000000002'),
       (24, 'C4', 'stat0003-0000-0000-0000-000000000003'),
       (25, 'C5', 'stat0003-0000-0000-0000-000000000003'),
       (26, 'C6', 'stat0004-0000-0000-0000-000000000004'),
       (27, 'C7', 'stat0005-0000-0000-0000-000000000005'),
       -- 강등 되지 않는 회원 예매 내역
       (28, 'A1', 'aabb0001-0000-0000-0000-000000000001'),
       (29, 'A2', 'aabb0001-0000-0000-0000-000000000001'),
       (30, 'A1', 'aabb0002-0000-0000-0000-000000000002'),
       (31, 'A2', 'aabb0002-0000-0000-0000-000000000002'),
       (32, 'A1', 'aabb0003-0000-0000-0000-000000000003'),
       (33, 'A2', 'aabb0003-0000-0000-0000-000000000003');

-- 결제 내역 (payment_details.id = reservation_details.id 로 1:1 매핑)
INSERT IGNORE INTO payment_details (id, cost, status, create_at, use_point, bonus_policy_id, coupon_num, reservation_id,
                                    payment_key)
VALUES
-- 케이스1: 일반 결제
('kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', 10000, 'PAY', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -3 YEAR), 0, 1, NULL,
 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', 'card'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 10000, 'PAY', CURRENT_TIMESTAMP, 0, 1, NULL,
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'card_key_001'),
-- 케이스2: 쿠폰(5000) + 포인트(5000) 전액
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 0, 'PAY', CURRENT_TIMESTAMP, 5000, 1, 'testCoupon06',
 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'card_key_002'),
-- 케이스3: 포인트 일부(3000) 사용
('cccccccc-cccc-cccc-cccc-cccccccccccc', 7000, 'PAY', CURRENT_TIMESTAMP, 3000, 1, NULL,
 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'card_key_003'),
-- 케이스4: 쿠폰(5000) + 포인트(2000) 일부
('dddddddd-dddd-dddd-dddd-dddddddddddd', 3000, 'PAY', CURRENT_TIMESTAMP, 2000, 1, 'testCoupon07',
 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'card_key_004'),
-- 케이스5: 환불 예정
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 10000, 'PAY', CURRENT_TIMESTAMP, 0, 1, NULL,
 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'card_key_005'),
-- 케이스6: 이미 환불 완료
('ffffffff-ffff-ffff-ffff-ffffffffffff', 10000, 'RETURN', CURRENT_TIMESTAMP, 0, 1, NULL,
 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'card_key_006'),
-- 케이스7: 전액 포인트
('gggggggg-gggg-gggg-gggg-gggggggggggg', 0, 'PAY', CURRENT_TIMESTAMP, 20000, 1, NULL,
 'gggggggg-gggg-gggg-gggg-gggggggggggg', 'card_key_007'),
-- 케이스8: 포인트 부자 일반 결제
('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 20000, 'PAY', CURRENT_TIMESTAMP, 0, 2, NULL,
 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'card_key_008'),
-- 케이스9: 비회원 일반 결제
('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 10000, 'PAY', CURRENT_TIMESTAMP, 0, 1, NULL,
 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'card_key_009'),
-- 케이스10: 비회원 환불 완료
('jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 10000, 'RETURN', CURRENT_TIMESTAMP, 0, 1, NULL,
 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 'card_key_010'),
-- 강등 되지 않는 회원 예매 내역
('aabb0001-0000-0000-0000-000000000001', 10000, 'PAY', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 MONTH), 0, 2, NULL,
 'aabb0001-0000-0000-0000-000000000001', 'batch_key_001'),
('aabb0002-0000-0000-0000-000000000002', 10000, 'PAY', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 MONTH), 0, 2, NULL,
 'aabb0002-0000-0000-0000-000000000002', 'batch_key_002'),
('aabb0003-0000-0000-0000-000000000003', 10000, 'PAY', CURRENT_TIMESTAMP, 0, 2, NULL,
 'aabb0003-0000-0000-0000-000000000003', 'batch_key_003'),
-- 뱃치 통계 집계를 위한 스케줄
('stat0001-0000-0000-0000-000000000001', 10000, 'PAY', DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY), 0, 1, NULL,
 'stat0001-0000-0000-0000-000000000001', 'stat_key_001'),
('stat0002-0000-0000-0000-000000000002', 10000, 'PAY', DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY), 0, 1, NULL,
 'stat0002-0000-0000-0000-000000000002', 'stat_key_002'),
('stat0003-0000-0000-0000-000000000003', 15000, 'PAY', DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY), 5000, 2, NULL,
 'stat0003-0000-0000-0000-000000000003', 'stat_key_003'),
('stat0004-0000-0000-0000-000000000004', 10000, 'PAY', DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY), 0, 1, NULL,
 'stat0004-0000-0000-0000-000000000004', 'stat_key_004'),
('stat0005-0000-0000-0000-000000000005', 10000, 'PAY', DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY), 0, 1, NULL,
 'stat0005-0000-0000-0000-000000000005', 'stat_key_005');


-- 포인트 내역
INSERT IGNORE INTO point_history (point_id, amount_point, create_at, type, phone, payment_id)
VALUES
-- 케이스1: 일반결제 적립 (10000 * 5% = 500p)
(1, 500, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -3 YEAR), 'EARN', '01011111111', 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk'),
(2, 500, CURRENT_TIMESTAMP, 'EARN', '01012345678', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
-- 케이스2: 쿠폰+포인트 전액결제 - 포인트 사용 5000
(3, 5000, CURRENT_TIMESTAMP, 'USE', '01012345678', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
-- 케이스3: 포인트 일부사용 3000
(4, 3000, CURRENT_TIMESTAMP, 'USE', '01012345678', 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
-- 케이스3: 실결제 7000 * 5% = 350p 적립
(5, 350, CURRENT_TIMESTAMP, 'EARN', '01012345678', 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
-- 케이스4: 포인트 일부사용 2000
(6, 2000, CURRENT_TIMESTAMP, 'USE', '01012345678', 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
-- 케이스4: 실결제 3000 * 5% = 150p 적립
(7, 150, CURRENT_TIMESTAMP, 'EARN', '01012345678', 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
-- 케이스5: 환불 예정 결제 적립 (10000 * 5% = 500p)
(8, 500, CURRENT_TIMESTAMP, 'EARN', '01012345678', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'),
-- 케이스6: 환불완료 - 적립 취소
(9, 500, CURRENT_TIMESTAMP, 'REFUND_EARN', '01012345678', 'ffffffff-ffff-ffff-ffff-ffffffffffff'),
-- 케이스7: 전액포인트 결제 - 사용 20000
(10, 20000, CURRENT_TIMESTAMP, 'USE', '01099999999', 'gggggggg-gggg-gggg-gggg-gggggggggggg'),
-- 케이스8: VIP 일반결제 적립 (20000 * 10% = 2000p)
(11, 2000, CURRENT_TIMESTAMP, 'EARN', '01099999999', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh'),
-- 강등 되지 않는 회원 예매 내역
(12, 500, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 MONTH), 'EARN', '01055550001',
 'aabb0001-0000-0000-0000-000000000001'),
(13, 500, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -2 MONTH), 'EARN', '01055550002',
 'aabb0002-0000-0000-0000-000000000002'),
(14, 500, CURRENT_TIMESTAMP, 'EARN', '01055550003', 'aabb0003-0000-0000-0000-000000000003');