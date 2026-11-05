package com.gara.quanlygara.service;

import jakarta.annotation.PreDestroy;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.*;
import java.util.concurrent.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
public class PasswordRecovery {
    private static final long PERIOD=TimeUnit.MINUTES.toMillis(15);
    private static final SecureRandom RANDOM=new SecureRandom();
    private static final org.slf4j.Logger LOG=org.slf4j.LoggerFactory.getLogger(PasswordRecovery.class);
    private final JdbcTemplate db;
    private final ResetMail mail;
    private final com.gara.quanlygara.repository.AccountRepository accounts;
    private final PasswordEncoder encoder;
    private final SecretKeySpec key;
    private final ExecutorService delivery=new ThreadPoolExecutor(1,2,60,TimeUnit.SECONDS,new ArrayBlockingQueue<>(100));

    public PasswordRecovery(JdbcTemplate db, ResetMail mail, PasswordEncoder encoder,com.gara.quanlygara.repository.AccountRepository accounts,@Value("${app.jwt.secret}") String key) {
        this.db=db; this.mail=mail; this.encoder=encoder; this.accounts=accounts;
        this.key=new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8),"HmacSHA256");
    }
    @PreDestroy void shutdown(){delivery.shutdown();}
    private String digest(String value) {
        try {
            Mac mac=Mac.getInstance("HmacSHA256"); mac.init(key);
            return HexFormat.of().formatHex(mac.doFinal(("garage:reset:"+value).getBytes(StandardCharsets.UTF_8)));
        } catch(GeneralSecurityException ex){throw new IllegalStateException(ex);}
    }
    private String emailKey(String email){return digest(email.strip().toLowerCase(Locale.ROOT));}
    private boolean matches(String expected,String actual){
        return expected!=null && MessageDigest.isEqual(expected.getBytes(StandardCharsets.US_ASCII),actual.getBytes(StandardCharsets.US_ASCII));
    }
    private Map<String,Object> lock(String emailKey) {
        return db.queryForList("SELECT * FROM PasswordRecovery WITH (UPDLOCK,HOLDLOCK) WHERE EmailKey=?",emailKey).stream().findFirst().orElse(null);
    }
    private List<Map<String,Object>> accounts(String email) {
        return db.queryForList("""
                SELECT a.MaTaiKhoan,a.TenDangNhap,a.MatKhauHash,COALESCE(c.Email,e.Email) address
                FROM TaiKhoan a LEFT JOIN KhachHang c ON c.MaKhachHang=a.MaKhachHang
                LEFT JOIN NhanVien e ON e.MaNhanVien=a.MaNhanVien
                WHERE a.TrangThai=1 AND LOWER(TRIM(COALESCE(c.Email,e.Email)))=?
                """,email.strip().toLowerCase(Locale.ROOT));
    }
    public enum Result { ACCEPTED, LIMITED, UNAVAILABLE }
    @Transactional
    public Result request(String email) {
        if(!mail.configured()) return Result.UNAVAILABLE;
        var candidates=accounts(email);
        return issue(emailKey(email),candidates.size()==1?candidates.getFirst():null,null);
    }

    @Transactional
    public Result requestContact(String username,String email,String password){
        var owner=accounts.findByUsername(username).orElseThrow();
        if(owner.getCustomerId()==null || !encoder.matches(password,owner.getPasswordHash()))
            throw new com.gara.quanlygara.exception.BadRequestException("Mật khẩu hiện tại không đúng.");
        if(!mail.configured()) return Result.UNAVAILABLE;
        String address=email.strip().toLowerCase(Locale.ROOT);
        return issue(digest("contact:"+owner.getId()),Map.of("address",address,"MaTaiKhoan",owner.getId(),"MatKhauHash",owner.getPasswordHash()),address);
    }

    private Result issue(String id,Map<String,Object> account,String contact){
        long now=System.currentTimeMillis();
        // Remove expired throttle records in bounded batches.
        db.update("DELETE TOP (64) FROM PasswordRecovery WHERE WindowStart<? AND ExpiresAt<?",now-PERIOD,now);
        var old=lock(id);
        boolean inWindow=old!=null && (long)old.get("WindowStart")>now-PERIOD;
        if(old!=null && ((long)old.get("LastRequest")>now-60000 || (inWindow && (int)old.get("Sends")>=3)))return Result.LIMITED;
        String code=String.format(Locale.ROOT,"%06d",RANDOM.nextInt(1000000));
        String hash=digest(id+":"+code);
        if(old==null) db.update("INSERT PasswordRecovery(EmailKey,ExpiresAt,WindowStart,LastRequest,Sends,Attempts) VALUES(?,0,?,0,0,0)",id,now);
        db.update("""
                UPDATE PasswordRecovery SET AccountId=?,CredentialKey=?,CodeHash=?,TicketHash=NULL,ExpiresAt=?,WindowStart=?,LastRequest=?,Sends=?,Attempts=? WHERE EmailKey=?
                """,account==null?null:account.get("MaTaiKhoan"),account==null?null:digest((contact==null?"":contact+":")+account.get("MatKhauHash")),hash,
                now+PERIOD,inWindow?old.get("WindowStart"):now,now,inWindow?(int)old.get("Sends")+1:1,inWindow?(int)old.get("Attempts"):0,id);
        if(account!=null) {
            String address=(String)account.get("address");
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){
                public void afterCommit(){
                    try { delivery.execute(()->{
                        try {mail.send(address,code);} catch(RuntimeException failure){failedDelivery(id,hash);}
                    }); } catch(RejectedExecutionException busy){failedDelivery(id,hash);}
                }
            });
        }
        return Result.ACCEPTED;
    }
    private void failedDelivery(String id,String hash){
        LOG.warn("Password recovery mail could not be delivered.");
        // Use a fresh connection even if the executor rejected work in afterCommit.
        try(var c=Objects.requireNonNull(db.getDataSource()).getConnection();
            var stmt=c.prepareStatement("UPDATE PasswordRecovery SET CodeHash=NULL WHERE EmailKey=? AND CodeHash=?")){
            stmt.setString(1,id);stmt.setString(2,hash);stmt.executeUpdate();
        } catch(java.sql.SQLException ex){LOG.error("Could not invalidate an undelivered recovery code.");}
    }
    @Transactional
    public String verify(String email,String code){
        return verifyKey(emailKey(email),code);
    }
    private String verifyKey(String id,String code){
        var row=lock(id);
        if(row==null || (long)row.get("ExpiresAt")<=System.currentTimeMillis() || row.get("CodeHash")==null || (int)row.get("Attempts")>=5)return null;
        db.update("UPDATE PasswordRecovery SET Attempts=Attempts+1 WHERE EmailKey=?",id);
        if(row.get("AccountId")==null || !matches((String)row.get("CodeHash"),digest(id+":"+code)))return null;
        byte[] bytes=new byte[32];RANDOM.nextBytes(bytes);String ticket=HexFormat.of().formatHex(bytes);
        db.update("UPDATE PasswordRecovery SET CodeHash=NULL,TicketHash=? WHERE EmailKey=?",digest(ticket),id);
        return ticket;
    }
    @Transactional(isolation=org.springframework.transaction.annotation.Isolation.SERIALIZABLE)
    public boolean confirmContact(String username,String email,String code){
        var owner=accounts.lockSessionOwner(username).orElseThrow();
        String id=digest("contact:"+owner.getId());
        String address=email.strip().toLowerCase(Locale.ROOT);
        var row=lock(id);
        if(row==null || owner.getCustomerId()==null || !matches((String)row.get("CredentialKey"),digest(address+":"+owner.getPasswordHash())))return false;
        if(verifyKey(id,code)==null)return false;
        if(accounts.countByContactEmail(address)>0)throw new com.gara.quanlygara.exception.ConflictException("Email đã liên kết với tài khoản.");
        db.update("UPDATE KhachHang SET Email=? WHERE MaKhachHang=?",address,owner.getCustomerId());
        db.update("UPDATE PasswordRecovery SET TicketHash=NULL WHERE EmailKey=?",id);
        return true;
    }
    @Transactional
    public boolean complete(String email,String ticket,String password){
        String id=emailKey(email);var row=lock(id);
        if(row==null || (long)row.get("ExpiresAt")<=System.currentTimeMillis() || !matches((String)row.get("TicketHash"),digest(ticket)))return false;
        var candidates=accounts(email);
        if(candidates.size()!=1)return false;
        var account=candidates.getFirst();
        var owner=accounts.lockSessionOwner((String)account.get("TenDangNhap")).orElse(null);
        if(owner==null || !owner.isActive())return false;
        String previous=owner.getPasswordHash();
        if(!Objects.equals(row.get("AccountId"),account.get("MaTaiKhoan")) || !matches((String)row.get("CredentialKey"),digest(previous)))return false;
        if(encoder.matches(password,previous)) throw new com.gara.quanlygara.exception.BadRequestException("Mật khẩu mới phải khác mật khẩu cũ.");
        owner.setPasswordHash(encoder.encode(password));
        accounts.saveAndFlush(owner);
        db.update("UPDATE PasswordRecovery SET TicketHash=NULL,CodeHash=NULL WHERE EmailKey=?",id);
        return true;
    }
}
