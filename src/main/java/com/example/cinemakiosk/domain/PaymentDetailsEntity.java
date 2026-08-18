package com.example.cinemakiosk.domain;

import com.example.cinemakiosk.domain.enums.Status;
import com.example.cinemakiosk.dto.*;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@Builder
@ToString(exclude = {"pointHistoryEntity", "reservationDetailsEntity", "couponEntity", "bonusPolicyEntity"})
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "payment_details", indexes = {
        @Index(name = "idx_payment_details_reservation_id", columnList = "reservation_id"),
        @Index(name = "idx_payment_details_coupon_num", columnList = "coupon_num"),
        @Index(name = "idx_payment_details_bonus_policy_id", columnList = "bonus_policy_id")
})
public class PaymentDetailsEntity {
    @Id
    @Column(length = 36, columnDefinition = "CHAR(36)")
    private String id;             // 인덱스

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reservation_id", nullable = false, columnDefinition = "CHAR(36)", foreignKey = @ForeignKey(name = "fk_payment_details_reservation_id"))
    private ReservationDetailsEntity reservationDetailsEntity;  // 예매 정보

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bonus_policy_id", foreignKey = @ForeignKey(name = "fk_payment_details_bonus_policy_id"))
    private BonusPolicyEntity bonusPolicyEntity;    // 사용한 적립 정책

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coupon_num", foreignKey = @ForeignKey(name = "fk_payment_details_coupon_id"))
    private CouponEntity couponEntity;      // 사용한 할인 쿠폰, 없는 경우 null

    @Column(nullable = false)
    private Long cost;             // 결제 금액

    @Column(nullable = false)
    private LocalDateTime createAt;    // 결제 시간

    @Column(name = "payment_key", nullable = false, length = 100)
    private String paymentKey;    // 환불을 위한 키

    @Column(columnDefinition = "BIGINT UNSIGNED DEFAULT 0")
    private Long usePoint;         // 사용 포인트 기본값 0

    @Enumerated(EnumType.STRING)
    private Status status;         // ENUM ('PAY','RETURN','FAIL'), 결제 완료, 환불, 실패

    @OneToMany(mappedBy = "paymentDetailsEntity")
    private  List<PointHistoryEntity> pointHistoryEntity;

    /**
     * 결제내역 상태 변경 도메인 메서드
     * @param status 변경될 상태값
     */
    public void changeStatus(Status status) {
        this.status = status;
    }

    /**
     * Entity -> DTO
     * @param paymentDetailsEntity
     * @return DTO
     */
    public static PaymentDetailsDTO toDTO(PaymentDetailsEntity paymentDetailsEntity){

        BonusPolicyDTO bonusPolicyDTO = null;
        if (paymentDetailsEntity.getBonusPolicyEntity() != null) {
            bonusPolicyDTO = BonusPolicyEntity.toDTO(paymentDetailsEntity.getBonusPolicyEntity());
        }

        // couponEntity null 체크
        CouponDTO couponDTO = null;
        if (paymentDetailsEntity.getCouponEntity() != null) {
            couponDTO = CouponEntity.toDTO(paymentDetailsEntity.getCouponEntity());
        }

        return PaymentDetailsDTO.builder()
                .id(paymentDetailsEntity.getId())
                .reservation(ReservationDetailsEntity.toDTO(paymentDetailsEntity.getReservationDetailsEntity()))
                .bonusPolicy(bonusPolicyDTO)
                .couponNum(couponDTO)
                .cost(paymentDetailsEntity.getCost())
                .createAt(paymentDetailsEntity.getCreateAt())
                .usePoint(paymentDetailsEntity.getUsePoint())
                .status(paymentDetailsEntity.getStatus())
                .paymentKey(paymentDetailsEntity.getPaymentKey())
                .build();
    }
    
}
