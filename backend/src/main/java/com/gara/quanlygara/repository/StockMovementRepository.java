// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.entity.StockMovement;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    // partId = 0 và type = 'ALL' nghĩa là không lọc (tránh tham số null trong JPQL).
    @Query(value = "SELECT new com.gara.quanlygara.dto.warehouse.StockMovementResponse("
            + "m.id, m.partId, p.name, m.receiptId, m.issueId, m.movedAt, m.type, m.quantity, "
            + "m.quantityBefore, m.quantityAfter, m.note) "
            + "FROM StockMovement m, SparePart p "
            + "WHERE p.id = m.partId AND (:partId = 0 OR m.partId = :partId) "
            + "AND (:type = 'ALL' OR m.type = :type) ORDER BY m.id DESC",
            countQuery = "SELECT COUNT(m) FROM StockMovement m "
                    + "WHERE (:partId = 0 OR m.partId = :partId) AND (:type = 'ALL' OR m.type = :type)")
    Page<StockMovementResponse> search(@Param("partId") int partId, @Param("type") String type, Pageable pageable);

    Optional<StockMovement> findFirstByIssueIdAndPartIdAndTypeOrderByIdDesc(Integer issueId, Integer partId, String type);
}
