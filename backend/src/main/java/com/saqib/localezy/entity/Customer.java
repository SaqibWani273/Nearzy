package com.saqib.localezy.entity;

import com.saqib.localezy.configuration.JpaConverterJSON;
import jakarta.persistence.*;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;
import java.util.Map;

@Schema(description = "Customer profile associated with a user, containing cart details")
@Entity
public class Customer{
    @Schema(description = "Unique identifier for the customer profile", example = "1", accessMode = Schema.AccessMode.READ_ONLY)
    @Id
    @Column(unique = true,nullable = false)
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    @Schema(description = "The underlying user account")
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "user_id", referencedColumnName = "id")
    private MyUser myUser;
    @Schema(description = "JSON representation of the customer's shopping cart items", example = "[{\"productId\": 1, \"quantity\": 2}]")
    @Convert(converter = JpaConverterJSON.class)
    @Column( length = 65000)
    private List<Map<String,Object>> cartItems;

    public Customer( MyUser myUser) {
        this.myUser = myUser;
    }
    public Customer() {
    }
    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public MyUser getMyUser() {
        return myUser;
    }

    public void setMyUser(MyUser myUser) {
        this.myUser = myUser;
    }

    public List<Map<String, Object>> getCartItems() {
        return cartItems;
    }

    public void setCartItems(List<Map<String, Object>> cartItems) {
        this.cartItems = cartItems;
    }
}