package com.example.cinemakiosk.domain.admindomain;

import com.example.cinemakiosk.dto.adminDTO.AdminDTO;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import org.springframework.data.annotation.CreatedDate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Getter
@ToString (exclude = "adminRoleMapEntity")
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "admin")
public class AdminEntity{

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "admin_id", columnDefinition = "BIGINT UNSIGNED")
    private Long adminId;         // 관리자 인덱스 (PK)

    @Column(name = "login_id", nullable = false, unique = true)
    private String loginId;       // 관리자 아이디

    @Column(name = "password", nullable = false)
    private String password;      // 관리자 비밀번호

    @Column(name = "name", nullable = false)
    private String name;          // 관리자 이름

    @Column(name = "admin_phone", nullable = false, unique = true)
    private String adminPhone;    // 전화번호

    @Column(name = "level", nullable = false)
    private boolean level;        // 권한 레벨 (false: 마스터 0, true: 직원(알바) 1)

    @Column(name = "refresh_token", length = 36, columnDefinition = "CHAR(36)")
    private String refreshToken;          // 자동 로그인 토큰

    @CreatedDate
    @Column(name = "create_at", nullable = false, updatable = false, columnDefinition = "DATETIME DEFAULT NOW()")
    private LocalDateTime createAt; // 계정 생성 일자

    @OnDelete(action= OnDeleteAction.CASCADE)
    @OneToMany(mappedBy = "adminEntity", cascade = {CascadeType.ALL}, orphanRemoval = true)
    private List<AdminRoleMapEntity> adminRoleMapEntity; // 관리자 아이디 FK


    /**
     * refreshToken을 업데이트 하는 도메인 메서드
     * @param refreshToken 변경될 refreshToken
     */
    public void changeRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    /**
     * 로그아웃시 refreshToken 컬럼 null 처리 도메인 메서드
     */
    public void changeRefreshTokenNull() {
        this.refreshToken = null;
    }

    /**
     * Entity -> DTO
     * @param adminEntity
     * @return DTO
     */
    public static AdminDTO toDTO(AdminEntity adminEntity) {
        return AdminDTO.builder()
                .adminId(adminEntity.getAdminId())
                .loginId(adminEntity.getLoginId())
                .password(adminEntity.getPassword())  // 암호화된 비밀번호 저장
                .name(adminEntity.getName())
                .adminPhone(adminEntity.getAdminPhone())
                .level(adminEntity.isLevel())
                .refreshToken(adminEntity.getRefreshToken())
                .createAt(adminEntity.getCreateAt())
                .build();
    }
}
