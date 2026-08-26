package com.saqib.localezy.repository;

import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MyUserRepository extends JpaRepository<MyUser, Long> {
    Optional<MyUser> findByEmail(String email);
    Optional<MyUser> findByUsername(String username);
//    MyUser findByPhone(String phone);
}
