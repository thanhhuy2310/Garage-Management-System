// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InventoryCheckItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface InventoryCheckItemRepository extends JpaRepository<InventoryCheckItem, InventoryCheckItem.Key> {

    List<InventoryCheckItem> findByCheckIdOrderByPartId(Integer checkId);

    List<InventoryCheckItem> findByCheckIdIn(Collection<Integer> checkIds);
}
