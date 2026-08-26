package com.saqib.localezy.entity;

import jakarta.persistence.*;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.Date;

@Schema(description = "Token entity for email verification")
@Entity
public class EmailConfirmation {

    @Schema(description = "Unique identifier", example = "1", accessMode = Schema.AccessMode.READ_ONLY)
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private  long id;

    @Schema(description = "Unique verification token", example = "abc123xyz")
    @Column(unique = true,nullable = false)
    private String token;
    @Schema(description = "Creation date of the token", example = "2023-10-01T12:00:00Z")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createDate;

    @Schema(description = "The user associated with this token")
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "user_id", referencedColumnName = "id")
    private MyUser myUser;


    public EmailConfirmation(String token, MyUser myUser) {
        this.token = token;
        this.createDate = Date.from(Instant.now());
        this.myUser = myUser;
    }

    public EmailConfirmation() {}

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public MyUser getMyUser() {

        return myUser;
    }

    public void setMyUser(MyUser myUser) {
        this.myUser = myUser;
    }
}
