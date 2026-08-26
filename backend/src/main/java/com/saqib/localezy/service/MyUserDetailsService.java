package com.saqib.localezy.service;

import com.saqib.localezy.entity.Admin;
import com.saqib.localezy.entity.Customer;
import com.saqib.localezy.entity.MyUser;
import com.saqib.localezy.repository.AdminRepository;
import com.saqib.localezy.repository.CustomerRepository;
import com.saqib.localezy.repository.MyUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Optional;


@Service
public class MyUserDetailsService implements UserDetailsService {
    @Autowired
private MyUserRepository myUserRepository;


    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
Optional<MyUser> myUser=   myUserRepository.findByEmail(email);
if(myUser.isEmpty()){
    throw new UsernameNotFoundException(email);
}
return User.builder()
        .username(myUser.get().getEmail())
        .password(myUser.get().getPassword())
        .roles(myUser.get().getRoles()).build();
    }

}