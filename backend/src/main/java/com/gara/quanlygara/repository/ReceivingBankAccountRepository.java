package com.gara.quanlygara.repository;
import com.gara.quanlygara.entity.ReceivingBankAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReceivingBankAccountRepository extends JpaRepository<ReceivingBankAccount, Integer> {
    List<ReceivingBankAccount> findAllByOrderByNameAscIdAsc();
}
