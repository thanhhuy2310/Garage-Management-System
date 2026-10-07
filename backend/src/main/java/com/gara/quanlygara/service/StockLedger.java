// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Điểm DUY NHẤT trong ứng dụng ghi SoLuongTon và BienDongKho.
 * Luôn khóa dòng phụ tùng (UPDLOCK) trước khi đọc tồn, rồi mới ghi tồn mới + biến động trong cùng transaction
 * của service gọi (rollback toàn bộ nếu một bước lỗi).
 */
@Component
public class StockLedger {

    public static final String IN = "NHAP";
    public static final String OUT = "XUAT";
    public static final String COUNT = "KIEM_KE";

    private final SparePartRepository sparePartRepository;
    private final StockMovementRepository movementRepository;

    public StockLedger(SparePartRepository sparePartRepository, StockMovementRepository movementRepository) {
        this.sparePartRepository = sparePartRepository;
        this.movementRepository = movementRepository;
    }

    /** Khóa dòng phụ tùng cho tới hết transaction và trả về tồn hiện tại. */
    public int lock(Integer partId) {
        return sparePartRepository.lockStockQuantity(partId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng."));
    }

    /** Đặt tồn mới và ghi một dòng BienDongKho. quantity là số lượng của biến động (theo CK_BienDongKho_SoLuong). */
    public StockMovement apply(
            Integer partId, int before, int after, String type, int quantity,
            Integer receiptId, Integer issueId, String note
    ) {
        if (after < 0) {
            throw new ConflictException("Số lượng tồn kho không đủ.");
        }
        if (sparePartRepository.updateStockQuantity(partId, after) != 1) {
            throw new ConflictException("Không thể cập nhật tồn kho của phụ tùng " + partId + ".");
        }

        StockMovement movement = new StockMovement();
        movement.setPartId(partId);
        movement.setReceiptId(receiptId);
        movement.setIssueId(issueId);
        movement.setMovedAt(LocalDateTime.now());
        movement.setType(type);
        movement.setQuantity(quantity);
        movement.setQuantityBefore(before);
        movement.setQuantityAfter(after);
        movement.setNote(note);
        return movementRepository.save(movement);
    }
}
