// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InventoryCheck;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InventoryCheckRepository extends JpaRepository<InventoryCheck, Integer> {

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT c FROM InventoryCheck c WHERE c.id = :id")
    java.util.Optional<InventoryCheck> findForUpdate(@org.springframework.data.repository.query.Param("id") Integer id);

    Page<InventoryCheck> findAllByOrderByIdDesc(Pageable pageable);
}
