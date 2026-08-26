package com.saqib.localezy.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Geographical location information including coordinates and address")
@NoArgsConstructor @AllArgsConstructor
@Entity @Getter @Setter
public class LocationInfo {

    @Schema(description = "Unique identifier for the location info", example = "1", accessMode = Schema.AccessMode.READ_ONLY)
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    long id;

    @Schema(description = "Short formatted address", example = "Downtown")
    String shortAddress;
    @Schema(description = "Latitude coordinate", example = "40.7128")
    double latitude;
    @Schema(description = "Longitude coordinate", example = "-74.0060")
    double longtitude;
    @Schema(description = "Complete detailed address", example = "123 Main St, New York, NY 10001, USA")
    String completeAddress;
//
//    public String getShortAddress() {
//        return shortAddress;
//    }
//
//    public void setShortAddress(String shortAddress) {
//        this.shortAddress = shortAddress;
//    }
//
//    public String getLatitude() {
//        return latitude;
//    }
//
//    public void setLatitude(String latitude) {
//        this.latitude = latitude;
//    }
//
//    public String getLongtitude() {
//        return longtitude;
//    }
//
//    public void setLongtitude(String longtitude) {
//        this.longtitude = longtitude;
//    }
//
//    public String getCompleteAddress() {
//        return completeAddress;
//    }
//
//    public void setCompleteAddress(String completeAddress) {
//        this.completeAddress = completeAddress;
//    }
}
