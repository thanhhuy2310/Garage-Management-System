package com.gara.quanlygara.validation;

import java.text.Normalizer;
import java.util.Locale;

/** Accepts the legacy Vietnamese label without rewriting historical records. */
public final class ServiceTypes {
    public static final String MAINTENANCE = "BAO_DUONG";
    private ServiceTypes() { }

    public static boolean isMaintenance(String value) {
        if (value == null) return false;
        String key = Normalizer.normalize(value.strip(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "").replace('đ', 'd').replace('Đ', 'D')
                .toUpperCase(Locale.ROOT).replaceAll("[\\s_]+", "_");
        return MAINTENANCE.equals(key);
    }

    public static String normalize(String value) {
        return isMaintenance(value) ? MAINTENANCE : value == null || value.isBlank() ? null : value.strip();
    }
}
