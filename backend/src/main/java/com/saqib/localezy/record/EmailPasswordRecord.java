package com.saqib.localezy.record;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Record for email and password based authentication")
public record EmailPasswordRecord(
        @Schema(description = "User's email address", example = "johndoe@example.com")
        String email,
        @Schema(description = "User's password", example = "Password123!", accessMode = Schema.AccessMode.WRITE_ONLY)
        String password
) {
}
