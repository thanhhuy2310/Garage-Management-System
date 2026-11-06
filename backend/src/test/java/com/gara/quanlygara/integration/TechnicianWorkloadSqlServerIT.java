package com.gara.quanlygara.integration;

import com.gara.quanlygara.service.TechnicianAssignmentService;
import com.gara.quanlygara.service.TechnicianWorkloadService;
import com.gara.quanlygara.dto.technician.TechnicianAssignmentRequest;
import com.gara.quanlygara.exception.ConflictException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@Transactional
class TechnicianWorkloadSqlServerIT {
    @Autowired JdbcTemplate jdbc;
    @Autowired TechnicianAssignmentService assignments;
    @Autowired TechnicianWorkloadService workload;
    private int id(String sql,Object...args){return jdbc.queryForObject(sql,Integer.class,args);}
    @Test void persistsSchedulesCountsDistinctWorkAndReleasesCompletedOrders() {
        assertEquals("QuanLyGaraOTo_Verify_20261029",jdbc.queryForObject("SELECT DB_NAME()",String.class));
        int employee=id("INSERT INTO NhanVien(HoTen,ChucVu) OUTPUT INSERTED.MaNhanVien VALUES (N'Nguyễn Minh Quang',N'Kỹ thuật viên')");
        jdbc.update("INSERT INTO KyThuatVien(MaNhanVien) VALUES (?)",employee);
        int shift=id("INSERT INTO CaLamKyThuatVien(TenCa,BatDau,KetThuc) OUTPUT INSERTED.Id VALUES (N'Ca kiểm thử','00:00','23:59:59')");
        LocalDate date=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        workload.saveSchedule(employee,new TechnicianWorkloadService.ScheduleRequest(date,List.of(shift),2));
        assertTrue(workload.list(date).stream().filter(t->t.id()==employee).findFirst().orElseThrow().assignable());
        int customer=id("INSERT INTO KhachHang(HoTen,SoDienThoai) OUTPUT INSERTED.MaKhachHang VALUES (N'Nguyễn Minh Quang',?)",UUID.randomUUID().toString().substring(0,20));
        List<Integer> orders=new ArrayList<>();
        for(int n=0;n<3;n++) {
            int car=id("INSERT INTO Xe(MaKhachHang,BienSo) OUTPUT INSERTED.MaXe VALUES (?,?)",customer,UUID.randomUUID().toString().substring(0,15));
            int reception=id("INSERT INTO PhieuTiepNhan(MaXe,NgayTiepNhan) OUTPUT INSERTED.MaTiepNhan VALUES (?,SYSDATETIME())",car);
            orders.add(id("SET NOCOUNT ON; DECLARE @Ids TABLE(Id int); INSERT INTO PhieuSuaChua(MaTiepNhan,NgayLap,TrangThai) OUTPUT INSERTED.MaPhieuSuaChua INTO @Ids VALUES (?,SYSDATETIME(),N'MOI_TAO'); SELECT Id FROM @Ids;",reception));
        }
        var request=new TechnicianAssignmentRequest(employee,null);
        assignments.assign(orders.get(0),request); assignments.assign(orders.get(1),request);
        var full=workload.list(date).stream().filter(t->t.id()==employee).findFirst().orElseThrow();
        assertEquals(2,full.activeVehicles()); assertEquals("Đang bận",full.status()); assertFalse(full.assignable());
        // Read the guard directly: throwing through a transactional assignment proxy would
        // mark this rollback-only fixture before the remaining assertions run.
        assertThrows(ConflictException.class,()->workload.requireAssignable(employee));
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai=N'HUY' WHERE MaPhieuSuaChua=?",orders.get(0));
        assignments.assign(orders.get(2),request);
        workload.saveSchedule(employee,new TechnicianWorkloadService.ScheduleRequest(date,List.of(),2));
        assertThrows(ConflictException.class,()->workload.requireAssignable(employee));
    }
}
