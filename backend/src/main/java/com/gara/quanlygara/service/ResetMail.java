package com.gara.quanlygara.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.stereotype.Component;

@Component
public class ResetMail {
    private final JavaMailSenderImpl smtp = new JavaMailSenderImpl();
    private final String from;
    public ResetMail(@Value("${SMTP_HOST:}") String host, @Value("${SMTP_PORT:587}") int port,
                     @Value("${SMTP_USERNAME:}") String username, @Value("${SMTP_PASSWORD:}") String password,
                     @Value("${SMTP_FROM:}") String from) {
        this.from=from;
        smtp.setHost(host); smtp.setPort(port); smtp.setUsername(username); smtp.setPassword(password);
        var settings=smtp.getJavaMailProperties();
        settings.setProperty("mail.smtp.auth","true");
        settings.setProperty("mail.smtp.ssl.checkserveridentity","true");
        if(port==465) settings.setProperty("mail.smtp.ssl.enable","true");
        else {
            settings.setProperty("mail.smtp.starttls.enable","true");
            settings.setProperty("mail.smtp.starttls.required","true");
        }
        for(String key:new String[]{"connectiontimeout","timeout","writetimeout"}) settings.setProperty("mail.smtp."+key,"5000");
    }
    public boolean configured() {
        return !smtp.getHost().isBlank() && !smtp.getUsername().isBlank() && !smtp.getPassword().isBlank() && !from.isBlank();
    }
    public void send(String address,String otp) {
        var message=new SimpleMailMessage();
        message.setFrom(from); message.setTo(address); message.setSubject("Khôi phục mật khẩu gara");
        message.setText("Mã xác minh của bạn là "+otp+". Mã dùng một lần và hết hạn sau 15 phút.");
        smtp.send(message);
    }
}
