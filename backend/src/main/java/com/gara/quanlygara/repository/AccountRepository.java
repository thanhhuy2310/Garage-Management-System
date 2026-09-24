package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Integer> {
    Optional<Account> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByUsernameAndIdNot(String username, Integer id);

    boolean existsByEmployeeId(Integer employeeId);

    boolean existsByEmployeeIdAndIdNot(Integer employeeId, Integer id);
}
