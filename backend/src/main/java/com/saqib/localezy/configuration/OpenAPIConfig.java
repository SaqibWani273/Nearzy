package com.saqib.localezy.configuration;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenAPIConfig {

    @Value("${spring.host.current:http://localhost:8080/}")
    private String serverUrl;

    @Bean
    public OpenAPI localezyOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Localezy API")
                        .description("""
                                **Localezy** is a local e-commerce marketplace REST API.
                                
                                ## Overview
                                - **Shops** register, get verified, and list products for sale
                                - **Customers** browse products, manage shopping carts, and place orders
                                - **Admins** manage product categories and oversee the platform
                                
                                ## Authentication
                                All authenticated endpoints require a **JWT Bearer token** obtained via the login endpoints.
                                Include it in the `Authorization` header as `Bearer <token>`.
                                
                                ## Roles
                                | Role | Description |
                                |------|-------------|
                                | `ROLE_CUSTOMER` | Registered customer — can browse, cart, and purchase |
                                | `ROLE_SHOP` | Registered shop owner — can list and manage products |
                                | `ROLE_ADMIN` | Platform administrator — manages categories and shops |
                                """)
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("Saqib Wani")
                                .email("saqibwani273@gmail.com")
                                .url("https://github.com/SaqibWani273"))
                        .license(new License()
                                .name("MIT License")
                                .url("https://opensource.org/licenses/MIT")))
                .servers(List.of(
                        new Server().url(serverUrl).description("Current Server")))
                .tags(List.of(
                        new Tag().name("Health").description("Server health and status monitoring"),
                        new Tag().name("Customer Auth").description("Customer registration, email verification, and login"),
                        new Tag().name("Shop Auth").description("Shop registration, email verification, and login"),
                        new Tag().name("Admin Auth").description("Admin registration, email verification, and login"),
                        new Tag().name("Customer").description("Customer profile, cart management, and product browsing"),
                        new Tag().name("Shop").description("Shop profile and product management"),
                        new Tag().name("Admin").description("Platform administration — categories and oversight"),
                        new Tag().name("Common").description("Shared endpoints for all authenticated users")))
                .addSecurityItem(new SecurityRequirement().addList("Bearer JWT"))
                .components(new Components()
                        .addSecuritySchemes("Bearer JWT", new SecurityScheme()
                                .name("Authorization")
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Enter your JWT token obtained from the login endpoint")));
    }
}
