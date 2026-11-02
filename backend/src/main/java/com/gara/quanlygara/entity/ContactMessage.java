package com.gara.quanlygara.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name="LienHeKhachHang")
public class ContactMessage {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) @Column(name="MaLienHe")
    private Integer id;
    @Column(name="MaYeuCau",nullable=false,unique=true,length=36) private String requestId;
    @Column(name="HoTen",nullable=false,length=100) private String fullName;
    @Column(name="SoDienThoai",nullable=false,length=20) private String phone;
    @Column(name="BienSo",length=20) private String plate;
    @Column(name="NoiDung",nullable=false,length=2000) private String message;
    @Column(name="NgayGui",nullable=false) private LocalDateTime createdAt;
    @Column(name="DaDoc",nullable=false) private boolean read;
    public ContactMessage() { }
    public ContactMessage(String requestId,String fullName,String phone,String plate,String message,LocalDateTime createdAt) {
        this.requestId=requestId;this.fullName=fullName;this.phone=phone;this.plate=plate;this.message=message;this.createdAt=createdAt;
    }
    public Integer getId(){return id;}
    public String getRequestId(){return requestId;}
    public String getFullName(){return fullName;}
    public String getPhone(){return phone;}
    public String getPlate(){return plate;}
    public String getMessage(){return message;}
    public LocalDateTime getCreatedAt(){return createdAt;}
    public boolean isRead(){return read;}
}
