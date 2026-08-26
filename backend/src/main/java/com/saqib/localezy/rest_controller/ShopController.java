package com.saqib.localezy.rest_controller;

import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.entity.Product;
import com.saqib.localezy.entity.ProductCategory;
import com.saqib.localezy.entity.Shop;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.service.customer.CustomerService;
import com.saqib.localezy.service.shop.ShopService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/shop")
public class ShopController {

    @Autowired
    ShopService shopService;

    //register endpoint
    @Tag(name = "Shop Auth")
    @Operation(summary = "Register a new shop", description = "Registers a new shop including nested user, phone number, and location info. This is a public endpoint.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Shop details", required = true, content = @Content(schema = @Schema(implementation = Shop.class)))
    @ApiResponse(responseCode = "200", description = "Shop registered successfully")
    @PostMapping("/register")
    public ResponseEntity<?> registerCustomer(@RequestBody Shop shop) {
        //should atleast contain email & password
        return shopService.registerShop(shop);
    }
    //email verification endpoint
    @Tag(name = "Shop Auth")
    @Operation(summary = "Verify shop email", description = "Verifies a shop's email using a token. GET retrieves the token, POST sets the isVerified flag.")
    @Parameter(name = "token", description = "Email verification token", required = true)
    @ApiResponse(responseCode = "200", description = "Email verified successfully")
    @RequestMapping(value="/verify-email", method= {RequestMethod.GET, RequestMethod.POST})
    //GETMethod to get the confirmation token
    //POST method to set the isVerified flag to true
    public ResponseEntity<?> verifyEmail(@RequestParam("token")String token) {
        return shopService.verifyEmail(token);
    }

    //login endpoint
    @Tag(name = "Shop Auth")
    @Operation(summary = "Shop login", description = "Authenticates a shop using email and password, returning a JWT token upon success.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Shop login credentials", required = true, content = @Content(schema = @Schema(implementation = EmailPasswordRecord.class)))
    @ApiResponse(responseCode = "200", description = "Shop logged in successfully")
    @PostMapping("/login")
    public ResponseEntity<?> loginCustomer(@RequestBody EmailPasswordRecord emailPasswordRecord) {
        //should atleast contain email and password
        return shopService.loginShop(emailPasswordRecord);
    }

    @Tag(name = "Shop")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Get shop profile", description = "Retrieves the authenticated shop's profile using the provided JWT token.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "JWT Token string", required = true, content = @Content(schema = @Schema(type = "string")))
    @ApiResponse(responseCode = "200", description = "Shop profile retrieved successfully")
    @PostMapping("/me")
    public ResponseEntity<?> testCustomerAuthentication(@RequestBody String token) {
      //we donot need to check for user authentication as every request
        //is being automatically checked using authfilterservice
        return shopService.getShop(token);
    }
    
    @Tag(name = "Shop")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Add a new product", description = "Adds a new product to the authenticated shop's inventory.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Product details", required = true, content = @Content(schema = @Schema(implementation = Product.class)))
    @ApiResponse(responseCode = "200", description = "Product added successfully")
    @PostMapping("add-product")
    public ResponseEntity<?> addProduct(@RequestBody Product product) {
        return shopService.addProduct(product);
    }

}
