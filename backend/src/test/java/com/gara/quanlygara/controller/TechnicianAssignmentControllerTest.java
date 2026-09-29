package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.Employee;
import com.gara.quanlygara.entity.RepairOrder;
import com.gara.quanlygara.entity.Technician;
import com.gara.quanlygara.entity.TechnicianAssignment;
import com.gara.quanlygara.entity.TechnicianAssignmentId;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.TechnicianAssignmentRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import com.gara.quanlygara.security.JwtService;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.test.context.support.WithMockUser;

import java.time.LocalDateTime;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TechnicianAssignmentControllerTest extends ApiTestSupport {

    @Autowired private EmployeeRepository employeeRepository;
    @Autowired private TechnicianRepository technicianRepository;
    @Autowired private RepairOrderRepository repairOrderRepository;
    @Autowired private TechnicianAssignmentRepository assignmentRepository;
    @Autowired private AccountRepository accountRepository;
    @Autowired private JwtService jwtService;
    @Autowired private EntityManager entityManager;

    private Employee firstTechnician;
    private Employee secondTechnician;
    private Employee receptionist;
    private RepairOrder firstOrder;
    private RepairOrder secondOrder;

    @BeforeEach
    void setUp() {
        firstTechnician = saveEmployee("Kỹ thuật viên A", true);
        secondTechnician = saveEmployee("Kỹ thuật viên B", true);
        receptionist = saveEmployee("Lễ tân", false);
        firstOrder = saveOrder(1);
        secondOrder = saveOrder(2);
    }

    @ParameterizedTest
    @ValueSource(strings = {"ADMIN", "MANAGER"})
    void managerRolesCanListAndAssignMultipleTechnicians(String role) throws Exception {
        mockMvc.perform(get("/api/technicians").with(user("manager").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].id").value(firstTechnician.getId()));
        mockMvc.perform(get(assignmentsUrl(firstOrder)).with(user("manager").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
        mockMvc.perform(post(assignmentsUrl(firstOrder)).with(user("manager").roles(role))
                        .contentType(APPLICATION_JSON).content(objectMapper.writeValueAsString(Map.of(
                                "technicianId", firstTechnician.getId(), "notes", "  Kiểm tra phanh  "))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.repairOrderId").value(firstOrder.getId()))
                .andExpect(jsonPath("$.data.technician.fullName").value(firstTechnician.getFullName()))
                .andExpect(jsonPath("$.data.assignedAt").isString())
                .andExpect(jsonPath("$.data.notes").value("Kiểm tra phanh"));
        mockMvc.perform(post(assignmentsUrl(firstOrder)).with(user("manager").roles(role))
                        .contentType(APPLICATION_JSON).content(request(secondTechnician.getId())))
                .andExpect(status().isCreated());
        entityManager.clear();
        mockMvc.perform(get(assignmentsUrl(firstOrder)).with(user("manager").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].technician.id").value(firstTechnician.getId()))
                .andExpect(jsonPath("$.data[1].technician.id").value(secondTechnician.getId()));
        assertEquals(2, assignmentRepository.count());
        assertEquals("DANG_SUA", repairOrderRepository.findById(firstOrder.getId()).orElseThrow().getStatus());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void duplicateAssignmentReturnsConflictWithoutOverwriting() throws Exception {
        TechnicianAssignment original = saveAssignment(firstOrder, firstTechnician, "Ghi chú ban đầu");
        mockMvc.perform(post(assignmentsUrl(firstOrder)).contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "technicianId", firstTechnician.getId(), "notes", "Không được ghi đè"))))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Kỹ thuật viên đã được phân công cho phiếu sửa chữa này."));
        entityManager.clear();
        TechnicianAssignment saved = assignmentRepository.findById(original.getId()).orElseThrow();
        assertEquals("Ghi chú ban đầu", saved.getNotes());
        assertEquals(original.getAssignedAt(), saved.getAssignedAt());
        assertEquals(1, assignmentRepository.count());
    }

    @Test
    void newAssignmentWithAnExistingKeyInsertsInsteadOfMerging() {
        saveAssignment(firstOrder, firstTechnician, "Ghi chú ban đầu");
        entityManager.clear();
        assertThrows(DataIntegrityViolationException.class,
                () -> saveAssignment(firstOrder, firstTechnician, "Không được ghi đè"));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void missingRepairOrderReturnsNotFound() throws Exception {
        mockMvc.perform(get("/api/repair-orders/2147483647/technicians"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Không tìm thấy phiếu sửa chữa."));
        mockMvc.perform(post("/api/repair-orders/2147483647/technicians")
                        .contentType(APPLICATION_JSON).content(request(firstTechnician.getId())))
                .andExpect(status().isNotFound());
        assertEquals(0, assignmentRepository.count());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void missingTechnicianAndOrdinaryEmployeeCannotBeAssigned() throws Exception {
        for (int id : new int[]{2147483647, receptionist.getId()}) {
            mockMvc.perform(post(assignmentsUrl(firstOrder)).contentType(APPLICATION_JSON).content(request(id)))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.message").value("Không tìm thấy kỹ thuật viên."));
        }
        assertEquals(0, assignmentRepository.count());
    }

    @ParameterizedTest
    @WithMockUser(roles = "ADMIN")
    @ValueSource(strings = {"{}", "{\"technicianId\":0}", "{\"technicianId\":-1}",
            "{\"technicianId\":\"abc\"}", "{invalid"})
    void invalidAssignmentReturnsBadRequest(String request) throws Exception {
        mockMvc.perform(post(assignmentsUrl(firstOrder)).contentType(APPLICATION_JSON).content(request))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
        assertEquals(0, assignmentRepository.count());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void notesMustFitSqlColumn() throws Exception {
        mockMvc.perform(post(assignmentsUrl(firstOrder)).contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "technicianId", firstTechnician.getId(), "notes", "a".repeat(501)))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.notes").exists());
        assertEquals(0, assignmentRepository.count());
    }

    @ParameterizedTest
    @ValueSource(strings = {"CUSTOMER", "TECHNICIAN", "RECEPTIONIST", "WAREHOUSE"})
    void nonManagersCannotAssignOrSeeAllAssignments(String role) throws Exception {
        mockMvc.perform(get("/api/technicians").with(user("reader").roles(role)))
                .andExpect(status().isForbidden());
        mockMvc.perform(get(assignmentsUrl(firstOrder)).with(user("reader").roles(role)))
                .andExpect(status().isForbidden());
        mockMvc.perform(post(assignmentsUrl(firstOrder)).with(user("reader").roles(role))
                        .contentType(APPLICATION_JSON).content(request(firstTechnician.getId())))
                .andExpect(status().isForbidden());
        assertEquals(0, assignmentRepository.count());
    }

    @Test
    void anonymousRequestsAreUnauthorized() throws Exception {
        mockMvc.perform(get("/api/technicians")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/technicians/me/repair-orders")).andExpect(status().isUnauthorized());
        mockMvc.perform(get(assignmentsUrl(firstOrder))).andExpect(status().isUnauthorized());
        mockMvc.perform(post(assignmentsUrl(firstOrder)).contentType(APPLICATION_JSON)
                        .content(request(firstTechnician.getId())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void jwtIdentifiesTechnicianAndCannotBeOverriddenByQueryParameter() throws Exception {
        Account firstAccount = saveAccount(firstTechnician, "technician-a");
        Account secondAccount = saveAccount(secondTechnician, "technician-b");
        saveAssignment(firstOrder, firstTechnician, "Công việc A");
        saveAssignment(secondOrder, secondTechnician, "Công việc B");
        mockMvc.perform(get("/api/technicians/me/repair-orders")
                        .header("Authorization", "Bearer " + jwtService.generateToken(firstAccount))
                        .param("technicianId", secondTechnician.getId().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].repairOrderId").value(firstOrder.getId()))
                .andExpect(jsonPath("$.data[0].receptionId").value(firstOrder.getReceptionId()))
                .andExpect(jsonPath("$.data[0].notes").value("Công việc A"))
                .andExpect(jsonPath("$.data[0].status").value("DANG_SUA"));
        mockMvc.perform(get("/api/technicians/me/repair-orders")
                        .header("Authorization", "Bearer " + jwtService.generateToken(secondAccount)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].repairOrderId").value(secondOrder.getId()));
    }

    @Test
    void technicianWithNoAssignmentsGetsEmptyList() throws Exception {
        Account account = saveAccount(firstTechnician, "technician-empty");
        mockMvc.perform(get("/api/technicians/me/repair-orders")
                        .header("Authorization", "Bearer " + jwtService.generateToken(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void disabledAccountCannotUsePreviouslyIssuedToken() throws Exception {
        Account account = saveAccount(firstTechnician, "technician-disabled");
        String token = jwtService.generateToken(account);
        account.setActive(false);
        accountRepository.saveAndFlush(account);
        mockMvc.perform(get("/api/technicians/me/repair-orders").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void technicianRoleWithoutTechnicianRecordIsForbidden() throws Exception {
        Account account = saveAccount(receptionist, "invalid-technician-mapping");
        mockMvc.perform(get("/api/technicians/me/repair-orders")
                        .header("Authorization", "Bearer " + jwtService.generateToken(account)))
                .andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"CUSTOMER", "RECEPTIONIST", "WAREHOUSE", "MANAGER", "ADMIN"})
    void myWorkEndpointIsOnlyForTechnicians(String role) throws Exception {
        mockMvc.perform(get("/api/technicians/me/repair-orders").with(user("not-technician").roles(role)))
                .andExpect(status().isForbidden());
    }

    private String assignmentsUrl(RepairOrder order) {
        return "/api/repair-orders/" + order.getId() + "/technicians";
    }

    private String request(int technicianId) throws Exception {
        return objectMapper.writeValueAsString(Map.of("technicianId", technicianId));
    }

    private Employee saveEmployee(String name, boolean technician) {
        Employee employee = new Employee();
        employee.setFullName(name);
        employee.setPosition(technician ? "Kỹ thuật viên" : "Lễ tân");
        employee = employeeRepository.saveAndFlush(employee);
        if (technician) {
            Technician record = new Technician();
            record.setEmployeeId(employee.getId());
            technicianRepository.saveAndFlush(record);
        }
        return employee;
    }

    private RepairOrder saveOrder(int receptionId) {
        RepairOrder order = new RepairOrder();
        order.setReceptionId(receptionId);
        order.setCreatedAt(LocalDateTime.of(2026, 9, 29, 8, 0));
        order.setStatus("DANG_SUA");
        return repairOrderRepository.saveAndFlush(order);
    }

    private TechnicianAssignment saveAssignment(RepairOrder order, Employee technician, String notes) {
        TechnicianAssignment assignment = new TechnicianAssignment();
        assignment.setId(new TechnicianAssignmentId(order.getId(), technician.getId()));
        assignment.setAssignedAt(LocalDateTime.of(2026, 9, 29, 9, 0));
        assignment.setNotes(notes);
        return assignmentRepository.saveAndFlush(assignment);
    }

    private Account saveAccount(Employee employee, String username) {
        Account account = new Account();
        account.setUsername(username);
        account.setEmployeeId(employee.getId());
        account.setPasswordHash("unused-in-jwt-test");
        account.setRole(AccountRole.TECHNICIAN);
        return accountRepository.saveAndFlush(account);
    }
}
