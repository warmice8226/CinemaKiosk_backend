package com.example.cinemakiosk.domain;

import com.example.cinemakiosk.dto.ReservationDetailsDTO;
import com.example.cinemakiosk.dto.ReservationSeatDTO;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import org.springframework.data.annotation.CreatedDate;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@Builder
@ToString(exclude = {"reservationSeatEntity", "paymentDetailsEntity", "memberEntity", "scheduleEntity"})
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "reservation_details", indexes = {
        @Index(name = "idx_reservation_details_schedule_id", columnList = "schedule_id"),
        @Index(name = "idx_reservation_details_phone", columnList = "phone")
})
public class ReservationDetailsEntity{
    @Id
    @Column(length = 36, columnDefinition = "CHAR(36)")
    private String id;                     // 예매 고유번호

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id", columnDefinition = "BIGINT UNSIGNED", nullable = false, foreignKey =
    @ForeignKey(name = "fk_reservation_details_payment_id"))
    private ScheduleEntity scheduleEntity;               //  스케쥴 정보 FK

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "phone", foreignKey =
    @ForeignKey(name = "fk_reservation_details_schedule_id",
            foreignKeyDefinition = "FOREIGN KEY (`phone`) REFERENCES member (`phone`) ON UPDATE CASCADE"))
    private MemberEntity memberEntity;                  //  회원 번호 FK

    @Column(nullable = false, columnDefinition = "BOOLEAN DEFAULT FALSE")
    private boolean returned;

    @CreatedDate
    @Column(nullable = false, updatable = false, columnDefinition = "DATETIME DEFAULT NOW()")
    private LocalDateTime createAt; //  예약 시간

    @OneToMany(mappedBy = "reservationDetailsEntity")
    private List<ReservationSeatEntity> reservationSeatEntity;

    @OneToMany(mappedBy = "reservationDetailsEntity")
    private List<PaymentDetailsEntity> paymentDetailsEntity;

    /**
     * 환불 여부 변경 도메인 메서드
     * @param returned 변경될 환불 여부
     */
    public void changeReturned(boolean returned) {
        this.returned = returned;
    }

    /**
     * Entity -> DTO
     * @param reservationDetailsEntity
     * @return DTO
     */
    public static ReservationDetailsDTO toDTO(ReservationDetailsEntity reservationDetailsEntity) {
        List<ReservationSeatDTO> seats = new ArrayList<>();
        if (reservationDetailsEntity.getReservationSeatEntity() != null) {
            for (ReservationSeatEntity seatEntity : reservationDetailsEntity.getReservationSeatEntity()) {
                seats.add(ReservationSeatEntity.toDTO(seatEntity));
            }
        }

        return ReservationDetailsDTO.builder()
                .id(reservationDetailsEntity.getId())
                .schedule(ScheduleEntity.toDTO(reservationDetailsEntity.getScheduleEntity()))
                .phone(MemberEntity.toDTO(reservationDetailsEntity.getMemberEntity()))
                .seats(seats)
                .createAt(reservationDetailsEntity.getCreateAt())
                .build();
    }

    /**
     * 해당 객체가 가진 seat의 Name을 반환받기 위해서 사용함.
     * @return reservationSeatEntity 변수 속의 seatName 
     */
    public List<String> getSeatName(){
        List<String> seatName = new ArrayList<>();
        for (ReservationSeatEntity reservationSeatEntity : this.reservationSeatEntity){
            seatName.add(reservationSeatEntity.getSeatNumber());
        }

        return seatName;
    }
}
