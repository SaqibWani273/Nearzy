package com.saqib.localezy.entity;

import com.saqib.localezy.configuration.JpaConverterJSON;
import jakarta.persistence.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

import java.util.List;
import java.util.Map;

@Schema(description = "Product available for sale in a shop")
@Entity
@Getter @Setter @NoArgsConstructor @ToString
public class Product {
    @Schema(description = "Unique identifier for the product", example = "500", accessMode = Schema.AccessMode.READ_ONLY)
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    long id;
     @Schema(description = "Name of the product", example = "Wireless Headphones")
     String name;
     @Schema(description = "Brand of the product", example = "Sony")
     String brand;
     @Schema(description = "Short summary description", example = "Noise-cancelling wireless headphones")
     String shortDescription;
     @Schema(description = "List of image URLs for the product", example = "[\"https://example.com/headphone1.jpg\"]")
     List<String> images;
     @Schema(description = "Price of the product in the base currency unit", example = "29900")
     int price;
     @Schema(description = "Discount percentage applied to the price", example = "10.0")
     double discountInPercentage;
     @Schema(description = "Complete and detailed description", example = "These wireless headphones offer industry-leading noise cancellation...")
     String completeDescription;
     @Schema(description = "The shop selling this product")
     @JoinColumn(name="shop_id",referencedColumnName = "id")
             @ManyToOne
     Shop shop;
     @Schema(description = "Number of items currently in stock", example = "50")
     int stockQuantity;
     @Schema(description = "Average customer rating", example = "4.5")
     double rating;
    @Schema(description = "Product category details in JSON format", example = "{\"id\": 1, \"name\": \"Electronics\"}")
    @Convert(converter = JpaConverterJSON.class)
    @Column( length = 65000)
    Map<String,Object> category;
    @Schema(description = "Available colors for the product", example = "[\"Black\", \"Silver\"]")
    List<String> colors;

    @Schema(description = "Whether the product is currently available for purchase", example = "true")
    boolean available;

//     List<ProductReview>? reviews;
    @Schema(description = "Stock Keeping Unit identifier", example = "SONY-WH1000XM4-BLK")
    String sku;

    public Product(String name, String brand, String shortDescription,
                   List<String> images, int price, double discountInPercentage,
                   String completeDescription, Shop shop, int stockQuantity,
                   double rating, Map<String, Object> category,
                   List<String> colors, boolean available, String sku) {
        this.name = name;
        this.brand = brand;
        this.shortDescription = shortDescription;
        this.images = images;
        this.price = price;
        this.discountInPercentage = discountInPercentage;
        this.completeDescription = completeDescription;
        this.shop = shop;
        this.stockQuantity = stockQuantity;
        this.rating = rating;
        this.category = category;
        this.colors = colors;
        this.available = available;
        this.sku = sku;
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public List<String> getImages() {
        return images;
    }

    public void setImages(List<String> images) {
        this.images = images;
    }

    public int getPrice() {
        return price;
    }

    public void setPrice(int price) {
        this.price = price;
    }

    public double getDiscountInPercentage() {
        return discountInPercentage;
    }

    public void setDiscountInPercentage(double discountInPercentage) {
        this.discountInPercentage = discountInPercentage;
    }

    public String getCompleteDescription() {
        return completeDescription;
    }

    public void setCompleteDescription(String completeDescription) {
        this.completeDescription = completeDescription;
    }

    public Shop getShop() {
        return shop;
    }

    public void setShop(Shop shop) {
        this.shop = shop;
    }

    public int getStockQuantity() {
        return stockQuantity;
    }

    public void setStockQuantity(int stockQuantity) {
        this.stockQuantity = stockQuantity;
    }

    public double getRating() {
        return rating;
    }

    public void setRating(double rating) {
        this.rating = rating;
    }

    public Map<String, Object> getCategory() {
        return category;
    }

    public void setCategory(Map<String, Object> category) {
        this.category = category;
    }

    public List<String> getColors() {
        return colors;
    }

    public void setColors(List<String> colors) {
        this.colors = colors;
    }

    public boolean isAvailable() {
        return available;
    }

    public void setAvailable(boolean available) {
        this.available = available;
    }

    public String getSku() {
        return sku;
    }

    public void setSku(String sku) {
        this.sku = sku;
    }
}
