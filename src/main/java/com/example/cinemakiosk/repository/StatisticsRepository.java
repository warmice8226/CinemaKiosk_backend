package com.example.cinemakiosk.repository;

import com.example.cinemakiosk.domain.enums.Days;
import com.example.cinemakiosk.vo.StatisticsVO;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@RequiredArgsConstructor
@Repository
public class StatisticsRepository {

    @Qualifier("mariaDBJdbcTemplate")
    private final JdbcTemplate jdbcTemplate;

    // 날짜별 스케줄 통계 집계 조회
    public List<StatisticsVO> selectAggregateByDate(LocalDate targetDate) {
        String sql = """
                SELECT
                    t.schedule_id,
                    UPPER(DAYNAME(t.date)) AS day,
                    SUM(t.cost)            AS revenue,         -- 실제 결제된 금액만 합산
                    SUM(t.seat_cnt)        AS customer_count,  -- 예약당 좌석 수를 모두 합산
                    t.date
                FROM (
                    SELECT
                        rd.schedule_id,
                        p.id,
                        p.cost,
                        DATE(p.create_at) AS date,
                        (SELECT COUNT(*) FROM reservation_seat rs WHERE rs.reservation_id = rd.id) AS seat_cnt
                    FROM payment_details p
                    JOIN reservation_details rd ON p.reservation_id = rd.id
                    WHERE DATE(p.create_at) = ?
                      AND p.status = 'PAY'
                ) t
                GROUP BY t.schedule_id, t.date;
                """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> StatisticsVO.builder()
                        .scheduleId(rs.getLong("schedule_id"))
                        .day(Days.valueOf(rs.getString("day")))
                        .revenue(rs.getLong("revenue"))
                        .customerCount(rs.getLong("customer_count"))
                        .date(rs.getDate("date").toLocalDate())
                        .build(),
                targetDate);
    }



//    // 날짜별 통계 데이터 삭제 (폐기)
//    public boolean deleteStatsByDate(LocalDate targetDate) {
//        String sql = "DELETE FROM statistics WHERE date = ?";
//        int rowsAffected = jdbcTemplate.update(sql, targetDate);
//        return rowsAffected == 1; // 삭제된 행이 1개면 true 반환
//    }


    // 통계 데이터 저장
    public boolean insertStatistics(StatisticsVO statisticsVO) {
        jdbcTemplate.update("DELETE FROM statistics WHERE schedule_id = ? AND date = ?",
                statisticsVO.getScheduleId(), statisticsVO.getDate());

        String sql = """
                INSERT INTO statistics (schedule_id, day, revenue, customer_count, date)
                VALUES (?, ?, ?, ?, ?)
                """;

        int rowsAffected = jdbcTemplate.update(sql,
                statisticsVO.getScheduleId(),
                statisticsVO.getDay().name(),
                statisticsVO.getRevenue(),
                statisticsVO.getCustomerCount(),
                statisticsVO.getDate());

        return rowsAffected == 1;
    }

}
