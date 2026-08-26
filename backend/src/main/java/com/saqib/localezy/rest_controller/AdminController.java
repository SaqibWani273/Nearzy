package com.saqib.localezy.rest_controller;


import com.saqib.localezy.entity.Admin;
import com.saqib.localezy.entity.ProductCategory;
import com.saqib.localezy.record.AdminPasswordRecord;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.service.admin.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.tags.Tags;

@RestController
@RequestMapping("/admin")
@CrossOrigin(origins = "http://localhost:8080")
@Tags({
    @Tag(name = "Admin Auth", description = "Public endpoints for admin authentication and registration"),
    @Tag(name = "Admin", description = "Authenticated endpoints for admin operations")
})
public class AdminController {
    @Autowired
    AdminService adminService;
    @PostMapping("/register")
    @Tag(name = "Admin Auth")
    @Operation(summary = "Register a new admin", description = "Registers a new admin user using an admin password record and a secret code.")
    @ApiResponse(responseCode = "200", description = "Admin registered successfully")
    public ResponseEntity<?> login(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Admin registration details including user info and secret code") @RequestBody AdminPasswordRecord adminPasswordRecord) {
        //should atleast contain email and password
        return adminService.registerAdmin(adminPasswordRecord);
    }
    //email verification endpoint
    @RequestMapping(value="/verify-email", method= {RequestMethod.GET, RequestMethod.POST})
    @Tag(name = "Admin Auth")
    @Operation(summary = "Verify admin email", description = "Verifies the admin's email address using a confirmation token.")
    @ApiResponse(responseCode = "200", description = "Email verified successfully")
    //GETMethod to get the confirmation token
    //POST method to set the isVerified flag to true
    public ResponseEntity<?> verifyEmail(@Parameter(description = "Email verification token") @RequestParam("token")String token) {
        return adminService.verifyEmail(token);
    }

    //allow all

    @PostMapping("/login")
    @Tag(name = "Admin Auth")
    @Operation(summary = "Admin login", description = "Authenticates an admin user using their email and password.")
    @ApiResponse(responseCode = "200", description = "Login successful")
    public ResponseEntity<?> login(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Admin login credentials") @RequestBody EmailPasswordRecord emailPasswordRecord) {
        //should atleast contain email and password
        return adminService.login(emailPasswordRecord);
    }
    @PostMapping("/add-category")
    @Tag(name = "Admin")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Add product category", description = "Adds a new product category to the system. Requires ROLE_ADMIN.")
    @ApiResponse(responseCode = "200", description = "Category added successfully")
    public ResponseEntity<?> addCategory(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Product category details") @RequestBody ProductCategory productCategory) {

        return adminService.addCategory(productCategory);
    }
    @PostMapping("/me")
    @Tag(name = "Admin")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Verify admin token", description = "Verifies the JWT token for an admin user and returns their profile information.")
    @ApiResponse(responseCode = "200", description = "Token verified successfully")
    public ResponseEntity<?> testCustomerAuthentication(@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "JWT Token string") @RequestBody String token) {
        //we donot need to check for user authentication as every request
        //is being automatically checked using authfilterservice
        return adminService.verifyToken(token);
    }
    @GetMapping("test-get")
    @Tag(name = "Admin Auth")
    @Operation(summary = "Test GET endpoint", description = "Public test endpoint for GET requests.")
    @ApiResponse(responseCode = "200", description = "Test successful")
    public ResponseEntity<?> testGet() {
        return ResponseEntity.ok("test get successful");
    }
    @PostMapping("test-post")
    @Tag(name = "Admin Auth")
    @Operation(summary = "Test POST endpoint", description = "Public test endpoint for POST requests.")
    @ApiResponse(responseCode = "200", description = "Test successful")
    public ResponseEntity<?> testPost() {
        return ResponseEntity.ok("test post successful");
    }
}
