// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockReceiptItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface StockReceiptItemRepository extends JpaRepository<StockReceiptItem, StockReceiptItem.Key> {

    List<StockReceiptItem> findByReceiptId(Integer receiptId);

    List<StockReceiptItem> findByReceiptIdIn(Collection<Integer> receiptIds);
}
