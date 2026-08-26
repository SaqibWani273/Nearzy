package com.saqib.localezy.entity;

import jakarta.persistence.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.time.Instant;
import java.util.Date;
import java.util.List;

@Schema(description = "Shop entity containing details about a registered business")
@Entity @ToString @Getter @Setter
public class Shop {
    @Schema(description = "Unique identifier for the shop", example = "100", accessMode = Schema.AccessMode.READ_ONLY)
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    long id;


    @Schema(description = "The user account acting as the shop owner")
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "user_id", referencedColumnName = "id")
    private MyUser myUser;
    @Schema(description = "Whether the shop has been verified by an admin", example = "true")
    @Column(nullable = false)
    boolean isVerifiedByAdmin;
//    String imageUrl;
    @Schema(description = "URL to the shop's profile picture", example = "https://example.com/shop.jpg")
String shopPicUrl;
    @Schema(description = "Contact phone number for the shop", example = "+1-555-123-4567")
    @Column(unique = true,nullable = false)
    String phoneNumber;
    @Schema(description = "Address of the shop", example = "123 Main St, Springfield")
    String address;
    @Schema(description = "Description of the shop's offerings", example = "Best bakery in town")
    String description;
    @Schema(description = "Date and time the shop profile was created", example = "2023-10-01T12:00:00Z")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createDate;
    @Schema(description = "Name of the shop owner", example = "Jane Doe")
    String ownerName;
    @Schema(description = "URL to the owner's picture", example = "https://example.com/owner.jpg")
    String ownerPicUrl;
    @Schema(description = "URL to the owner's PAN card picture", example = "https://example.com/pancard.jpg")
    String pancardPicUrl;
    @Schema(description = "URL to the owner's ID picture", example = "https://example.com/owner_id.jpg")
    String ownerIdPicUrl;
    @Schema(description = "URL or reference to the business license", example = "LICENSE-987654321")
    String businessLicense;
    @Schema(description = "List of categories the shop belongs to", example = "[\"Bakery\", \"Desserts\"]")
    List<String> categories;
    //many shops can be in one location
    @Schema(description = "Location information linking to coordinates and complete address")
    @ManyToOne(cascade = CascadeType.ALL)
    @JoinColumn(name="location_id",referencedColumnName = "id")
    LocationInfo locationInfo;

    public Shop() {
    }

    public Shop(long id, MyUser myUser, boolean isVerifiedByAdmin,
                String shopPicUrl, String phoneNumber, String address,
                String description,  String ownerName, String ownerPicUrl,
                String pancardPicUrl, String ownerIdPicUrl,
                String businessLicense, List<String> categories,
                LocationInfo locationInfo
                ) {
        this.id = id;
        this.myUser = myUser;
        this.isVerifiedByAdmin = isVerifiedByAdmin;
        this.shopPicUrl = shopPicUrl;
        this.phoneNumber = phoneNumber;
        this.address = address;
        this.description = description;
        this.createDate = Date.from(Instant.now());
        this.ownerName = ownerName;
        this.ownerPicUrl = ownerPicUrl;
        this.pancardPicUrl = pancardPicUrl;
        this.ownerIdPicUrl = ownerIdPicUrl;
        this.businessLicense = businessLicense;
        this.categories = categories;
        this.locationInfo = locationInfo;
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

    public boolean isVerifiedByAdmin() {
        return isVerifiedByAdmin;
    }

    public void setVerifiedByAdmin(boolean verifiedByAdmin) {
        isVerifiedByAdmin = verifiedByAdmin;
    }

    public String getShopPicUrl() {
        return shopPicUrl;
    }

    public void setShopPicUrl(String shopPicUrl) {
        this.shopPicUrl = shopPicUrl;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Date getCreateDate() {
        return createDate;
    }

    public void setCreateDate(Date createDate) {
        this.createDate = createDate;
    }

    public String getOwnerName() {
        return ownerName;
    }

    public void setOwnerName(String ownerName) {
        this.ownerName = ownerName;
    }

    public String getOwnerPicUrl() {
        return ownerPicUrl;
    }

    public void setOwnerPicUrl(String ownerPicUrl) {
        this.ownerPicUrl = ownerPicUrl;
    }

    public String getPancardPicUrl() {
        return pancardPicUrl;
    }

    public void setPancardPicUrl(String pancardPicUrl) {
        this.pancardPicUrl = pancardPicUrl;
    }

    public String getOwnerIdPicUrl() {
        return ownerIdPicUrl;
    }

    public void setOwnerIdPicUrl(String ownerIdPicUrl) {
        this.ownerIdPicUrl = ownerIdPicUrl;
    }

    public String getBusinessLicense() {
        return businessLicense;
    }

    public void setBusinessLicense(String businessLicense) {
        this.businessLicense = businessLicense;
    }

    public List<String> getCategories() {
        return categories;
    }

    public void setCategories(List<String> categories) {
        this.categories = categories;
    }

    public LocationInfo getLocationInfo() {
        return locationInfo;
    }

    public void setLocationInfo(LocationInfo locationInfo) {
        this.locationInfo = locationInfo;
    }
}
