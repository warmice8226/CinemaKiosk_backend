package com.example.cinemakiosk.batch;

import com.example.cinemakiosk.domain.MovieEntity;
import com.example.cinemakiosk.domain.ScheduleEntity;
import com.example.cinemakiosk.domain.TheaterEntity;
import com.example.cinemakiosk.dto.requestDTO.AdminReservationRequest;
import com.example.cinemakiosk.repository.MovieRepository;
import com.example.cinemakiosk.repository.ScheduleRepository;
import com.example.cinemakiosk.repository.TheaterRepository;
import com.example.cinemakiosk.service.PaymentDetailsService;
import com.example.cinemakiosk.service.ReservationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;

@Log4j2
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.demo-data.enabled", havingValue = "true")
public class DemoDataScheduler {

    private static final ZoneId KOREA_ZONE = ZoneId.of("Asia/Seoul");
    private static final List<LocalTime> SHOW_TIME_CANDIDATES = List.of(
            LocalTime.of(10, 0), LocalTime.of(13, 0), LocalTime.of(16, 0),
            LocalTime.of(19, 0), LocalTime.of(22, 0));
    private static final List<String> SEAT_POOL = createSeatPool();
    private static final int SEAT_CAPACITY = 40;
    private static final double MIN_TARGET_OCCUPANCY = 0.05;
    private static final double MAX_TARGET_OCCUPANCY = 0.70;

    private final MovieRepository movieRepository;
    private final TheaterRepository theaterRepository;
    private final ScheduleRepository scheduleRepository;
    private final ReservationService reservationService;
    private final PaymentDetailsService paymentDetailsService;

    @Value("${app.demo-data.schedule-horizon-days:7}")
    private int scheduleHorizonDays;

    @Value("${app.demo-data.reservations-per-run:4}")
    private int reservationsPerRun;

    @EventListener(ApplicationReadyEvent.class)
    public void initializeDemoData() {
        ensureScheduleHorizon();
        createSimulatedReservations();
    }

    @Scheduled(cron = "0 10 0 * * *", zone = "Asia/Seoul")
    @Transactional
    public void ensureScheduleHorizon() {
        List<MovieEntity> movies = movieRepository.findAll().stream()
                .sorted(Comparator.comparing(MovieEntity::getMovieId))
                .toList();
        List<TheaterEntity> theaters = theaterRepository.findAll().stream()
                .sorted(Comparator.comparing(TheaterEntity::getNo))
                .toList();

        if (movies.isEmpty() || theaters.isEmpty()) {
            log.warn("데모 상영 일정 생성 생략: 영화 또는 상영관 데이터가 없습니다.");
            return;
        }

        LocalDate today = LocalDate.now(KOREA_ZONE);
        LocalDateTime now = LocalDateTime.now(KOREA_ZONE);
        int created = 0;

        for (int dayOffset = 0; dayOffset <= scheduleHorizonDays; dayOffset++) {
            LocalDate date = today.plusDays(dayOffset);
            for (int theaterIndex = 0; theaterIndex < theaters.size(); theaterIndex++) {
                TheaterEntity theater = theaters.get(theaterIndex);
                MovieEntity movie = movies.get((dayOffset + theaterIndex) % movies.size());

                for (LocalTime showTime : selectShowTimes(date, theater.getNo())) {
                    LocalDateTime startAt = date.atTime(showTime);
                    if (!startAt.isAfter(now.plusMinutes(30))) {
                        continue;
                    }
                    LocalDateTime endAt = startAt.plusMinutes(movie.getRuntime())
                            .plusMinutes(theater.getCleanupTime());

                    boolean overlaps = scheduleRepository
                            .existsByTheaterEntity_NoAndStartAtLessThanAndEndAtGreaterThan(
                                    theater.getNo(), endAt, startAt);
                    if (overlaps) {
                        continue;
                    }

                    scheduleRepository.save(ScheduleEntity.builder()
                            .theaterEntity(theater)
                            .movieEntity(movie)
                            .startAt(startAt)
                            .endAt(endAt)
                            .activation(true)
                            .build());
                    created++;
                }
            }
        }
        log.info("데모 상영 일정 보충 완료: {}건 생성, 보장 기간 {}일", created, scheduleHorizonDays);
    }

