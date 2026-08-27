package com.example.cinemakiosk.service;

import com.example.cinemakiosk.domain.PaymentDetailsEntity;
import com.example.cinemakiosk.domain.enums.Status;
import com.example.cinemakiosk.domain.enums.Type;
import com.example.cinemakiosk.dto.*;
import com.example.cinemakiosk.dto.requestDTO.AdminReservationRequest;
import com.example.cinemakiosk.mapper.PaymentDetailsMapper;
import com.example.cinemakiosk.repository.PaymentDetailsRepository;
import com.example.cinemakiosk.vo.CouponVO;
import com.example.cinemakiosk.vo.PaymentDetailsVO;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.data.domain.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;

@Log4j2
@Service
@RequiredArgsConstructor
public class PaymentDetailsServiceImpl implements PaymentDetailsService {

    private static final String SIMULATED_PAYMENT_KEY = "simulated";

    @Value("${toss.widget-secret-key}")
    private String tossWidgetSecretKey;

    private final PaymentDetailsMapper paymentDetailsMapper;
    private final PaymentDetailsRepository paymentDetailsRepository;
    private final ReservationService reservationService; //확정된 예매 등록을 위해서 작성
    private final MemberService memberService; //포인트 관리를 위해서 작성.
    private final BonusPolicyService bonusPolicyService; //보너스 적립 비율 확인을 위해 사용
    private final ScheduleService scheduleService; // 스케쥴 정보를 그냥 받아오는게 빠를듯.
    private final TheaterService theaterService; // 관리자 예매 시 좌석 정가 계산용
    private final DiscountPolicyService discountPolicyService;
    private final ObjectMapper objectMapper; // 스프링이 자동으로 주입해주는 JSON 변환기


    //결제 시도 및 결과 등록
    @Override
    public void create(PaymentDetailsDTO paymentDetailsDTO) {
        paymentDetailsRepository.save(PaymentDetailsDTO.toEntity(paymentDetailsDTO));
    }


    //결제 내역 조회
    @Override
    public PaymentDetailsDTO read(String uuid) {
        PaymentDetailsVO paymentDetailsVO = paymentDetailsMapper.selectOneById(uuid);
        return PaymentDetailsVO.toDTO(paymentDetailsVO);
    }


    //결제 내역 전체조회
    @Override
    public Page<PaymentDetailsDTO> readAll(int page) {
        int offset = (page - 1) * 10;
        long count = paymentDetailsRepository.count();
        List<PaymentDetailsVO> paymentDetailsVOS = paymentDetailsMapper.selectAll(offset);
        Pageable pageable = PageRequest.of(page - 1, 10, Sort.by("createAt").descending());
        log.info("{}번 ~ {}번", offset + 1, offset + 10);
        return new PageImpl<>(paymentDetailsVOS.stream().map(PaymentDetailsVO::toDTO).toList(), pageable, count);
    }

    //결제 내역 변경
    @Override
    @Transactional
    public void updateToReturn(PaymentDetailsDTO paymentDetailsDTO) {
        PaymentDetailsEntity entity = paymentDetailsRepository.findById(paymentDetailsDTO.getId()).orElseThrow();
        entity.changeStatus(Status.RETURN);
        entity.getReservationDetailsEntity().changeReturned(true);
        paymentDetailsRepository.save(entity);
    }

    /**
     * DB 저장 공통 로직 (Reservation, Payment, Point History)
     */
    @Transactional
    public void savePaymentInfo(JsonNode requestData, long amount) {
        log.info("데이터 저장 로직 시작.");
        String orderId = requestData.path("orderId").asText("");
        String paymentKey = requestData.path("paymentKey").asText("");
        String phone = requestData.path("phone").asText(null); // 없으면 비회원 null 반환
        boolean isGuest = phone == null || phone.isEmpty();

        long usePoint = requestData.path("usePoint").asLong(0);
        long scheduleIdValue = requestData.path("scheduleId").asLong(0);
        if (orderId.isBlank() || paymentKey.isBlank() || scheduleIdValue <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "필수 결제 정보가 누락되었습니다.");
        }
        log.error("경계1");
        // 좌석 정보 파싱
        List<ReservationSeatDTO> seats = new ArrayList<>();

