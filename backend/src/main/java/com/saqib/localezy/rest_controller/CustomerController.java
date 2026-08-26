package com.saqib.localezy.rest_controller;

import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.record.EmailPasswordRecord;
import com.saqib.localezy.record.UpdateCartItemsRecord;
import com.saqib.localezy.service.customer.CustomerService;
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

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/customer")
public class CustomerController {

    private CustomerService customerService;

    @Autowired
    public CustomerController(CustomerService customerService) {

        this.customerService = customerService;
    }

    public CustomerController() {
    }

    //register endpoint
    @Tag(name = "Customer Auth")
    @Operation(summary = "Register a new customer", description = "Registers a new customer account using email, password, and username. This endpoint is public.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Customer details containing email, password, and username", required = true, content = @Content(schema = @Schema(implementation = MyUser.class)))
    @ApiResponse(responseCode = "200", description = "Successfully registered the customer")
    @PostMapping("/register")
    public ResponseEntity<?> registerCustomer(@RequestBody MyUser myUser) {
        //should atleast contain email & password
        return customerService.registerCustomer(myUser);
    }

    //email verification endpoint
    @Tag(name = "Customer Auth")
    @Operation(summary = "Verify customer email", description = "Verifies a customer's email address using a token. GET gets the token, POST sets the isVerified flag to true.")
    @Parameter(name = "token", description = "The email verification token", required = true)
    @ApiResponse(responseCode = "200", description = "Email verified successfully")
    @RequestMapping(value = "/verify-email", method = {RequestMethod.GET, RequestMethod.POST})
    //GETMethod to get the confirmation token
    //POST method to set the isVerified flag to true
    public ResponseEntity<?> verifyEmail(@RequestParam("token") String token) {
        return customerService.verifyEmail(token);
    }

    //login endpoint
    @Tag(name = "Customer Auth")
    @Operation(summary = "Login customer", description = "Authenticates a customer with email and password, returning a JWT token upon success.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Customer login credentials", required = true, content = @Content(schema = @Schema(implementation = EmailPasswordRecord.class)))
    @ApiResponse(responseCode = "200", description = "Successfully logged in and JWT token generated")
    @PostMapping("/login")
    public ResponseEntity<?> loginCustomer(@RequestBody EmailPasswordRecord emailPasswordRecord) {
        //should atleast contain email and password
        return customerService.loginCustomer(emailPasswordRecord);
    }

    @Tag(name = "Customer")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Get current customer profile", description = "Retrieves the authenticated customer's profile using their JWT token.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "JWT Token string", required = true, content = @Content(schema = @Schema(type = "string")))
    @ApiResponse(responseCode = "200", description = "Customer profile retrieved successfully")
    @PostMapping("/me")
    public ResponseEntity<?> testCustomerAuthentication(@RequestBody String token) {
        //we donot need to check for user authentication as every request
        //is being automatically checked using authfilterservice
        Customer customer = customerService.getCustomer(token);
        if (customer == null) {
            return ResponseEntity.badRequest().body("invalid token");
        }
        return ResponseEntity.ok(customer);
    }
    
    @Tag(name = "Customer Auth")
    @Operation(summary = "Get all products", description = "Fetches a list of all available products. This endpoint is public.")
    @ApiResponse(responseCode = "200", description = "Successfully retrieved all products")
    @GetMapping("/get-all-products")
    public ResponseEntity<?> getProducts() {
        return customerService.getAllProducts();
    }
    
    @Tag(name = "Customer")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Update customer profile", description = "Updates the currently authenticated customer's profile details.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Updated customer details", required = true, content = @Content(schema = @Schema(implementation = Customer.class)))
    @ApiResponse(responseCode = "200", description = "Customer profile updated successfully")
    @PostMapping("/update")
    public ResponseEntity<?> updateCustomer(@RequestBody Customer customer) {
        return customerService.updateCustomer(customer);
    }
    
    @Tag(name = "Customer")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Update cart items", description = "Updates the items in the authenticated customer's cart.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Cart item updates", required = true, content = @Content(schema = @Schema(implementation = UpdateCartItemsRecord.class)))
    @ApiResponse(responseCode = "200", description = "Cart items updated successfully")
    @PostMapping("/update-cart-items")
    public ResponseEntity<?> updateCartItems(@RequestBody UpdateCartItemsRecord updateCartItemsRecord) {
        return customerService.updateCartItems(updateCartItemsRecord);
    }
    
    @Tag(name = "Customer")
    @SecurityRequirement(name = "Bearer JWT")
    @Operation(summary = "Get products by IDs", description = "Fetches specific products based on a provided list of product IDs.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Map containing the list of product IDs under the key 'productIds'", required = true, content = @Content(schema = @Schema(type = "object", example = "{\"productIds\": [1, 2, 3]}")))
    @ApiResponse(responseCode = "200", description = "Products retrieved successfully")
    @PostMapping("/get-products-by-ids")
    public ResponseEntity<?> getProductsByIds(@RequestBody Map<String, List<Long>> idsMap) {
        return customerService.fetchProdcutsByIds(idsMap.get("productIds"));
    }

}
