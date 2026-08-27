package com.example.cinemakiosk.repository;

import com.example.cinemakiosk.domain.ScheduleEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface ScheduleRepository extends JpaRepository<ScheduleEntity, Long> {
    // 스케줄에서 지정영화만 전체 조회하기 위한 메서드
    List<ScheduleEntity> findByMovieEntity_MovieId(Long movieId);

    // 영화에 해당하는 스케줄 조회(현재시간으로부터 이후 스케줄만 조회함, 활성화 여부도 True)
    List<ScheduleEntity> findByMovieEntity_MovieIdAndStartAtAfterAndActivationTrue(Long movieId, LocalDateTime now);

    // 스케줄 오늘 포함 이후 날짜 전체 조회
    List<ScheduleEntity> findAllByEndAtAfter(LocalDateTime now);

    List<ScheduleEntity> findAllByStartAtBetweenAndActivationTrueOrderByStartAt(
            LocalDateTime startAt, LocalDateTime endAt);

    boolean existsByTheaterEntity_NoAndStartAtLessThanAndEndAtGreaterThan(
            Long theaterNo, LocalDateTime endAt, LocalDateTime startAt);
}
