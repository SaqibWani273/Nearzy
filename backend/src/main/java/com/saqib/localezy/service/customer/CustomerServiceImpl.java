package com.saqib.localezy.service.customer;

import com.saqib.localezy.entity.*;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.record.UpdateCartItemsRecord;
import com.saqib.localezy.repository.*;
import com.saqib.localezy.service.AuthServices;
import com.saqib.localezy.service.MyUserDetailsService;
import com.saqib.localezy.service.jwt.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CustomerServiceImpl implements CustomerService {

    private CustomerRepository customerRepository;
    private MyUserRepository myUserRepository;
    private PasswordEncoder passwordEncoder;
//    private EmailConfirmationRepository emailConfirmationRepository;
    private AuthenticationManager authenticationManager;
    private JwtService jwtService;
    private MyUserDetailsService myUserDetailsService;
    private AuthServices authServices;
    private ProductRepository productRepository;


    @Autowired
    public CustomerServiceImpl(
            CustomerRepository customerRepository,
            PasswordEncoder passwordEncoder,
//            JavaMailSender javaMailSender,
//            EmailConfirmationRepository emailConfirmationRepository,
            AuthenticationManager authenticationManager,
            JwtService jwtService,
            MyUserDetailsService myUserDetailsService,
            MyUserRepository myUserRepository,
            AuthServices authServices,
            ProductRepository productRepository

            ) {
        this.customerRepository = customerRepository;
        this.passwordEncoder = passwordEncoder;
//        this.javaMailSender = javaMailSender;
//        this.emailConfirmationRepository = emailConfirmationRepository;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.myUserDetailsService = myUserDetailsService;
        this.myUserRepository = myUserRepository;
        this.authServices = authServices;
        this.productRepository = productRepository;
    }





    @Override
    public ResponseEntity<?> registerCustomer(MyUser myUser) {

      var result=authServices.preRegistrationProcess(myUser);
        if(result instanceof String) {
            //=> error
            return ResponseEntity.badRequest().body(result);
        }
        myUser.setRoles("CUSTOMER");
        //save myUser with isVerified as false(by default)
        myUserRepository.save(myUser);
        Customer customer = new Customer(myUser);
        customerRepository.save(customer);



        //send email verification

return authServices.sendEmail(myUser,"customer/verify-email?token=");

    }

    @Override
    public ResponseEntity<?> verifyEmail(String token) {
       return authServices.verifyEmail(token);
    }



    @Override
    public ResponseEntity<?> loginCustomer(EmailPasswordRecord emailPasswordRecord) {
        if (myUserRepository.findByEmail(emailPasswordRecord.email()).isEmpty()) {

            return ResponseEntity.badRequest().body("Email Not Registered");
        }
        if(!myUserRepository.findByEmail(emailPasswordRecord.email()).get().isEmailVerified()){
            return ResponseEntity.badRequest().body("Email not verified");
        }
     return  authServices.sendTokenBack(emailPasswordRecord);

    }
    @Override
    public Customer getCustomer(String jwtToken) {
        String email= jwtService.extractEmail(jwtToken);
        Optional<MyUser> myUser= myUserRepository.findByEmail(email);
        if(myUser.isEmpty()){
            return null;
        }
             Customer customer=   customerRepository.findByMyUser(myUser.get());
        return customer;

    }

    @Override
    public ResponseEntity<?> getAllProducts() {
        return ResponseEntity.ok(productRepository.findAll());
    }

    @Override
    public ResponseEntity<?> updateCustomer(Customer customer) {
        return ResponseEntity.ok(customerRepository.save(customer));
    }

    @Override
    public ResponseEntity<?> updateCartItems(UpdateCartItemsRecord updateCartItemsRecord) {
        //update customer
        Customer customer = customerRepository.findById(updateCartItemsRecord.customerId()).get();
        customer.setCartItems(updateCartItemsRecord.cartItems());
        customerRepository.save(customer);
        return ResponseEntity.ok("Cart Items Updated");
    }

    @Override
    public ResponseEntity<?> fetchProdcutsByIds(List<Long> ids) {
        List<Product> products = productRepository.findAllById(ids);
        return ResponseEntity.ok(products);
    }


}
