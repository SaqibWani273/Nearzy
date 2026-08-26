package com.saqib.localezy.record;

import java.util.List;
import java.util.Map;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Record for updating the items in a customer's cart")
public record UpdateCartItemsRecord(
        @Schema(description = "List of items to update in the cart", example = "[{\"productId\": 1, \"quantity\": 2}]")
        List<Map<String, Object>> cartItems,
        @Schema(description = "ID of the customer whose cart is being updated", example = "1")
        Long customerId
) {
}
