package com.example.cinemakiosk.domain;

import com.example.cinemakiosk.domain.enums.Type;
import com.example.cinemakiosk.dto.PointHistoryDTO;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@ToString(exclude = {"memberEntity", "paymentDetailsEntity"})
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "point_history", indexes = {
        @Index(name = "idx_point_history_payment_id", columnList = "payment_id"),
        @Index(name = "idx_point_history_phone", columnList = "phone")
})
public class PointHistoryEntity{
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(columnDefinition = "BIGINT UNSIGNED")
    @Id private Long pointId; // 포인트 인덱스

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_id", nullable = false, foreignKey = @ForeignKey(name = "fk_point_history_payment_id"))
    private PaymentDetailsEntity paymentDetailsEntity; // 결제 고유번호 FK

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "phone", nullable = false, columnDefinition = "CHAR(36)", foreignKey =
    @ForeignKey(name = "fk_point_history_phone",
            foreignKeyDefinition = "FOREIGN KEY (`phone`) REFERENCES member (`phone`) ON UPDATE CASCADE"))
    private MemberEntity memberEntity; // 회원번호 FK

    @Enumerated(EnumType.STRING) // Enum
    @Column(nullable = false)
    private Type type; // 적립 / 사용 ('EARN', 'USE')

    @Column(nullable = false, columnDefinition = "INT UNSIGNED")
    private Integer amountPoint; // 사용할 포인트
    
    @Column(nullable = false, columnDefinition = "DATETIME DEFAULT NOW()")
    private LocalDateTime createAt; // 포인트 변경일


    /**
     * Entity -> DTO
     * @param pointHistoryEntity
     * @return DTO
     */
    public static PointHistoryDTO toDTO(PointHistoryEntity pointHistoryEntity){
        return PointHistoryDTO.builder()
                .pointId(pointHistoryEntity.getPointId())
                .type(pointHistoryEntity.getType())
                .amountPoint(pointHistoryEntity.getAmountPoint())
                .createAt(pointHistoryEntity.getCreateAt())
                .build();
    }
    
}
