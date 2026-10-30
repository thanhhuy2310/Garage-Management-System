package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.*;
import com.gara.quanlygara.service.StockIssueService;
import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class QuotationsSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    @Autowired StockIssueService stock;
    List<Integer> accounts=new ArrayList<>(),customers=new ArrayList<>();
    Integer employee,vehicle,reception,order,serviceId,part,warehouse;
    String owner,other,manager;
    @BeforeEach void prepare() {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).matches("QuanLyGaraOTo_Verify_\\d{8}"));
        String tag=UUID.randomUUID().toString().replace("-","").substring(0,10);
        owner="thanhha_"+tag;other="minhduc_"+tag;manager="quanghuy_"+tag;
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            customers.add(insert("KhachHang","MaKhachHang",Map.of("HoTen","Nguyễn Thanh Hà","SoDienThoai",tag+"1")));
            customers.add(insert("KhachHang","MaKhachHang",Map.of("HoTen","Trần Minh Đức","SoDienThoai",tag+"2")));
            employee=insert("NhanVien","MaNhanVien",Map.of("HoTen","Trần Quang Huy","ChucVu","Quản lý"));
            jdbc.update("INSERT INTO KyThuatVien(MaNhanVien) VALUES(?)",employee);
            account(owner,"CUSTOMER",customers.get(0));account(other,"CUSTOMER",customers.get(1));account(manager,"MANAGER",null);
            vehicle=insert("Xe","MaXe",Map.of("MaKhachHang",customers.get(0),"BienSo","51A-"+tag,"HangXe","Toyota","DongXe","Vios"));
            Timestamp now=Timestamp.valueOf(LocalDateTime.now());
            reception=insert("PhieuTiepNhan","MaTiepNhan",Map.of("MaXe",vehicle,"NgayTiepNhan",now));
            order=insert("PhieuSuaChua","MaPhieuSuaChua",Map.of("MaTiepNhan",reception,"NgayLap",now,"TrangThai","MOI_TAO"));
            jdbc.update("INSERT INTO PhanCongKyThuatVien(MaPhieuSuaChua,MaKyThuatVien,NgayPhanCong) VALUES(?,?,?)",order,employee,now);
            serviceId=insert("DichVu","MaDichVu",Map.of("TenDichVu","Kiểm tra phanh","LoaiDichVu","KIEM_TRA","DonGia",new BigDecimal("100000.00")));
            warehouse=insert("Kho","MaKho",Map.of("TenKho","Kho phụ tùng phía sau"));
            part=insert("PhuTung","MaPhuTung",Map.of("MaKho",warehouse,"TenPhuTung","Lọc dầu","DonGia",new BigDecimal("50000.00"),"SoLuongTon",10));
        });
    }
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    void account(String username,String role,Integer customer) {
        var values=new HashMap<String,Object>(Map.of("TenDangNhap",username,"MatKhauHash","unused-sql-it-password","VaiTro",role));
        values.put(customer==null?"MaNhanVien":"MaKhachHang",customer==null?employee:customer);
        accounts.add(insert("TaiKhoan","MaTaiKhoan",values));
    }
    ResultActions call(MockHttpServletRequestBuilder request,String name,String role,Object body) throws Exception {
        request.with(user(name).roles(role));if(body!=null)request.contentType(APPLICATION_JSON).content(json.writeValueAsString(body));
        return mvc.perform(request).andDo(result->{if(result.getResponse().getStatus()>=500)
            throw new AssertionError("Quotation endpoint failed",result.getResolvedException());});
    }
    JsonNode data(ResultActions result)throws Exception {return json.readTree(result.andReturn().getResponse().getContentAsString()).path("data");}
    List<Map<String,Object>> lines(int quantity) {return List.of(Map.of("kind","SERVICE","itemId",serviceId,"quantity",quantity),Map.of("kind","PART","itemId",part,"quantity",1));}
    int create()throws Exception {
        return data(call(post("/api/quotations"),manager,"MANAGER",Map.of("repairOrderId",order,"lines",lines(2)))
            .andExpect(status().isCreated())).path("id").asInt();
    }
    void send(int id,int version)throws Exception {call(post("/api/quotations/"+id+"/send"),manager,"MANAGER",Map.of("version",version)).andExpect(status().isOk());}
    void decide(int id,int version,boolean accepted)throws Exception {
        call(post("/api/quotations/"+id+"/decision"),owner,"CUSTOMER",Map.of("version",version,"accepted",accepted,"reason","Đã xem chi phí"))
            .andExpect(status().isOk());
    }
    int count(String sql,Object...args) {return jdbc.queryForObject(sql,Integer.class,args);}
    @AfterEach void cleanup() {
        if(order==null)return;
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            jdbc.update("DELETE FROM ThongBao WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM BienDongKho WHERE MaPhuTung=?",part);
            jdbc.update("DELETE FROM ChiTietPhieuXuat WHERE MaPhieuXuat IN(SELECT MaPhieuXuat FROM PhieuXuatKho WHERE MaPhieuSuaChua=?)",order);
            jdbc.update("DELETE FROM PhieuXuatKho WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM ChiTietPhuTung WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM LichSuBaoGia WHERE MaBaoGia IN(SELECT MaBaoGia FROM BaoGia WHERE MaPhieuSuaChua=?)",order);
            jdbc.update("DELETE FROM ChiTietBaoGia WHERE MaBaoGia IN(SELECT MaBaoGia FROM BaoGia WHERE MaPhieuSuaChua=?)",order);
            jdbc.update("DELETE FROM BaoGia WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM NhatKySuaChua WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM ChiTietDichVu WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM PhieuSuaChua WHERE MaPhieuSuaChua=?",order);
            jdbc.update("DELETE FROM PhieuTiepNhan WHERE MaTiepNhan=?",reception);
            jdbc.update("DELETE FROM Xe WHERE MaXe=?",vehicle);
            for(int id:accounts)jdbc.update("DELETE FROM TaiKhoan WHERE MaTaiKhoan=?",id);
            jdbc.update("DELETE FROM KyThuatVien WHERE MaNhanVien=?",employee);
            jdbc.update("DELETE FROM NhanVien WHERE MaNhanVien=?",employee);
            for(int id:customers)jdbc.update("DELETE FROM KhachHang WHERE MaKhachHang=?",id);
            jdbc.update("DELETE FROM DichVu WHERE MaDichVu=?",serviceId);
            jdbc.update("DELETE FROM PhuTung WHERE MaPhuTung=?",part);jdbc.update("DELETE FROM Kho WHERE MaKho=?",warehouse);
        });
    }
    @Test void persistenceOwnershipApprovalAndRepairGate()throws Exception {
        int id=create();
        assertEquals(new BigDecimal("250000.00"),jdbc.queryForObject("SELECT TongTien FROM BaoGia WHERE MaBaoGia=?",BigDecimal.class,id));
        assertEquals(10,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
        assertEquals(0,count("SELECT COUNT(*) FROM ChiTietPhuTung WHERE MaPhieuSuaChua=?",order));
        call(get("/api/quotations/"+id),owner,"CUSTOMER",null).andExpect(status().isNotFound());
        send(id,0);
        call(get("/api/quotations/"+id),owner,"CUSTOMER",null).andExpect(status().isOk()).andExpect(jsonPath("$.data.lines.length()").value(2));
        call(get("/api/quotations/"+id),other,"CUSTOMER",null).andExpect(status().isNotFound());
        call(post("/api/quotations/"+id+"/decision"),other,"CUSTOMER",Map.of("version",1,"accepted",true)).andExpect(status().isNotFound());
        call(post("/api/quotations/"+id+"/decision"),manager,"MANAGER",Map.of("version",1,"accepted",true)).andExpect(status().isForbidden());
        var progress=Map.of("expectedStatus","MOI_TAO","status","DANG_SUA","notes","Bắt đầu kiểm tra phanh");
        call(put("/api/repair-orders/"+order+"/progress"),manager,"MANAGER",progress).andExpect(status().isConflict());
        decide(id,1,true);decide(id,1,true);
        assertEquals(3,count("SELECT COUNT(*) FROM LichSuBaoGia WHERE MaBaoGia=?",id));
        assertEquals(accounts.get(0),jdbc.queryForObject("SELECT MaNguoiDuyet FROM BaoGia WHERE MaBaoGia=?",Integer.class,id));
        assertEquals(2,count("SELECT SoLuong FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND MaDichVu=?",order,serviceId));
        call(put("/api/quotations/"+id),manager,"MANAGER",Map.of("version",2,"lines",lines(3))).andExpect(status().isConflict());
        call(put("/api/repair-orders/"+order+"/progress"),manager,"MANAGER",progress).andExpect(status().isOk());
        assertEquals(1,count("SELECT COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua=? AND LoaiThongBao=N'BAO_GIA'",order));
        assertEquals(10,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
    }
    @Test void rejectionRevisionSnapshotsAndStaleDecision()throws Exception {
        int id=create();send(id,0);decide(id,1,false);
        String snapshot=jdbc.queryForObject("SELECT NoiDung FROM LichSuBaoGia WHERE MaBaoGia=? AND PhienBan=2",String.class,id);
        call(post("/api/quotations/"+id+"/revise"),manager,"MANAGER",Map.of("version",2,"reason","Điều chỉnh số lượng"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.revision").value(2));
        call(put("/api/quotations/"+id),manager,"MANAGER",Map.of("version",3,"lines",lines(1))).andExpect(status().isOk());
        send(id,4);
        call(post("/api/quotations/"+id+"/decision"),owner,"CUSTOMER",Map.of("version",1,"accepted",true)).andExpect(status().isConflict());
        decide(id,5,true);
        assertEquals(snapshot,jdbc.queryForObject("SELECT NoiDung FROM LichSuBaoGia WHERE MaBaoGia=? AND PhienBan=2",String.class,id));
        assertEquals(new BigDecimal("150000.00"),jdbc.queryForObject("SELECT TongTien FROM BaoGia WHERE MaBaoGia=?",BigDecimal.class,id));
        assertEquals(7,count("SELECT COUNT(*) FROM LichSuBaoGia WHERE MaBaoGia=?",id));
        call(get("/api/quotations/"+id+"/history"),owner,"CUSTOMER",null).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(4));
        call(get("/api/quotations/"+id+"/history"),other,"CUSTOMER",null).andExpect(status().isNotFound());
    }
    @Test void concurrentOppositeDecisionsCommitOnlyOne()throws Exception {
        int id=create();send(id,0);var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)) {
            List<Future<Integer>> futures=new ArrayList<>();
            for(boolean accepted:new boolean[]{true,false}) futures.add(pool.submit(()->{
                gate.await();return call(post("/api/quotations/"+id+"/decision"),owner,"CUSTOMER",Map.of("version",1,"accepted",accepted))
                    .andReturn().getResponse().getStatus();
            }));
            gate.countDown();var statuses=List.of(futures.get(0).get(20,TimeUnit.SECONDS),futures.get(1).get(20,TimeUnit.SECONDS));
            assertTrue(statuses.contains(200),statuses.toString());assertTrue(statuses.contains(409),statuses.toString());
        }
        assertEquals(3,count("SELECT COUNT(*) FROM LichSuBaoGia WHERE MaBaoGia=?",id));
        assertEquals(2,count("SELECT PhienBan FROM BaoGia WHERE MaBaoGia=?",id));
    }
    @Test void approvedPartQuantityAndPriceGateAllocationAndActualUse()throws Exception {
        int id=create();send(id,0);decide(id,1,true);
        call(put("/api/repair-orders/"+order+"/progress"),manager,"MANAGER",
            Map.of("expectedStatus","MOI_TAO","status","DANG_SUA","notes","Bắt đầu sửa chữa")).andExpect(status().isOk());
        // Catalog changes must never silently replace the customer's agreed price.
        jdbc.update("UPDATE PhuTung SET DonGia=90000.00 WHERE MaPhuTung=?",part);
        call(post("/api/warehouse/exports"),manager,"MANAGER",Map.of("repairOrderId",order,"requestedTechnicianId",employee,
            "reason","Thay lọc dầu","items",List.of(Map.of("partId",part,"quantity",2)))).andExpect(status().isConflict());
        var allocation=Map.of("repairOrderId",order,"requestedTechnicianId",employee,"reason","Thay lọc dầu",
            "items",List.of(Map.of("partId",part,"quantity",1)));
        int issue=data(call(post("/api/warehouse/exports"),manager,"MANAGER",allocation).andExpect(status().isCreated())).path("id").asInt();
        assertEquals(new BigDecimal("50000.00"),jdbc.queryForObject("SELECT DonGia FROM ChiTietPhieuXuat WHERE MaPhieuXuat=? AND MaPhuTung=?",BigDecimal.class,issue,part));
        call(post("/api/warehouse/exports"),manager,"MANAGER",allocation).andExpect(status().isConflict());
        assertEquals(10,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
        call(post("/api/quotations/"+id+"/revise"),manager,"MANAGER",Map.of("version",2,"reason","Xem lại trước khi thực hiện")).andExpect(status().isOk());
        var progress=Map.of("expectedStatus","CHO_SUA","status","DANG_SUA","notes","Kiểm tra phanh");
        call(put("/api/repair-orders/"+order+"/services/"+serviceId+"/progress"),manager,"MANAGER",progress).andExpect(status().isConflict());
        assertThrows(com.gara.quanlygara.exception.ConflictException.class,()->stock.confirmUsage(issue,part,new ConfirmUsageRequest(1,null),employee,true));
        // A revision cannot strand a pending allocation with a different agreed price or missing line.
        call(put("/api/quotations/"+id),manager,"MANAGER",Map.of("version",3,"lines",List.of(
            Map.of("kind","SERVICE","itemId",serviceId,"quantity",2),
            Map.of("kind","PART","itemId",part,"quantity",1,"unitPrice",60000))))
            .andExpect(status().isConflict());
        call(put("/api/quotations/"+id),manager,"MANAGER",Map.of("version",3,"lines",List.of(
            Map.of("kind","SERVICE","itemId",serviceId,"quantity",2))))
            .andExpect(status().isConflict());
        assertEquals(3,count("SELECT PhienBan FROM BaoGia WHERE MaBaoGia=?",id));
        send(id,3);decide(id,4,true);
        call(put("/api/repair-orders/"+order+"/services/"+serviceId+"/progress"),manager,"MANAGER",progress).andExpect(status().isOk());
        stock.confirmUsage(issue,part,new ConfirmUsageRequest(1,null),employee,true);
        assertEquals(9,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
        assertEquals(1,count("SELECT SoLuong FROM ChiTietPhuTung WHERE MaPhieuSuaChua=? AND MaPhuTung=?",order,part));
        assertEquals(new BigDecimal("50000.00"),jdbc.queryForObject("SELECT DonGia FROM ChiTietPhuTung WHERE MaPhieuSuaChua=? AND MaPhuTung=?",BigDecimal.class,order,part));
        assertThrows(com.gara.quanlygara.exception.ConflictException.class,()->stock.confirmUsage(issue,part,new ConfirmUsageRequest(1,null),employee,true));
        assertEquals(1,count("SELECT COUNT(*) FROM BienDongKho WHERE MaPhuTung=?",part));
    }
    @Test void validationAndRoleChecksDoNotWriteInvalidQuotes()throws Exception {
        call(post("/api/quotations"),owner,"CUSTOMER",Map.of("repairOrderId",order,"lines",lines(1))).andExpect(status().isForbidden());
        call(post("/api/quotations"),manager,"MANAGER",Map.of("repairOrderId",order,"lines",List.of(Map.of("kind","SERVICE","itemId",serviceId,"quantity",0))))
            .andExpect(status().isBadRequest());
        call(post("/api/quotations"),manager,"MANAGER",Map.of("repairOrderId",order,"lines",List.of(Map.of("kind","SERVICE","itemId",serviceId,"quantity",1,"unitPrice",-1))))
            .andExpect(status().isBadRequest());
        assertEquals(0,count("SELECT COUNT(*) FROM BaoGia WHERE MaPhieuSuaChua=?",order));
    }
    @Test void pricesMustBeWholeThousandsAndInvalidWritesAreAtomic() throws Exception {
        for (BigDecimal price : List.of(new BigDecimal("100001"), new BigDecimal("100000.50"))) {
            var serviceBody=Map.of("name","Kiểm tra phanh","type","KIEM_TRA","unitPrice",price);
            call(post("/api/services"),manager,"MANAGER",serviceBody).andExpect(status().isBadRequest());
            call(put("/api/services/"+serviceId),manager,"MANAGER",serviceBody).andExpect(status().isBadRequest());
            var partBody=Map.of("warehouseId",warehouse,"name","Lọc dầu","unitPrice",price,"minStockLevel",0);
            call(post("/api/spare-parts"),manager,"MANAGER",partBody).andExpect(status().isBadRequest());
            call(put("/api/spare-parts/"+part),manager,"MANAGER",partBody).andExpect(status().isBadRequest());
            call(post("/api/quotations"),manager,"MANAGER",Map.of("repairOrderId",order,"lines",List.of(
                Map.of("kind","SERVICE","itemId",serviceId,"quantity",1,"unitPrice",price))))
                .andExpect(status().isBadRequest());
            call(post("/api/warehouse/imports"),manager,"MANAGER",Map.of("supplier","Phụ tùng Thành Phát",
                "items",List.of(Map.of("partId",part,"quantity",1,"unitPrice",price))))
                .andExpect(status().isBadRequest());
        }
        assertEquals(new BigDecimal("100000.00"),jdbc.queryForObject("SELECT DonGia FROM DichVu WHERE MaDichVu=?",BigDecimal.class,serviceId));
        assertEquals(new BigDecimal("50000.00"),jdbc.queryForObject("SELECT DonGia FROM PhuTung WHERE MaPhuTung=?",BigDecimal.class,part));
        assertEquals(10,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
        assertEquals(0,count("SELECT COUNT(*) FROM BaoGia WHERE MaPhieuSuaChua=?",order));
        assertEquals(0,count("SELECT COUNT(*) FROM BienDongKho WHERE MaPhuTung=?",part));
        // A legacy catalog price cannot silently enter a new quotation through default pricing.
        jdbc.update("UPDATE DichVu SET DonGia=100001 WHERE MaDichVu=?",serviceId);
        call(post("/api/quotations"),manager,"MANAGER",Map.of("repairOrderId",order,"lines",lines(1)))
            .andExpect(status().isBadRequest());
        call(put("/api/services/"+serviceId),manager,"MANAGER",Map.of("name","Kiểm tra phanh","unitPrice",100000))
            .andExpect(status().isOk());
        call(put("/api/spare-parts/"+part),manager,"MANAGER",Map.of("warehouseId",warehouse,"name","Lọc dầu","unitPrice",50000))
            .andExpect(status().isOk());
        int id=create();
        call(put("/api/quotations/"+id),manager,"MANAGER",Map.of("version",0,"lines",List.of(
            Map.of("kind","SERVICE","itemId",serviceId,"quantity",1,"unitPrice",100001))))
            .andExpect(status().isBadRequest());
        assertEquals(0,count("SELECT PhienBan FROM BaoGia WHERE MaBaoGia=?",id));
        // Sending an old odd-priced draft requires an explicit price correction, not display rounding.
        jdbc.update("UPDATE ChiTietBaoGia SET DonGia=100001 WHERE MaBaoGia=? AND MaDichVu=?",id,serviceId);
        call(post("/api/quotations/"+id+"/send"),manager,"MANAGER",Map.of("version",0)).andExpect(status().isBadRequest());
        assertEquals("NHAP",jdbc.queryForObject("SELECT TrangThai FROM BaoGia WHERE MaBaoGia=?",String.class,id));
    }
    @Test void legacySqlProcedureCannotBypassApprovedQuantityAndRollsBackStock()throws Exception {
        int id=create();send(id,0);decide(id,1,true);
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai=N'DANG_SUA' WHERE MaPhieuSuaChua=?",order);
        int issue=insert("PhieuXuatKho","MaPhieuXuat",Map.of("MaPhieuSuaChua",order,"MaNhanVienKho",employee,
            "NgayXuat",Timestamp.valueOf(LocalDateTime.now()),"LyDo","Cấp phát lọc dầu"));
        jdbc.update("INSERT INTO ChiTietPhieuXuat(MaPhieuXuat,MaPhuTung,SoLuong,DonGia) VALUES(?,?,2,50000.00)",issue,part);
        assertThrows(org.springframework.dao.DataAccessException.class,()->
            jdbc.update("EXEC dbo.sp_XacNhanSuDungPhuTung ?,?,?,?",issue,part,employee,2));
        assertEquals(10,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
        assertEquals(0,count("SELECT COUNT(*) FROM ChiTietPhieuXuat WHERE MaPhieuXuat=? AND DaXacNhanSuDung=1",issue));
        assertEquals(0,count("SELECT COUNT(*) FROM BienDongKho WHERE MaPhuTung=?",part));
        jdbc.update("EXEC dbo.sp_XacNhanSuDungPhuTung ?,?,?,?",issue,part,employee,1);
        assertEquals(9,count("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",part));
        assertEquals(1,count("SELECT SoLuongHoanTra FROM ChiTietPhieuXuat WHERE MaPhieuXuat=?",issue));
    }
}
