package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.appointment.AppointmentDtos.*;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.AppointmentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@Service
@Transactional(readOnly = true)
public class AppointmentService {
    private final AppointmentRepository repository;
    private final Clock clock;
    @org.springframework.beans.factory.annotation.Autowired
    public AppointmentService(AppointmentRepository repository) {
        this(repository, Clock.system(ZoneId.of("Asia/Ho_Chi_Minh")));
    }
    AppointmentService(AppointmentRepository repository, Clock clock) { this.repository = repository; this.clock = clock; }
    private Integer customerScope(Account actor) {
        if (actor.getRole() != AccountRole.CUSTOMER) return null;
        if (actor.getCustomerId() == null) throw new ForbiddenException("Tài khoản chưa liên kết khách hàng.");
        return actor.getCustomerId();
    }
    public List<View> list(Account actor) { return repository.list(customerScope(actor)); }
    public View get(int id, Account actor) {
        View item = repository.get(id);
        Integer scope = customerScope(actor);
        if (scope != null && scope != item.customerId()) throw new ResourceNotFoundException("Không tìm thấy lịch hẹn.");
        return item;
    }
    public List<Audit> history(int id, Account actor) { get(id, actor); return repository.history(id); }
    public List<Schedule> schedule() { return repository.schedule(); }
    public Availability availability(LocalDate date) {
        var configured = repository.schedule().stream().filter(s -> s.dayOfWeek() == date.getDayOfWeek().getValue()).toList();
        var slots = configured.stream().filter(s -> s.capacity() > 0 && date.atTime(s.time()).isAfter(LocalDateTime.now(clock)))
            .map(s -> new Slot(s.time(),s.capacity(),Math.max(0,s.capacity()-repository.occupied(date,s.time(),0)))).toList();
        return new Availability(date, !configured.isEmpty(), slots);
    }
    @Transactional
    public List<Schedule> configure(Schedule slot, Account actor) {
        requireMinute(slot.time());
        repository.lockBooking();
        repository.saveSchedule(slot, actor.getId());
        return schedule();
    }
    @Transactional
    public View create(Create input, Account actor) {
        repository.lockBooking();
        Integer owner = repository.activeVehicleOwner(input.vehicleId());
        if (owner == null || (customerScope(actor) != null && !Objects.equals(owner, actor.getCustomerId())))
            throw new ResourceNotFoundException("Không tìm thấy xe thuộc khách hàng đang hoạt động.");
        if (input.serviceId() != null && !repository.activeService(input.serviceId()))
            throw new BadRequestException("Dịch vụ không tồn tại hoặc đã ngừng cung cấp.");
        checkSlot(input.vehicleId(), input.date(), input.time(), 0);
        View created = repository.get(repository.create(input, owner));
        repository.audit(created, actor.getId(), "TAO", input.note());
        return created;
    }
    @Transactional
    public View move(int id, Move input, Account actor) {
        repository.lockBooking();
        View item = get(id, actor);
        mutable(item, input.version());
        checkSlot(item.vehicleId(), input.date(), input.time(), id);
        repository.update(id, input.version(), input.date(), input.time(), "CHO_XAC_NHAN");
        View updated = repository.get(id);
        repository.audit(updated, actor.getId(), "DOI_LICH", input.reason());
        return updated;
    }
    @Transactional
    public View cancel(int id, Change input, Account actor) {
        repository.lockBooking();
        View item = get(id, actor);
        if (Set.of("HUY", "DA_HUY").contains(item.status())) return item;
        mutable(item,input.version());
        return change(item, input, actor, "HUY", "HUY");
    }
    @Transactional
    public View confirm(int id, Change input, Account actor) {
        repository.lockBooking();
        View item = get(id,actor);
        if (item.status().equals("DA_XAC_NHAN")) return item;
        mutable(item,input.version());
        if (!item.date().atTime(item.time()).isAfter(LocalDateTime.now(clock)))
            throw new BadRequestException("Không thể xác nhận lịch trong quá khứ.");
        return change(item,input,actor,"DA_XAC_NHAN","XAC_NHAN");
    }
    private View change(View item, Change input, Account actor, String state, String action) {
        repository.update(item.id(),input.version(),item.date(),item.time(),state);
        View updated = repository.get(item.id());
        repository.audit(updated,actor.getId(),action,input.reason());
        return updated;
    }
    private void mutable(View item, int version) {
        if (item.version()!=version) throw new ConflictException("Lịch đã thay đổi. Vui lòng tải lại.");
        if (!Set.of("CHO_XAC_NHAN","DA_XAC_NHAN").contains(item.status()))
            throw new ConflictException("Chỉ có thể thay đổi lịch chưa tiếp nhận và chưa hủy.");
    }
    private void requireMinute(LocalTime time) {
        if (time.getSecond()!=0 || time.getNano()!=0) throw new BadRequestException("Khung giờ phải chính xác đến phút.");
    }
    private void checkSlot(int vehicleId, LocalDate date, LocalTime time, int excludedId) {
        requireMinute(time);
        if (!date.atTime(time).isAfter(LocalDateTime.now(clock))) throw new BadRequestException("Không thể đặt lịch trong quá khứ.");
        int capacity = repository.schedule().stream()
            .filter(s -> s.dayOfWeek()==date.getDayOfWeek().getValue() && s.time().equals(time))
            .mapToInt(Schedule::capacity).findFirst().orElse(0);
        if (capacity<=0) throw new ConflictException("Gara chưa mở khung giờ này. Vui lòng chọn giờ khác.");
        if (repository.duplicateVehicle(vehicleId,date,time,excludedId)) throw new ConflictException("Xe đã có lịch trong khung giờ này.");
        if (repository.occupied(date,time,excludedId)>=capacity) throw new ConflictException("Khung giờ vừa hết chỗ. Vui lòng chọn giờ khác.");
    }
}
