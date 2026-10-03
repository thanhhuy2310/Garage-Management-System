// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

import com.gara.quanlygara.entity.SparePart;
import org.springframework.data.domain.Page;

import java.util.List;

/** page bắt đầu từ 0, giống Spring Data. */
public record SparePartPageResponse(
        List<SparePartResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static SparePartPageResponse from(Page<SparePart> result) {
        return new SparePartPageResponse(
                result.getContent().stream().map(SparePartResponse::from).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }
}
