// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockReceipt;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StockReceiptRepository extends JpaRepository<StockReceipt, Integer> {

    Page<StockReceipt> findAllByOrderByIdDesc(Pageable pageable);
}
