package com.saqib.localezy.record;

import com.saqib.localezy.entity.MyUser;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Record for creating a new admin account")
public record AdminPasswordRecord(
        @Schema(description = "The user details for the new admin")
        MyUser myUser,
        @Schema(description = "Secret code required for admin registration", example = "SECRET_ADMIN_123", accessMode = Schema.AccessMode.WRITE_ONLY)
        String secretCode
) {
}
