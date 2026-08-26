package com.saqib.localezy.repository;

import com.saqib.localezy.entity.ProductCategory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductCategoryRepository  extends JpaRepository<ProductCategory, Long> {
}
