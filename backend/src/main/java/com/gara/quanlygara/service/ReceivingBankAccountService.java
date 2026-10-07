package com.gara.quanlygara.service;
import com.gara.quanlygara.dto.billing.BankAccountRequest;
import com.gara.quanlygara.entity.ReceivingBankAccount;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.ReceivingBankAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ReceivingBankAccountService {
    private final ReceivingBankAccountRepository banks;
    public ReceivingBankAccountService(ReceivingBankAccountRepository banks) { this.banks = banks; }
    public List<ReceivingBankAccount> getAll() { return banks.findAllByOrderByNameAscIdAsc(); }
    @Transactional
    public ReceivingBankAccount save(Integer id, BankAccountRequest request) {
        var bank = id == null ? new ReceivingBankAccount() : banks.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản ngân hàng."));
        bank.setName(request.name()); bank.setBin(request.bin()); bank.setAccount(request.account());
        bank.setAccountName(request.accountName()); bank.setActive(request.active());
        return banks.saveAndFlush(bank);
    }
}
