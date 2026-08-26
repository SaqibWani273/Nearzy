package com.saqib.localezy.service;

import com.saqib.localezy.entity.EmailConfirmation;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.repository.EmailConfirmationRepository;
import com.saqib.localezy.repository.MyUserRepository;
import com.saqib.localezy.service.jwt.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AuthServices {
    @Autowired
    private EmailConfirmationRepository emailConfirmationRepository;
    @Autowired
    private JavaMailSender javaMailSender;
    @Autowired
    MyUserRepository myUserRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private MyUserDetailsService myUserDetailsService;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private AuthenticationManager authenticationManager;
    @Value("${spring.host.current}")
    private String host;


    //returns string if error else returns MyUser
    public Object preRegistrationProcess(MyUser myUser) {
        //check if email exists
        if (myUserRepository.findByEmail(myUser.getEmail()).isPresent()) {

            return "Email already exists";
        }
        if(myUserRepository.findByUsername(myUser.getUsername()).isPresent()){

            return "Username already exists";
        }

        //encrypt password
        myUser.setPassword(passwordEncoder.encode(myUser.getPassword()));
        //if client set id to any value then it should be ignored
        if(myUser.getId()!=0){
            myUser.setId(0);
        }
        return myUser;
    }
    public ResponseEntity<?> sendEmail(MyUser myUser,String text){

        String randomToken = UUID.randomUUID().toString();
        EmailConfirmation emailConfirmation = new EmailConfirmation(randomToken, myUser);
        emailConfirmationRepository.save(emailConfirmation);
        SimpleMailMessage simpleMailMessage = new SimpleMailMessage();
        simpleMailMessage.setTo(myUser.getEmail());
//        simpleMailMessage.getFrom(adminEmail);
        simpleMailMessage.setSubject("Email Verification for Localezy");

        simpleMailMessage.setText("Email verification link: " + host  + text + emailConfirmation.getToken());

        sendEmail(simpleMailMessage);
        return ResponseEntity.ok("Email verification link sent to " + myUser.getEmail());

    }
    @Async
    void sendEmail(SimpleMailMessage message) {
        javaMailSender.send(message);
    }
    public ResponseEntity<?> verifyEmail(String token) {
        EmailConfirmation emailConfirmation = emailConfirmationRepository.findByToken(token);
        if(emailConfirmation!=null){
            MyUser myUser = emailConfirmation.getMyUser();
            myUser.setEmailVerified(true);
            myUserRepository.save(myUser);

            return ResponseEntity.ok("Email verified successfully");
        }


        return ResponseEntity.badRequest().body("Invalid token");
    }

    public ResponseEntity<?> sendTokenBack(EmailPasswordRecord emailPasswordRecord) {
        //check user auhthentication
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(emailPasswordRecord.email(),emailPasswordRecord.password()));
        if(authentication.isAuthenticated()){
            //generate token
            String token=  jwtService.generateToken(myUserDetailsService
                    .loadUserByUsername(emailPasswordRecord.email()));
            return ResponseEntity.ok(token);
        }

        return ResponseEntity.badRequest().body("Invalid credentials");
    }
}
