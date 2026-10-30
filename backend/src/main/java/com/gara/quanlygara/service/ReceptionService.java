package com.gara.quanlygara.service;
import com.gara.quanlygara.dto.reception.*;
import com.gara.quanlygara.entity.*;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;

@Service
public class ReceptionService {
    private final ReceptionRepository receptions;
    private final VehicleRepository vehicles;
    private final CustomerRepository customers;
    private final RepairOrderRepository orders;
    private final AppointmentRepository appointments;
    public ReceptionService(ReceptionRepository receptions, VehicleRepository vehicles, CustomerRepository customers,
                            RepairOrderRepository orders, AppointmentRepository appointments) {
        this.receptions=receptions; this.vehicles=vehicles; this.customers=customers;
        this.orders=orders; this.appointments=appointments;
    }
    @Transactional(readOnly=true)
    public List<ReceptionResponse> list() { return receptions.overview(0).stream().map(this::response).toList(); }
    @Transactional(readOnly=true)
    public ReceptionResponse get(int id) {
        return receptions.overview(id).stream().findFirst().map(this::response)
            .orElseThrow(()->new ResourceNotFoundException("Không tìm thấy phiếu tiếp nhận."));
    }
    @Transactional
    public ReceptionResponse create(ReceptionRequest input, Account actor) {
        requireEmployee(actor);
        // Share the booking transaction lock so cancellation/rescheduling cannot race reception.
        appointments.lockBooking();
        Vehicle vehicle=vehicles.findForUpdate(input.vehicleId())
            .orElseThrow(()->new ResourceNotFoundException("Không tìm thấy xe."));
        if(!Objects.equals(vehicle.getCustomerId(),input.customerId()))
            throw new BadRequestException("Xe không thuộc khách hàng đã chọn.");
        var customer=customers.findById(input.customerId())
            .orElseThrow(()->new ResourceNotFoundException("Không tìm thấy khách hàng."));
        if(!customer.isActive()) throw new BadRequestException("Khách hàng đã ngừng hoạt động.");
        if(input.appointmentId()!=null) {
            var appointment=appointments.get(input.appointmentId());
            if(appointment.vehicleId()!=vehicle.getId() || appointment.customerId()!=input.customerId())
                throw new BadRequestException("Lịch hẹn không khớp xe và khách hàng.");
            if(!"DA_XAC_NHAN".equals(appointment.status()) || receptions.existsByAppointmentId(appointment.id()))
                throw new ConflictException("Lịch hẹn phải được xác nhận và chưa tiếp nhận.");
            if(appointment.date().isAfter(now().toLocalDate()))
                throw new BadRequestException("Chưa đến ngày của lịch hẹn. Hãy dời lịch trước khi tiếp nhận.");
        }
        if(receptions.countOpenForVehicle(vehicle.getId())>0)
            throw new ConflictException("Xe đang có phiếu tiếp nhận hoặc sửa chữa chưa kết thúc. Hãy mở phiếu hiện có.");
        InsuranceReception reception=new InsuranceReception();
        reception.setVehicleId(vehicle.getId()); reception.setAppointmentId(input.appointmentId());
        reception.setReceivedAt(now()); reception.setReceivedBy(actor.getEmployeeId());
        apply(reception,vehicle,input.mileage(),input.initialCondition(),input.customerRequest(),input.notes());
        reception=receptions.saveAndFlush(reception);
        if(input.appointmentId()!=null) {
            var appointment=appointments.get(input.appointmentId());
            appointments.update(appointment.id(),appointment.version(),appointment.date(),appointment.time(),"DA_DEN");
            appointments.audit(appointments.get(appointment.id()),actor.getId(),"TIEP_NHAN","Phiếu tiếp nhận #"+reception.getId());
        }
        return get(reception.getId());
    }
    @Transactional
    public ReceptionResponse update(int id, ReceptionUpdateRequest input, Account actor) {
        requireEmployee(actor); appointments.lockBooking();
        var reception=receptions.findForUpdate(id)
            .orElseThrow(()->new ResourceNotFoundException("Không tìm thấy phiếu tiếp nhận."));
        if(reception.getVersion()!=input.version()) throw new ConflictException("Phiếu đã thay đổi. Vui lòng tải lại.");
        if(orders.existsByReceptionId(id)) throw new ConflictException("Phiếu đã lập sửa chữa, không sửa lại thông tin tiếp nhận.");
        var vehicle=vehicles.findForUpdate(reception.getVehicleId()).orElseThrow();
        apply(reception,vehicle,input.mileage(),input.initialCondition(),input.customerRequest(),input.notes());
        receptions.saveAndFlush(reception);
        return get(id);
    }
    private void apply(InsuranceReception reception,Vehicle vehicle,Integer mileage,String condition,String request,String notes) {
        if(mileage!=null && vehicle.getMileage()!=null && mileage<vehicle.getMileage())
            throw new BadRequestException("Số km tiếp nhận không được nhỏ hơn số km đang lưu của xe.");
        reception.setMileage(mileage==null?vehicle.getMileage():mileage);
        if(mileage!=null) vehicle.setMileage(mileage);
        reception.setInitialCondition(condition.strip()); reception.setCustomerRequest(request.strip());
        reception.setNotes(notes==null||notes.isBlank()?null:notes.strip()); reception.setUpdatedAt(now());
    }
    private void requireEmployee(Account actor) {
        if(actor.getEmployeeId()==null) throw new BadRequestException("Tài khoản chưa liên kết nhân viên tiếp nhận.");
    }
    private LocalDateTime now() { return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).withNano(0); }
    private ReceptionResponse response(ReceptionRepository.Overview r) {
        return new ReceptionResponse(r.getId(),r.getVehicleId(),r.getCustomerId(),r.getCustomerName(),r.getLicensePlate(),
            r.getAppointmentId(),r.getMileage(),r.getInitialCondition(),r.getCustomerRequest(),r.getNotes(),r.getReceivedAt(),
            r.getUpdatedAt(),r.getReceivedBy(),r.getVersion(),r.getRepairOrderId(),r.getRepairStatus());
    }
}
