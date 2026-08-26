package com.saqib.localezy.entity;

import jakarta.persistence.*;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Core user entity representing authentication and basic details")
@Entity
public class MyUser  {
    @Schema(description = "Unique identifier for the user", example = "1", accessMode = Schema.AccessMode.READ_ONLY)
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private long id;
    @Schema(description = "User's chosen username", example = "johndoe123")
    @Column(unique = true,nullable = true)
    private String username;
    @Schema(description = "User's password (hashed)", example = "Password123!", accessMode = Schema.AccessMode.WRITE_ONLY)
    @Column(unique = true,nullable = false)
    private String password;
    @Schema(description = "User's email address", example = "johndoe@example.com")
    @Column(unique = true,nullable = false)
    private String email;
    @Schema(description = "Comma-separated list of roles", example = "ROLE_CUSTOMER")
    private String roles;
    @Schema(description = "Whether the user's email has been verified", example = "true")
    private boolean isEmailVerified;

    public MyUser() {
    }

    public MyUser( String username, String password, String email, String roles) {

        this.username = username;
        this.password = password;
        this.email = email;
        this.roles = roles;
        this.isEmailVerified = false;
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getRoles() {
        return roles;
    }

    public void setRoles(String roles) {
        this.roles = roles;
    }

    public boolean isEmailVerified() {
        return isEmailVerified;
    }

    public void setEmailVerified(boolean emailVerified) {
        isEmailVerified = emailVerified;
    }
}
