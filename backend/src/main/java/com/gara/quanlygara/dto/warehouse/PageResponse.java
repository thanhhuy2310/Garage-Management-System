// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import org.springframework.data.domain.Page;

import java.util.List;
import java.util.function.Function;

/** page bắt đầu từ 0, giống Spring Data. */
public record PageResponse<T>(List<T> items, int page, int size, long totalElements, int totalPages) {

    public static <S, T> PageResponse<T> of(Page<S> page, Function<S, T> mapper) {
        return new PageResponse<>(
                page.getContent().stream().map(mapper).toList(),
                page.getNumber(), page.getSize(), page.getTotalElements(), page.getTotalPages());
    }

    public static <T> PageResponse<T> of(Page<T> page) {
        return of(page, Function.identity());
    }
}
