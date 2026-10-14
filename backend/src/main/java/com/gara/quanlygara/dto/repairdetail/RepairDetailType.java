// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import com.gara.quanlygara.exception.BadRequestException;

import java.util.Locale;

/** Hạng mục của phiếu sửa chữa là dịch vụ (ChiTietDichVu) hoặc phụ tùng (ChiTietPhuTung). */
public enum RepairDetailType {
    SERVICE,
    SPARE_PART;

    /** Giá trị trên đường dẫn: "service" hoặc "spare-part". */
    public static RepairDetailType fromPath(String value) {
        if (value == null) throw new BadRequestException("Loại hạng mục không hợp lệ.");
        try {
            return valueOf(value.trim().toUpperCase(Locale.ROOT).replace('-', '_'));
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("Loại hạng mục không hợp lệ.");
        }
    }
}
