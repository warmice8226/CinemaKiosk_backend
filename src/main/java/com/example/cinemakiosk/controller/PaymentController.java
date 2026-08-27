package com.example.cinemakiosk.controller;

import com.example.cinemakiosk.dto.*;
import com.example.cinemakiosk.dto.requestDTO.AdminReservationRequest;
import com.example.cinemakiosk.domain.enums.Status;
import com.example.cinemakiosk.service.*;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.data.domain.Page;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.beans.factory.annotation.Value;

import java.io.*;
import java.util.*;

@Log4j2
@RestController // @Controller + @ResponseBody 합쳐진 것
@RequiredArgsConstructor
@RequestMapping(value = "/api")
public class PaymentController {

    @Value("${toss.secret-key}")
    private String tossSecretKey;

    private final ObjectMapper objectMapper; // 스프링이 자동으로 주입해주는 JSON 변환기
    private final PaymentDetailsService paymentDetailsService; //결제 내역 등록을 위해서 작성.
    private final RefundService refundService;

    /**
     * 결제를 확정짓는 메서드
     * @param jsonBody 결제 요청 JSON 본문 (payType, orderId, amount, paymentKey 포함)
     * @return 결제 처리 결과 ResponseEntity (성공 시 200, 실패 시 400)
     * @throws Exception 외부 토스 결제 API 호출 실패 시
     */
    @PostMapping(value = "/payment/confirm")
    public ResponseEntity<JsonNode> confirmPayment(@RequestBody String jsonBody) throws Exception {
        log.info("결제 컨펌 로직 시작");


        // 1. 파싱 (Jackson 사용)
        JsonNode requestData = objectMapper.readTree(jsonBody);
        String payType = requestData.path("payType").asText(); // 기본값 CARD
        String orderId = requestData.path("orderId").asText();
        String amountStr = requestData.path("amount").asText("0");
        long amount = Long.parseLong(amountStr);

        long scheduleId = requestData.path("scheduleId").asLong(0);
        JsonNode seats = requestData.path("seats");
        if (orderId.isBlank() || scheduleId <= 0 || !seats.isArray() || seats.isEmpty() || amount < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "필수 결제 정보가 누락되었거나 올바르지 않습니다.");
        }

        String PAY_TYPE_CARD = "CARD";

        JsonNode responseResult = null;
        int statusCode = 200;


        if (PAY_TYPE_CARD.equalsIgnoreCase(payType) && amount > 0) { // 할인후 금액이 0보다 클경우만 (전액 포인트할인이 적용될 경우를 생각함)
            log.error("경계2");
            // 1. 토스 결제 승인 로직
            String paymentKey = requestData.path("paymentKey").asText("");
            if (paymentKey.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "paymentKey가 필요합니다.");
            }
            responseResult = paymentDetailsService.confirmTossPayment(orderId, amount, paymentKey);

            // 토스 응답이 200이 아니면 실패 처리 (예외 던지거나 에러 리턴)
            if (responseResult == null) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "토스 결제 승인 응답이 없습니다.");
            }
            if (responseResult.has("code") && !responseResult.has("status")) {
                return ResponseEntity.status(400).body(responseResult);
            }
        } else {
            log.error("경계3");
            // 2. 포인트 전액 결제 로직
            log.info("포인트 전액 결제 처리: {}", orderId);
            ObjectNode successNode = objectMapper.createObjectNode();
            successNode.put("status", "DONE");
            successNode.put("orderId", orderId);
            successNode.put("method", "POINT");
            responseResult = successNode;
        }
        log.error("경계4");

        // 3. 공통 DB 저장 로직 실행
        paymentDetailsService.savePaymentInfo(requestData, amount);

        log.error("경계5");
        return ResponseEntity.status(statusCode).body(responseResult);
    }

    /**
     * 결제 내역 단일 조회
     * @param no 조회할 결제 내역 UUID
     * @return 조회된 결제 내역 DTO
     */
    @GetMapping("/admin/payment/read/{uuid}")
    public ResponseEntity<PaymentDetailsDTO> readOne(@PathVariable("uuid") String no) {
        log.info("찾으려는 uuid : {}", no);
        PaymentDetailsDTO paymentDetailsDTO = paymentDetailsService.read(no);
        log.info("조회된 결제 내역 : {}", paymentDetailsDTO);
        return ResponseEntity.ok(paymentDetailsDTO);
    }

    @PostMapping("/admin/payment/refund")
    public ResponseEntity<Void> refund(@RequestBody String jsonBody) throws JsonProcessingException {
        //1. payment값이 필요함
        //2. 결제 내역 정보가 필요함


        log.error("경계");
        // 1. 파싱 (Jackson 사용)
        JsonNode requestData = objectMapper.readTree(jsonBody);
        String paymentId = requestData.path("paymentId").asText();
        if (paymentId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "paymentId가 필요합니다.");
        }
        PaymentDetailsDTO payment = paymentDetailsService.read(paymentId);
        if (payment.getStatus() == Status.RETURN) {
            return ResponseEntity.ok().build();
        }
        String paymentKey = payment.getPaymentKey();

        if (paymentKey == null || paymentKey.isBlank() || paymentKey.equals("point") || paymentKey.equals("admin") || paymentKey.equals("simulated")) {
            log.info("환불할 금액 0원 이거나 관리자 예매(현장 결제를 가정함) 이므로 토스 호출 하지않음: {}", paymentId);
            refundService.refund(paymentId);
            return ResponseEntity.ok().build();
        }


        RestTemplate restTemplate = new RestTemplate();

        //환불처리
        // 1. URL 설정
        String url = "https://api.tosspayments.com/v1/payments/" + paymentKey + "/cancel";

        // 2. 헤더 설정 (Authorization & Content-Type)
        HttpHeaders headers = new HttpHeaders();
        // Authorization: Basic {Base64 인코딩된 시크릿키}

        String secretKey = tossSecretKey;// 1. 테스트 시크릿 키
        String encodedKey = Base64.getEncoder().encodeToString((secretKey + ":").getBytes()); // 2. 키 뒤에 콜론(:)을 더하고 Base64로 변환

        headers.set("Authorization", "Basic " + encodedKey);
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Idempotency-Key", "refund-" + paymentId);

        // 3. 바디(데이터) 설정
        Map<String, String> map = new HashMap<>();
        map.put("cancelReason", "구매자가 취소를 원함");

        HttpEntity<Map<String, String>> entity = new HttpEntity<>(map, headers);

        // 4. API 호출 및 응답 받기
        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url, entity, String.class);
            log.info("{} : {}", response.getStatusCode(), response.getBody());

            if (response.getStatusCode() == HttpStatus.OK) {
                System.out.println("취소 성공: " + response.getBody());

                //환불처리
                refundService.refund(paymentId);

            }
        } catch (Exception e) {
            log.error("토스 결제 취소 실패: paymentId={}", paymentId, e);
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "토스 결제 취소에 실패했습니다.", e);
        }

        return ResponseEntity.ok().build();
    }

    @Operation(summary = "결제 내역 모두 조회 (페이징)")
    @GetMapping("/admin/payment/list")
    public ResponseEntity<Page<PaymentDetailsDTO>> readAllPayment(@RequestParam(defaultValue = "1") int page) {
        return ResponseEntity.ok(paymentDetailsService.readAll(page));
    }

    @Operation(summary = "관리자 직접 예매")
    @PostMapping("/admin/payment/admin-reserve")
    public ResponseEntity<Void> adminReserve(@RequestBody AdminReservationRequest request) {
        paymentDetailsService.saveAdminReservation(request);
        return ResponseEntity.ok().build();
    }

}