        JsonNode seatsNode = requestData.get("seats");
        if (seatsNode != null && seatsNode.isArray()) {
            for (JsonNode seat : seatsNode) {
                seats.add(ReservationSeatDTO.builder().seatNumber(seat.asText()).build());
            }
        }
        if (seats.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "선택된 좌석이 없습니다.");
        }
        log.error("경계2 {}", seats);
        ScheduleDTO schedule = scheduleService.getScheduleDTO(scheduleIdValue);
        String couponStr = requestData.path("couponNum").asText("");
        CouponDTO couponNum = couponStr.isEmpty() ? null : discountPolicyService.getCoupon(couponStr);
        log.error("경계3");
        MemberDTO member = null;
        BonusPolicyDTO bonusPolicy = null;

        if (!isGuest) {
            member = memberService.getMember(phone);
            bonusPolicy = bonusPolicyService.getBonusPolicy(member.getGrade());
        }

        // 1. 예매 등록
        ReservationDetailsDTO reservation = ReservationDetailsDTO.builder()
                .id(orderId)
                .schedule(schedule)
                .phone(isGuest ? null : member) // 비회원 null
                .seats(seats)
                .returned(false)
                .createAt(LocalDateTime.now())
                .build();

        log.error("경계4");
        ReservationDetailsDTO reservationDetailsDTO = reservationService.create(reservation);
        log.error("경계5");
        // 2. 결제 상세 등록
        PaymentDetailsDTO payment = PaymentDetailsDTO.builder()
                .id(orderId)
                .reservation(reservationDetailsDTO)
                .bonusPolicy(isGuest ? null : bonusPolicy) // 비회원 null
                .couponNum(couponNum)
                .cost(amount)
                .createAt(LocalDateTime.now())
                .usePoint(isGuest ? 0L : usePoint) // 비회원 포인트 사용 X
                .status(Status.PAY)
                .paymentKey(paymentKey)
                .build();
        log.error("경계7");
        create(payment);
        log.error("경계8");

        // 쿠폰을 사용할 경우 사용여부 변경
        if (couponNum != null) {
            CouponDTO dto = CouponDTO.builder()
                    .couponNum(couponNum.getCouponNum())
                    .status(false)
                    .build();
            discountPolicyService.updateStatus(dto);
            log.info("지정 쿠폰 : {}", dto);
        }

        // 3. 포인트 처리
        if (!isGuest) {
            int earnPoint = (int) (amount * bonusPolicy.getGiveValue() / 100);

            log.error("경계9");
            // 사용 내역 - 통과
            if (usePoint > 0) {
                memberService.pointHistoryCreate(PointHistoryDTO.builder()
                        .paymentId(orderId).phone(phone).type(Type.USE).amountPoint((int) usePoint)
                        .createAt(LocalDateTime.now()).title("영화 예매 포인트 사용")
                        .build());
                log.info("Point log");
            }

            log.error("경계10");
            // 적립 내역 - 걸림
            if (earnPoint > 0) {
                memberService.pointHistoryCreate(PointHistoryDTO.builder()
                        .paymentId(orderId).phone(phone).type(Type.EARN).amountPoint(earnPoint)
                        .createAt(LocalDateTime.now())
                        .build());
                log.info("Point Earn {}", earnPoint);

            }
            log.error("경계11");
            // 회원 등급 확인
            memberService.updateGrade(member.getPhone());
            // 멤버 실제 포인트 업데이트
            log.info("멤버 확인 : {}", member);
        }

        log.info("DB 저장 및 포인트 갱신 완료: 주문번호 {}", orderId);
    }

    /**
     * 관리자 직접 예매 로직 (토스 결제 없이 바로 DB 저장)
     */
    @Transactional
    @Override
    public void saveAdminReservation(AdminReservationRequest request) {
        saveInternalReservation(request, "admin");
    }



    @Transactional
    @Override
    public void saveSimulatedReservation(AdminReservationRequest request) {
        saveInternalReservation(request, SIMULATED_PAYMENT_KEY);
    }

    private void saveInternalReservation(AdminReservationRequest request, String paymentKey) {
        String orderId = java.util.UUID.randomUUID().toString();

        ScheduleDTO schedule = scheduleService.getScheduleDTO(request.getScheduleId());

        List<ReservationSeatDTO> seats = request.getSeats().stream()
                .map(seatNum -> ReservationSeatDTO.builder().seatNumber(seatNum).build())
                .toList();

        // 1. 예매 등록
        ReservationDetailsDTO reservation = ReservationDetailsDTO.builder()
                .id(orderId)
                .schedule(schedule)
                .phone(null)
                .seats(seats)
                .returned(false)
                .createAt(LocalDateTime.now())
                .build();

        ReservationDetailsDTO savedReservation = reservationService.create(reservation);

        // 2. 좌석 정가 계산: schedule.no -> theater.policyId -> seatPolicy.cost × 좌석 수
        TheaterDTO theater = theaterService.getTheater(schedule.getNo());
        SeatPolicyDTO seatPolicy = theaterService.readSeat(theater.getPolicyId());
        long cost = seatPolicy.getCost() * request.getSeats().size();

        // 3. 결제 내역 등록 (관리자 예매는 현장결제로 paymentKey="admin", 포인트/쿠폰 없음)
        PaymentDetailsDTO payment = PaymentDetailsDTO.builder()
                .id(orderId)
                .reservation(savedReservation)
                .bonusPolicy(null)
                .couponNum(null)
                .cost(cost)
                .createAt(LocalDateTime.now())
                .usePoint(0L)
                .status(Status.PAY)
                .paymentKey(paymentKey)
                .build();

        create(payment);

        log.info("내부 예매 완료: 주문번호 {}, 결제유형 {}", orderId, paymentKey);
    }

    /**
     * 토스 API 승인 요청 메서드
     */
    public JsonNode confirmTossPayment(String orderId, long amount, String paymentKey) {

        String url = "https://api.tosspayments.com/v1/payments/confirm";

        // 1. 헤더 설정 (Basic Auth 및 Content-Type)
        HttpHeaders headers = new HttpHeaders();
        headers.setBasicAuth(tossWidgetSecretKey, ""); // 콜론(:) 처리를 자동으로 해줍니다.
        headers.setContentType(MediaType.APPLICATION_JSON);

        // 2. 바디 데이터 생성 (Map 또는 DTO 사용 가능)
        Map<String, Object> payload = new HashMap<>();
        payload.put("orderId", orderId);
        payload.put("amount", amount);
        payload.put("paymentKey", paymentKey);

        // 3. 요청 객체(HttpEntity) 생성
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(payload, headers);

        RestTemplate restTemplate = new RestTemplate();

        try {
            // 4. POST 요청 및 응답 처리
            return restTemplate.postForObject(url, entity, JsonNode.class);
        } catch (HttpClientErrorException | HttpServerErrorException e) {
            // 5. 에러 발생 시(400, 500 등) 에러 바디(JSON)를 파싱하여 반환
            try {
                return objectMapper.readTree(e.getResponseBodyAsString());
            } catch (Exception ex) {
                log.error("토스 에러 응답 파싱 실패", ex);
                return null;
            }
        }
    }
}
