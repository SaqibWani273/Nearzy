package com.saqib.localezy.service.shop;

import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.entity.Product;
import com.saqib.localezy.entity.Shop;
import com.saqib.localezy.record.EmailPasswordRecord;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public interface ShopService {
    ResponseEntity<?> registerShop(Shop shop);

    ResponseEntity<?> loginShop(EmailPasswordRecord emailPasswordRecord);

    ResponseEntity<?> getShop(String token);

    ResponseEntity<?> verifyEmail(String token);

    ResponseEntity<?> addProduct(Product product);
}
