package com.saqib.localezy.repository;

import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.entity.Shop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface  ShopRepository extends JpaRepository<Shop, Long> {
    Shop findByMyUser(MyUser myUser);
//    Shop findByUserId(Long id);
}
