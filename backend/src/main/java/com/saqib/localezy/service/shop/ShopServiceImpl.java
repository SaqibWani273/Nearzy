package com.saqib.localezy.service.shop;

import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.entity.Product;
import com.saqib.localezy.entity.Shop;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.repository.MyUserRepository;
import com.saqib.localezy.repository.ProductRepository;
import com.saqib.localezy.repository.ShopRepository;
import com.saqib.localezy.service.AuthServices;
import com.saqib.localezy.service.jwt.JwtService;
import org.antlr.v4.runtime.misc.LogManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ShopServiceImpl implements ShopService {
    @Autowired
    private AuthServices authServices;
    @Autowired
    private MyUserRepository myUserRepository;
    @Autowired
    private ShopRepository shopRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private ProductRepository productRepository;

    @Override
    public ResponseEntity<?> registerShop(Shop shop) {

        var result=authServices.preRegistrationProcess(shop.getMyUser());
        if(result instanceof String) {
            //=> error
            return ResponseEntity.badRequest().body(result);
        }

       shop.getMyUser().setRoles("SHOP");
        //save myUser with isVerified as false(by default)
        myUserRepository.save(shop.getMyUser());

        shopRepository.save(shop);


        //send email verification

        return authServices.sendEmail(shop.getMyUser(),"shop/verify-email?token=");


    }

    @Override
    public ResponseEntity<?> verifyEmail(String token) {
        return authServices.verifyEmail(token);
    }
    @Override
    public ResponseEntity<?> loginShop(EmailPasswordRecord emailPasswordRecord) {
        final Optional<MyUser> myUser= myUserRepository.findByEmail(emailPasswordRecord.email());
        if (myUser.isEmpty()) {

            return ResponseEntity.badRequest().body("Email Not Registered");
        }
        if(!myUser.get().isEmailVerified()){
            return ResponseEntity.badRequest().body("Email not verified");
        }
        if(!myUser.get().getRoles().equals("SHOP")){
            return ResponseEntity.badRequest().body("Not a shop user");
        }
        //to do : check isVerifiefd by admin later
        return authServices.sendTokenBack(emailPasswordRecord);
    }

    @Override
    public ResponseEntity<?> getShop(String token) {
        String email= jwtService.extractEmail(token);
        Optional<MyUser> myUser= myUserRepository.findByEmail(email);
        Shop shop=shopRepository.findByMyUser(myUser.get());
        return ResponseEntity.ok(shop);
    }


    @Override
    public ResponseEntity<?> addProduct(Product product) {
        System.out.println("bool-> "+product.getClass().equals(Product.class));
        System.out.println( "adding product "+product.toString());
//        Shop shop=shopRepository.findById(product.getShop().getId()).get();
      productRepository.save(product);
        return   ResponseEntity.ok("Product Added -> "+product.toString());
    }
}
