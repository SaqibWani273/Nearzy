package com.saqib.localezy.repository;

import com.saqib.localezy.entity.LocationInfo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LocationInfoRepository  extends JpaRepository<LocationInfo,Long> {
}
