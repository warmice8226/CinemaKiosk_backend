package com.example.cinemakiosk.service;

import com.example.cinemakiosk.dto.PaymentDetailsDTO;
import com.example.cinemakiosk.dto.requestDTO.AdminReservationRequest;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.data.domain.Page;

import java.util.List;

public interface PaymentDetailsService {
    //결제 시도 및 결과 등록
    void create(PaymentDetailsDTO paymentDetailsDTO);

    //결제 내역 조회
    PaymentDetailsDTO read(String uuid);

    //결제 내역 전체조회
    Page<PaymentDetailsDTO> readAll(int page);

    //결제 내역 변경
    void updateToReturn(PaymentDetailsDTO paymentDetailsDTO);

    //예매 내용을 저장
    void savePaymentInfo(JsonNode requestData, long amount);

    //토스 결제 확인 로직
    JsonNode confirmTossPayment(String orderId, long amount, String paymentKey) throws Exception;

    void saveSimulatedReservation(AdminReservationRequest request);

    //관리자 직접 예매
    void saveAdminReservation(AdminReservationRequest request);
}
