package com.saqib.localezy.repository;

import com.saqib.localezy.entity.EmailConfirmation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface  EmailConfirmationRepository  extends JpaRepository<EmailConfirmation, Long> {

    EmailConfirmation findByToken(String token);

}
