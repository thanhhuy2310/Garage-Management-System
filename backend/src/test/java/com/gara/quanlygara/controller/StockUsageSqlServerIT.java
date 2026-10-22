package com.gara.quanlygara.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Requires Seed_Integrated_Demo.sql on the local development database; every change rolls back. */
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional
class StockUsageSqlServerIT {
 @Autowired JdbcTemplate jdbc;
 @Autowired org.springframework.test.web.servlet.MockMvc mvc;
 @Autowired ObjectMapper json;
 @Autowired EntityManager em;
 @ParameterizedTest @ValueSource(ints={0,1})
 void actualUsageUpdatesStockAndBillingTogether(int actual) throws Exception {
  var row=jdbc.queryForMap("""
    SELECT px.MaPhieuXuat AS issueId,p.MaPhieuSuaChua AS orderId,ct.MaPhuTung AS partId
    FROM Xe x JOIN PhieuTiepNhan tn ON tn.MaXe=x.MaXe
    JOIN PhieuSuaChua p ON p.MaTiepNhan=tn.MaTiepNhan
    JOIN PhieuXuatKho px ON px.MaPhieuSuaChua=p.MaPhieuSuaChua
    JOIN ChiTietPhieuXuat ct ON ct.MaPhieuXuat=px.MaPhieuXuat
    WHERE x.BienSo='51G-880.04' AND ct.DaXacNhanSuDung=0
    """);
  int issue=((Number)row.get("issueId")).intValue(), order=((Number)row.get("orderId")).intValue(), part=((Number)row.get("partId")).intValue();
  int stock=jdbc.queryForObject("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",Integer.class,part);
  String url="/api/warehouse/exports/"+issue+"/items/"+part+"/confirm";
  mvc.perform(post(url).with(user("demo_gara_manager").roles("MANAGER")).contentType(APPLICATION_JSON)
    .content(json.writeValueAsString(Map.of("actualUsed",actual)))).andExpect(status().isForbidden());
  mvc.perform(post(url).with(user("demo_gara_technician").roles("TECHNICIAN")).contentType(APPLICATION_JSON)
    .content(json.writeValueAsString(Map.of("actualUsed",actual)))).andExpect(status().isOk());
  em.flush(); em.clear();
  assertEquals(stock-actual,jdbc.queryForObject("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",Integer.class,part));
  assertEquals(actual,jdbc.queryForObject("SELECT COALESCE(SUM(SoLuong),0) FROM ChiTietPhuTung WHERE MaPhieuSuaChua=? AND MaPhuTung=?",Integer.class,order,part));
  assertEquals(actual,jdbc.queryForObject("SELECT COUNT(*) FROM BienDongKho WHERE MaPhieuXuat=?",Integer.class,issue));
  mvc.perform(post(url).with(user("demo_gara_technician").roles("TECHNICIAN")).contentType(APPLICATION_JSON)
    .content(json.writeValueAsString(Map.of("actualUsed",actual)))).andExpect(status().isConflict());
  assertEquals(stock-actual,jdbc.queryForObject("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",Integer.class,part));
 }
}
