// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InventoryCheck;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InventoryCheckRepository extends JpaRepository<InventoryCheck, Integer> {

    Page<InventoryCheck> findAllByOrderByIdDesc(Pageable pageable);
}
