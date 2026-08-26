package com.saqib.localezy.service.admin;

import com.saqib.localezy.entity.Admin;
import com.saqib.localezy.entity.EmailConfirmation;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.entity.ProductCategory;
import com.saqib.localezy.record.AdminPasswordRecord;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.repository.AdminRepository;
import com.saqib.localezy.repository.MyUserRepository;
import com.saqib.localezy.repository.ProductCategoryRepository;
import com.saqib.localezy.service.AuthServices;
import com.saqib.localezy.service.MyUserDetailsService;
import com.saqib.localezy.service.jwt.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service
public class AdminServiceImpl implements AdminService {
    @Value("${admin.email}")
    private String adminEmail;

    @Value("${admin.password}")
    private String adminPassword;
    @Autowired
    PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;
    @Autowired
    AdminRepository adminRepository;

    @Autowired
    MyUserDetailsService myUserDetailsService;
    @Autowired
    MyUserRepository myUserRepository;
    @Autowired
    AuthenticationManager authenticationManager;
    @Autowired
    private AuthServices authServices;
    @Autowired
    ProductCategoryRepository productCategoryRepository;

    //temp method
    @Override
    public ResponseEntity<?> registerAdmin(AdminPasswordRecord adminPasswordRecord) {
        var result = authServices.preRegistrationProcess(adminPasswordRecord.myUser());
        if(result instanceof String) {
            return ResponseEntity.badRequest().body(result);
        }
        if(adminPasswordRecord.secretCode().equals(adminPassword)) {
            MyUser myUser = adminPasswordRecord.myUser();
            myUser.setRoles("ADMIN");
            myUserRepository.save(myUser);
            Admin admin = new Admin();
            admin.setMyUser(adminPasswordRecord.myUser());
            adminRepository.save(admin);
            //send email verification
            return authServices.sendEmail(myUser, "admin/verify-email?token=");
        }

        return ResponseEntity.badRequest().body("Invalid Secret Code");
    }


    @Override
    public ResponseEntity<?> verifyEmail(String token) {
        return authServices.verifyEmail(token);
    }

    @Override
    public ResponseEntity<?> verifyToken(String token) {
        String email= jwtService.extractEmail(token);
        Optional<MyUser> myUser= myUserRepository.findByEmail(email);
        if(myUser.isEmpty()){
            return ResponseEntity.badRequest().body("No User Found");
        }
      if( myUser.get().getRoles().contains("ADMIN")){
          return ResponseEntity.ok("Email Verified");
      }

        return ResponseEntity.badRequest().body("Invalid Token");
    }

    @Override
    public ResponseEntity<?> login(EmailPasswordRecord emailPasswordRecord) {

        Optional<MyUser> myUser = myUserRepository.findByEmail(emailPasswordRecord.email());
        if (myUser.isPresent() && myUser.get().getRoles().contains("ADMIN")) {
            return authServices.sendTokenBack(emailPasswordRecord);
        }

        return ResponseEntity.badRequest().body("Invalid Admin credentials");
    }

    @Override
    public ResponseEntity<?> addCategory(ProductCategory productCategory) {
if(productCategory.getId()!=0){
    productCategory.setId(0);
}
        System.out.println("adding category "+productCategory.toString());
        productCategoryRepository.save(productCategory);
        return ResponseEntity.ok("Category added successfully");
    }
}
