package com.saqib.localezy.service.jwt;

import com.saqib.localezy.service.MyUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Service;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

//every request will pass through this filter first and
//check for token in the header and if it has a token in header
//we'll extract username from token and check if user is in database
//and set authenticated accordingly and those endpoints that need client
//to be authenticated will be protected

@Service
public class JwtAuthFilterService extends OncePerRequestFilter {

    @Autowired
    JwtService jwtService;

    @Autowired
    MyUserDetailsService myUserDetailsService;
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
String auhtHeader = request.getHeader("Authorization");
if(auhtHeader==null||!auhtHeader.startsWith("Bearer ")){
//  Allow request to proceed for invalid/missing token to avoid DoS attacks.
//  Authorization will be handled at the endpoint level.

    filterChain.doFilter(request,response);
    return;
}

String token = auhtHeader.substring(7);
String email= jwtService.extractEmail(token);
        if(email!=null &&
                // to proceed only if currently user is not authenticated
                SecurityContextHolder.getContext().getAuthentication()==null)
        {
            //do not get confused my name of this method, we've used email
            //in the parameter at the method definition
            UserDetails userDetails = myUserDetailsService.loadUserByUsername(email);
if(userDetails!=null && jwtService.isTokenValid(token)){
    UsernamePasswordAuthenticationToken authToken= new UsernamePasswordAuthenticationToken(
            email,userDetails.getPassword(),userDetails.getAuthorities());
    //to set the client details for security purposes
    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
    //set user as authenticated
    SecurityContextHolder.getContext().setAuthentication(authToken);

}
        }
filterChain.doFilter(request,response);
    }
}
