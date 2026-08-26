package com.saqib.localezy.security;

import com.saqib.localezy.service.jwt.JwtAuthFilterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

@Autowired
    private UserDetailsService myUserDetailsService;
    @Autowired
    private JwtAuthFilterService jwtAuthFilterService;


    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(configurer
                ->configurer
                .requestMatchers(HttpMethod.POST, "/customer/register","/customer/login",
                        "admin/register","admin/login","shop/register",
                        "shop/login", "admin/test-post","admin/verify-email",
                        "user/email-exists","user/username-exists","user/phone-exists"

                        ).permitAll()
                .requestMatchers(HttpMethod.GET, "/customer/verify-email",
                        "/admin/verify-email","/shop/verify-email","admin/test-get",
                        "user/test","user/get-all-categories","/customer/get-all-products",
                        "/health",
                        "/swagger-ui/**", "/swagger-ui.html",
                        "/v3/api-docs/**", "/v3/api-docs.yaml").permitAll()
                .requestMatchers(HttpMethod.POST,"customer/me","customer/update",
                        "customer/update-cart-items","customer/get-products-by-ids").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.POST,"shop/me","shop/add-product").hasRole("SHOP")
                        .requestMatchers(HttpMethod.POST,"admin/add-category").hasRole("ADMIN")
                                .requestMatchers(HttpMethod.POST,"user/me").hasAnyRole("CUSTOMER","SHOP")
//                                .requestMatchers(HttpMethod.GET,"user/get-all-categories").hasAnyRole("CUSTOMER","SHOP")
                .anyRequest().hasRole("ADMIN")
                )
                //add jwt filter before security filter to authenticate users
                //using jwt token
                .addFilterBefore(jwtAuthFilterService, UsernamePasswordAuthenticationFilter.class);;
        http.csrf(csrf->csrf.disable());
//        http.cors();
//        http.cors(cors->cors.disable());
        //use basic authentication
        http.httpBasic(Customizer.withDefaults());
        return http.build();
    }
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    //for user authentication
    @Bean
    public AuthenticationProvider authenticationProvider(){
        DaoAuthenticationProvider daoAuthenticationProvider = new DaoAuthenticationProvider();
        daoAuthenticationProvider.setUserDetailsService(userDetailsService());
        daoAuthenticationProvider.setPasswordEncoder(passwordEncoder());
        return daoAuthenticationProvider;
    }

    private UserDetailsService userDetailsService() {
        return myUserDetailsService;
    }

    @Bean
    public AuthenticationManager authenticationManager(){
        return  new ProviderManager(authenticationProvider());
    }


}
