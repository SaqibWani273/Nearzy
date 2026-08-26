package com.saqib.localezy.rest_controller;

import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.repository.CustomerRepository;
import com.saqib.localezy.repository.MyUserRepository;
import com.saqib.localezy.repository.ShopRepository;
import com.saqib.localezy.service.common.CommonService;
import com.saqib.localezy.service.jwt.JwtService;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/user")
@Tag(name = "Common", description = "Common utility endpoints shared across different user roles")
public class CommonController {
    @Autowired
    JwtService jwtService;

    @Autowired
    MyUserRepository myUserRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private ShopRepository shopRepository;
    @Autowired
    private CommonService commonService;


    @GetMapping("/test")
    @Operation(summary = "Test endpoint", description = "Public test endpoint to verify the common API is accessible.")
    @ApiResponse(responseCode = "200", description = "Tested successfully")
    public String test() {
        return "tested successfully";
    }
    @PostMapping("/me")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Get current user profile", description = "Retrieves the profile information for the authenticated user based on their JWT token.")
    @ApiResponse(responseCode = "200", description = "User profile retrieved successfully")
    public ResponseEntity<?> testCustomerAuthentication(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "JWT Token string") @RequestBody String token) {
        //we donot need to check for user authentication as every request
        //is being automatically checked using authfilterservice
        String email = jwtService.extractEmail(token);
        final Optional<MyUser> myUser = myUserRepository.findByEmail(email);
        Claims claims = jwtService.extractClaims(token);
        String role = claims.get("role").toString();
        Map<String, Object> responseBody = new HashMap<>();
        if (role.equals("ROLE_CUSTOMER")) {
            responseBody.put( "model", customerRepository.findByMyUser(myUser.get()));
        } else {
            //=> ROLE_SHOP
            responseBody.put( "model", shopRepository.findByMyUser(myUser.get()));

        }
        responseBody.put("role", role);

        //shop model
        return ResponseEntity.ok(responseBody);

    }

    @GetMapping("/get-all-categories")
    @Operation(summary = "Get all product categories", description = "Retrieves a list of all available product categories.")
    @ApiResponse(responseCode = "200", description = "Categories retrieved successfully")
    public ResponseEntity<?> getAllCategories() {
        return commonService.getAllCategories();
    }
    @PostMapping("/email-exists")
    @Operation(summary = "Check if email exists", description = "Checks whether the provided email address is already registered in the system.")
    @ApiResponse(responseCode = "200", description = "Email availability check completed")
    public ResponseEntity<?> emailExists(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Email address to check") @RequestBody String email) {
        return commonService.emailExists(email);
    }
//    @PostMapping("/phone-exists")
//    public ResponseEntity<?> phoneExists(@RequestBody String phone) {
//        return commonService.phoneExists(phone);
//    }
    @PostMapping("/username-exists")
    @Operation(summary = "Check if username exists", description = "Checks whether the provided username is already registered in the system.")
    @ApiResponse(responseCode = "200", description = "Username availability check completed")
    public ResponseEntity<?> usernameExists(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Username to check") @RequestBody String username) {
        return commonService.usernameExists(username);
    }

}
