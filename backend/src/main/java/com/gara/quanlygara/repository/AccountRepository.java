package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Integer> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select a from Account a where a.username=:name")
    Optional<Account> lockSessionOwner(@org.springframework.data.repository.query.Param("name") String name);

    Optional<Account> findByUsername(String username);

    Optional<Account> findByEmployeeId(Integer employeeId);

    Optional<Account> findByCustomerId(Integer customerId);

    @org.springframework.data.jpa.repository.Query(value="""
        SELECT COUNT(*) FROM TaiKhoan a LEFT JOIN KhachHang c ON c.MaKhachHang=a.MaKhachHang
        LEFT JOIN NhanVien e ON e.MaNhanVien=a.MaNhanVien
        WHERE LOWER(TRIM(COALESCE(c.Email,e.Email)))=LOWER(:email)
        """,nativeQuery=true)
    int countByContactEmail(@org.springframework.data.repository.query.Param("email") String email);

    boolean existsByUsername(String username);

    boolean existsByUsernameAndIdNot(String username, Integer id);

    boolean existsByEmployeeId(Integer employeeId);

    boolean existsByEmployeeIdAndIdNot(Integer employeeId, Integer id);
}
