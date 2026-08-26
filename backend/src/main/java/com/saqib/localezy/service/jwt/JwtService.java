package com.saqib.localezy.service.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.sql.Date;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class JwtService {
    @Autowired
    private Environment env;

    @Value("${security.jwt.secret-key}")
    private  String secretKey;
//  private  final  String secretKey = env.getProperty("security.jwt.secret-key");
    private static final long expInMilis= TimeUnit.HOURS.toMillis(48);

    //method used to generate token at login
    public String generateToken(UserDetails user){

// additional data can be added  to the token through claims
        System.out.println("user authorities-> "+user.getAuthorities());
        Map<String,String> claims=new HashMap<>();
        claims.put("name",user.getUsername());

        claims.put("role",user.getAuthorities().stream().map(GrantedAuthority::getAuthority).findFirst().get());
//        claims.put("role",)
        return Jwts.builder()
                .claims(claims)
                .subject(user.getUsername())
                .issuedAt(Date.from(Instant.now()))
                .expiration(Date.from(Instant.now().plusMillis(expInMilis)))
                .signWith(generateKey()).compact();

    }
    private SecretKey generateKey(){
        byte[] byteKey= Base64.getDecoder().decode(secretKey);
        return Keys.hmacShaKeyFor(byteKey);
    }
    //methods used for verfication after login
    public Claims extractClaims(String token){

        return Jwts
                .parser()
                .verifyWith(generateKey()).build()
                .parseSignedClaims(token).getPayload();
    }
    public boolean isTokenValid(String token){

        return extractClaims(token).getExpiration().after(Date.from(Instant.now()));
    }
    //we can extract email from the token
    //as we've set username to email in loadUserByUsername() of CustomerDetailsService class
    //and then set the subject to username above in generateToken()
    public String extractEmail(String token){
        Claims claims=extractClaims(token);
        return  claims.getSubject();
    }
}
