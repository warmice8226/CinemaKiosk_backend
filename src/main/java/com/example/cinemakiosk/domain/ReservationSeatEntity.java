package com.example.cinemakiosk.domain;

import com.example.cinemakiosk.dto.ReservationDetailsDTO;
import com.example.cinemakiosk.dto.ReservationSeatDTO;
import com.example.cinemakiosk.vo.ReservationSeatVO;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "reservation_seat", indexes = @Index(name = "idx_reservation_seat_reservation_id", columnList = "reservation_id"))
public class ReservationSeatEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(columnDefinition = "BIGINT UNSIGNED")
    private Long id;               //인덱스

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reservation_id", nullable = false, columnDefinition = "CHAR(36)", foreignKey = @ForeignKey(name = "fk_reservation_seat_reservation_id"))
    private ReservationDetailsEntity reservationDetailsEntity;  //예매 내역 아이디

    @Column(length = 10, nullable = false)
    private String seatNumber;     //좌석 번호

    /**
     * Entity -> DTO
     * @param reservationSeatEntity
     * @return DTO
     */
    public static ReservationSeatDTO toDTO(ReservationSeatEntity reservationSeatEntity){
        return ReservationSeatDTO.builder()
                .id(reservationSeatEntity.getId())
                .reservationDetailsId(reservationSeatEntity.getReservationDetailsEntity().getId())
                .seatNumber(reservationSeatEntity.getSeatNumber())
                .build();
    }
}
