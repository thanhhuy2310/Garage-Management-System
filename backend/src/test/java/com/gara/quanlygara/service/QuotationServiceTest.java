package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.quotation.QuotationDtos.*;
import com.gara.quanlygara.entity.*;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.QuotationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class QuotationServiceTest {
    QuotationRepository repo=mock(QuotationRepository.class);
    RepairBusinessRules rules=mock(RepairBusinessRules.class);
    QuotationService service=new QuotationService(repo,rules);
    Account customer=new Account(),staff=new Account();
    Line line=new Line(1,Kind.SERVICE,3,"Kiểm tra phanh",2,new BigDecimal("100000.00"),new BigDecimal("200000.00"));
    LineInput input=new LineInput(Kind.SERVICE,3,2,null);
    @BeforeEach void setup() {
        customer.setId(2);customer.setCustomerId(7);customer.setRole(AccountRole.CUSTOMER);
        staff.setId(4);staff.setRole(AccountRole.MANAGER);
    }
    View view(String state,int version) {
        return new View(1,10,7,"Nguyễn Minh Anh",8,"51A-12345","Toyota","Vios",2021,1000,
            version,1,state,LocalDateTime.of(2026,10,30,8,0),null,null,4,
            List.of("DA_XAC_NHAN","KHONG_DONG_Y").contains(state)?2:null,null,line.amount(),List.of(line));
    }
    @Test void foreignCustomerCannotReadOrApprove() {
        when(repo.get(1)).thenReturn(view("CHO_XAC_NHAN",1));customer.setCustomerId(99);
        assertThrows(ResourceNotFoundException.class,()->service.get(1,customer));
        assertThrows(ResourceNotFoundException.class,()->service.decide(1,new Decision(1,true,null),customer));
        verify(repo,never()).advance(any(),any(),anyBoolean(),any(),any(),any());
    }
    @Test void draftIsNotVisibleToCustomer() {
        when(repo.get(1)).thenReturn(view("NHAP",0));
        assertThrows(ResourceNotFoundException.class,()->service.get(1,customer));
    }
    @Test void customerWithoutLinkCannotFallBackToStaffList() {
        customer.setCustomerId(null);assertThrows(ForbiddenException.class,()->service.list(customer));
        verify(repo,never()).list(any());
    }
    @Test void acceptedContentCannotBeEditedInPlace() {
        when(repo.get(1)).thenReturn(view("DA_XAC_NHAN",2));
        assertThrows(ConflictException.class,()->service.edit(1,new Edit(2,List.of(input)),staff));
        verify(repo,never()).replaceLines(anyInt(),any());
    }
    @Test void staleEditDoesNotOverwrite() {
        when(repo.get(1)).thenReturn(view("NHAP",3));
        assertThrows(ConflictException.class,()->service.edit(1,new Edit(0,List.of(input)),staff));
        verify(repo,never()).replaceLines(anyInt(),any());
    }
    @Test void duplicateItemsRejectedBeforeWritingQuote() {
        assertThrows(BadRequestException.class,()->service.create(new Create(10,List.of(input,input)),staff));
        verify(repo,never()).create(anyInt(),anyInt(),any());
    }
    @Test void serverPricesAndAuditsCreatedQuote() {
        when(repo.priced(input)).thenReturn(line);when(repo.create(eq(10),eq(4),any())).thenReturn(1);
        when(repo.get(1)).thenReturn(view("NHAP",0));
        assertEquals(new BigDecimal("200000.00"),service.create(new Create(10,List.of(input)),staff).total());
        var order=inOrder(rules,repo);order.verify(rules).lock(10);
        order.verify(repo).create(eq(10),eq(4),any());order.verify(repo).replaceLines(1,List.of(line));
        order.verify(repo).audit(any(),eq(4),eq("TAO"),isNull());
    }
    @Test void revisionPreservesAcceptedSnapshotBeforeChangingState() {
        View accepted=view("DA_XAC_NHAN",2),draft=view("NHAP",3);
        when(repo.get(1)).thenReturn(accepted,accepted,draft);
        assertEquals("NHAP",service.revise(1,new Change(2,"Bổ sung kiểm tra"),staff).status());
        var order=inOrder(repo);order.verify(repo).preserveLegacy(accepted);
        order.verify(repo).advance(eq(accepted),eq("NHAP"),eq(true),isNull(),isNull(),any());
        order.verify(repo).audit(eq(draft),eq(4),eq("DIEU_CHINH"),eq("Bổ sung kiểm tra"));
        verify(repo,never()).replaceLines(anyInt(),any());
    }
    @Test void revisionRequiresReason() {
        when(repo.get(1)).thenReturn(view("KHONG_DONG_Y",2));
        assertThrows(BadRequestException.class,()->service.revise(1,new Change(2," "),staff));
    }
    @Test void sendNotifiesOnlyAfterPersistingPendingState() {
        View draft=view("NHAP",0),sent=view("CHO_XAC_NHAN",1);
        when(repo.get(1)).thenReturn(draft,draft,sent);
        service.send(1,new Change(0,null),staff);
        var order=inOrder(repo);order.verify(repo).advance(eq(draft),eq("CHO_XAC_NHAN"),eq(false),isNull(),isNull(),any());
        order.verify(repo).audit(eq(sent),eq(4),eq("GUI"),isNull());order.verify(repo).notifyCustomer(sent);
    }
    @Test void acceptanceSyncsServicesAndRepeatedDecisionDoesNotDuplicate() {
        View pending=view("CHO_XAC_NHAN",1),accepted=view("DA_XAC_NHAN",2);
        when(repo.get(1)).thenReturn(pending,pending,accepted,accepted,accepted);
        service.decide(1,new Decision(1,true,null),customer);
        service.decide(1,new Decision(1,true,null),customer);
        verify(repo,times(1)).syncApprovedServices(accepted);
        verify(repo,times(1)).audit(eq(accepted),eq(2),eq("CHAP_THUAN"),isNull());
    }
    @Test void oldApprovalCannotApproveAnotherRevision() {
        when(repo.get(1)).thenReturn(view("CHO_XAC_NHAN",5));
        assertThrows(ConflictException.class,()->service.decide(1,new Decision(1,true,null),customer));
        verify(repo,never()).syncApprovedServices(any());
    }
    @Test void rejectionKeepsReasonAndDoesNotAddRepairWork() {
        View pending=view("CHO_XAC_NHAN",1),rejected=view("KHONG_DONG_Y",2);
        when(repo.get(1)).thenReturn(pending,pending,rejected);
        service.decide(1,new Decision(1,false,"Cần xem lại chi phí"),customer);
        verify(repo).advance(eq(pending),eq("KHONG_DONG_Y"),eq(false),eq(2),eq("Cần xem lại chi phí"),any());
        verify(repo,never()).syncApprovedServices(any());
    }
}
