package com.saqib.localezy.service.common;

import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.repository.MyUserRepository;
import com.saqib.localezy.repository.ProductCategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class CommonServiceImpl implements CommonService {

    @Autowired
    ProductCategoryRepository productCategoryRepository;

    @Autowired
    private MyUserRepository myUserRepository;

    @Override
    public ResponseEntity<?> getAllCategories() {
        return ResponseEntity.ok( productCategoryRepository.findAll());
    }

    @Override
    public ResponseEntity<?> emailExists(String email) {

        return myUserRepository.findByEmail(email).isPresent()?
                ResponseEntity.ok(true) : ResponseEntity.ok(false);
    }

    @Override
    public ResponseEntity<?> usernameExists(String username) {
        return myUserRepository.findByEmail(username).isPresent()? ResponseEntity.ok(true) : ResponseEntity.ok(false);
    }

//    @Override
//    public ResponseEntity<?> phoneExists(String phone) {
//        return myUserRepository.findByEmail(phone).getClass()==
//                MyUser.class? ResponseEntity.ok(true) : ResponseEntity.ok(false);
//    }
}
