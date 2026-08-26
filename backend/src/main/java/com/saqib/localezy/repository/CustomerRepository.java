package com.saqib.localezy.repository;

import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {

    Customer findByMyUser(MyUser myUser);
//    Customer findByUsername(String username);
}
