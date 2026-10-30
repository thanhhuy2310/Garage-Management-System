package com.gara.quanlygara.service;

import com.gara.quanlygara.validation.PriceRules;

import com.gara.quanlygara.dto.quotation.QuotationDtos.*;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.QuotationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

@Service
@Transactional(readOnly=true)
public class QuotationService {
    private final QuotationRepository repository;
    private final RepairBusinessRules rules;
    public QuotationService(QuotationRepository repository,RepairBusinessRules rules) {
        this.repository=repository;this.rules=rules;
    }
    private Integer scope(Account actor) {
        if(actor.getRole()!=AccountRole.CUSTOMER) return null;
        if(actor.getCustomerId()==null) throw new ForbiddenException("Tài khoản chưa liên kết khách hàng.");
        return actor.getCustomerId();
    }
    public List<View> list(Account actor) { return repository.list(scope(actor)); }
    public View get(int id,Account actor) {
        View item=repository.get(id); Integer owner=scope(actor);
        if(owner!=null && (owner!=item.customerId() || "NHAP".equals(item.status())))
            throw new ResourceNotFoundException("Không tìm thấy báo giá.");
        return item;
    }
    public List<Audit> history(int id,Account actor) {
        // Owners may still read sent snapshots while a replacement draft is being prepared.
        View item=repository.get(id); Integer owner=scope(actor);
        if(owner!=null && owner!=item.customerId()) throw new ResourceNotFoundException("Không tìm thấy báo giá.");
        return repository.history(id).stream().filter(a->owner==null || !"NHAP".equals(a.snapshot().status())).toList();
    }
    private View locked(int id,int version,Account actor) {
        View first=get(id,actor);
        rules.lock(first.repairOrderId());
        View current=get(id,actor);
        if(current.version()!=version) throw new ConflictException("Báo giá đã thay đổi. Vui lòng tải lại trước khi thao tác.");
        repository.requireOpenOrder(current.repairOrderId());
        repository.preserveLegacy(current);
        return current;
    }
    private List<Line> priced(int orderId,List<LineInput> input) {
        Set<String> seen=new HashSet<>();
        for(LineInput line:input) if(!seen.add(line.kind()+":"+line.itemId()))
            throw new BadRequestException("Không chọn trùng hạng mục trong báo giá.");
        List<Line> lines=input.stream().map(repository::priced).toList();
        BigDecimal total=lines.stream().map(Line::amount).reduce(BigDecimal.ZERO,BigDecimal::add);
        if(total.compareTo(new BigDecimal("9999999999999999.99"))>0)
            throw new BadRequestException("Tổng báo giá vượt giới hạn lưu trữ.");
        repository.requirePerformedLinesUnchanged(orderId,lines);
        return lines;
    }
    @Transactional
    public View create(Create input,Account actor) {
        rules.lock(input.repairOrderId()); repository.requireOpenOrder(input.repairOrderId());
        if(repository.existsForOrder(input.repairOrderId()))
            throw new ConflictException("Phiếu đã có báo giá. Hãy sửa bản nháp hoặc tạo lần điều chỉnh.");
        List<Line> lines=priced(input.repairOrderId(),input.lines());
        int id=repository.create(input.repairOrderId(),actor.getId(),now());
        repository.replaceLines(id,lines);
        View item=repository.get(id); repository.audit(item,actor.getId(),"TAO",null); return item;
    }
    @Transactional
    public View edit(int id,Edit input,Account actor) {
        View item=locked(id,input.version(),actor);
        if(!"NHAP".equals(item.status())) throw new ConflictException("Chỉ sửa nội dung bản nháp. Báo giá đã gửi cần tạo lần điều chỉnh.");
        List<Line> lines=priced(item.repairOrderId(),input.lines());
        repository.replaceLines(id,lines);
        return change(item,actor,"NHAP",false,null,"SUA",null);
    }
    @Transactional
    public View send(int id,Change input,Account actor) {
        View item=locked(id,input.version(),actor);
        if(!"NHAP".equals(item.status())) throw new ConflictException("Chỉ gửi bản nháp để khách xác nhận.");
        if(item.lines().isEmpty()) throw new BadRequestException("Báo giá phải có ít nhất một hạng mục.");
        item.lines().forEach(line -> PriceRules.requireWholeThousand(line.unitPrice()));
        repository.requirePerformedLinesUnchanged(item.repairOrderId(),item.lines());
        View sent=change(item,actor,"CHO_XAC_NHAN",false,null,"GUI",input.reason());
        repository.notifyCustomer(sent); return sent;
    }
    @Transactional
    public View revise(int id,Change input,Account actor) {
        View item=locked(id,input.version(),actor);
        if(!Set.of("CHO_XAC_NHAN","DA_XAC_NHAN","KHONG_DONG_Y").contains(item.status()))
            throw new ConflictException("Báo giá đang là bản nháp, hãy chỉnh sửa trực tiếp.");
        if(input.reason()==null || input.reason().isBlank()) throw new BadRequestException("Cần ghi lý do điều chỉnh báo giá.");
        return change(item,actor,"NHAP",true,null,"DIEU_CHINH",input.reason());
    }
    @Transactional
    public View decide(int id,Decision input,Account actor) {
        // A repeated decision is idempotent only for the immediately preceding
        // version of this revision. An old request can never approve a new revision.
        View first=get(id,actor);rules.lock(first.repairOrderId());View item=get(id,actor);
        String state=input.accepted()?"DA_XAC_NHAN":"KHONG_DONG_Y";
        if(state.equals(item.status()) && Objects.equals(item.decidedBy(),actor.getId()) &&
            (input.version()==item.version() || input.version()==item.version()-1)) return item;
        if(item.version()!=input.version()) throw new ConflictException("Báo giá đã thay đổi. Vui lòng tải lại để xem nội dung mới.");
        repository.requireOpenOrder(item.repairOrderId());
        if(!"CHO_XAC_NHAN".equals(item.status())) throw new ConflictException("Báo giá không còn chờ xác nhận.");
        repository.preserveLegacy(item);
        repository.requirePerformedLinesUnchanged(item.repairOrderId(),item.lines());
        View decided=change(item,actor,state,false,actor.getId(),input.accepted()?"CHAP_THUAN":"TU_CHOI",input.reason());
        if(input.accepted()) repository.syncApprovedServices(decided);
        return decided;
    }
    private View change(View item,Account actor,String state,boolean revision,Integer decidedBy,String action,String reason) {
        repository.advance(item,state,revision,decidedBy,"KHONG_DONG_Y".equals(state)?reason:null,now());
        View updated=repository.get(item.id());repository.audit(updated,actor.getId(),action,reason);return updated;
    }
    private LocalDateTime now() { return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).withNano(0); }
}
