package com.saqib.localezy.service.customer;

import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.record.UpdateCartItemsRecord;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface CustomerService {

    //register
    ResponseEntity<?> registerCustomer(MyUser myUser);

    //login

    ResponseEntity<?> loginCustomer(EmailPasswordRecord emailPasswordRecord);

    //email verification

    ResponseEntity<?> verifyEmail(String token);

    //forgot password

    Customer getCustomer(String jwtToken);

    ResponseEntity<?> getAllProducts();
    //to do : also receive jwt token to check if user is authorized

    ResponseEntity<?> updateCustomer(Customer customer);

    ResponseEntity<?> updateCartItems(UpdateCartItemsRecord updateCartItemsRecord);
ResponseEntity<?> fetchProdcutsByIds(List<Long> ids);

}
