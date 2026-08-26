package com.saqib.localezy.service.admin;

import com.saqib.localezy.entity.Admin;
import com.saqib.localezy.entity.ProductCategory;
import com.saqib.localezy.record.AdminPasswordRecord;
import com.saqib.localezy.record.EmailPasswordRecord;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public interface AdminService {
    ResponseEntity<?> login(EmailPasswordRecord emailPasswordRecord);
    ResponseEntity<?> registerAdmin(AdminPasswordRecord adminPasswordRecord);
    ResponseEntity<?> addCategory(ProductCategory productCategory);
    ResponseEntity<?> verifyEmail(String token);
ResponseEntity<?> verifyToken(String token);
}