    @Scheduled(cron = "0 0 9,13,17,21 * * *", zone = "Asia/Seoul")
    public void createSimulatedReservations() {
        LocalDateTime now = LocalDateTime.now(KOREA_ZONE);
        List<ScheduleEntity> candidates = new ArrayList<>(
                scheduleRepository.findAllByStartAtBetweenAndActivationTrueOrderByStartAt(
                        now.plusHours(2), now.plusDays(scheduleHorizonDays)));
        java.util.Collections.shuffle(candidates);

        int runLimit = ThreadLocalRandom.current().nextInt(1, Math.max(2, reservationsPerRun + 1));
        int created = 0;
        for (ScheduleEntity schedule : candidates) {
            if (created >= runLimit) {
                break;
            }

            Set<String> occupied = new HashSet<>(
                    reservationService.readAllReservationSeatByScheduleId(schedule.getId()));
            int targetSeats = targetOccupiedSeats(schedule);
            if (occupied.size() >= targetSeats) {
                continue;
            }

            double demand = targetSeats / (double) SEAT_CAPACITY;
            if (ThreadLocalRandom.current().nextDouble() > Math.max(0.25, demand)) {
                continue;
            }

            List<String> available = SEAT_POOL.stream()
                    .filter(seat -> !occupied.contains(seat))
                    .collect(java.util.stream.Collectors.toCollection(ArrayList::new));
            java.util.Collections.shuffle(available);

            int requestedSeats = randomPartySize();
            int seatCount = Math.min(requestedSeats,
                    Math.min(available.size(), targetSeats - occupied.size()));
            if (seatCount == 0) {
                continue;
            }

            AdminReservationRequest request = new AdminReservationRequest();
            request.setScheduleId(schedule.getId());
            request.setSeats(new ArrayList<>(available.subList(0, seatCount)));
            paymentDetailsService.saveSimulatedReservation(request);
            created++;
        }
        log.info("시뮬레이션 예매 생성 완료: {}건 (이번 실행 한도 {}건)", created, runLimit);
    }

    private List<LocalTime> selectShowTimes(LocalDate date, Long theaterNo) {
        long seed = date.toEpochDay() * 31 + theaterNo;
        Random random = new Random(seed);
        int showCount = 2 + random.nextInt(3);
        List<LocalTime> times = new ArrayList<>(SHOW_TIME_CANDIDATES);
        java.util.Collections.shuffle(times, random);
        return times.stream().limit(showCount).sorted().toList();
    }

    private int targetOccupiedSeats(ScheduleEntity schedule) {
        long seed = schedule.getId() * 31 + schedule.getStartAt().toLocalDate().toEpochDay();
        Random random = new Random(seed);
        double targetRate = 0.08 + random.nextDouble() * 0.42;

        DayOfWeek day = schedule.getStartAt().getDayOfWeek();
        if (day == DayOfWeek.FRIDAY || day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY) {
            targetRate *= 1.25;
        }
        int hour = schedule.getStartAt().getHour();
        if (hour >= 18) {
            targetRate *= 1.20;
        } else if (hour < 12) {
            targetRate *= 0.75;
        }

        targetRate = Math.max(MIN_TARGET_OCCUPANCY, Math.min(MAX_TARGET_OCCUPANCY, targetRate));
        return Math.max(1, (int) Math.round(SEAT_CAPACITY * targetRate));
    }

    private int randomPartySize() {
        int value = ThreadLocalRandom.current().nextInt(100);
        if (value < 45) return 1;
        if (value < 85) return 2;
        if (value < 97) return 3;
        return 4;
    }

    private static List<String> createSeatPool() {
        List<String> seats = new ArrayList<>();
        for (char row = 'A'; row <= 'H'; row++) {
            for (int number = 1; number <= 5; number++) {
                seats.add(row + String.valueOf(number));
            }
        }
        return List.copyOf(seats);
    }
}
