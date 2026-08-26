package com.saqib.localezy.exception_handler;

import jakarta.persistence.PersistenceException;
import jakarta.persistence.UniqueConstraint;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@ControllerAdvice
public class RestExceptionHandler {
//    @ExceptionHandler
//    public ResponseEntity<String> handleException(Exception e) {
//return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
//    }

@ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ResponseBody
    public ApiError handleAll(Exception e) {
        ApiError apiError = new ApiError();
        apiError.setMessage(e.getMessage());
        apiError.setStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        apiError.setError(e.getClass().getName());
        return apiError;
    }
@ExceptionHandler(DataIntegrityViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public ApiError handleDataIntegrityViolationException(DataIntegrityViolationException e) {
        ApiError apiError = new ApiError();

        apiError.setMessage(e.getMessage()==null?"Duplicate Entry":e.getMessage());
        apiError.setStatus(HttpStatus.UNPROCESSABLE_ENTITY);
        apiError.setError(e.getClass().getName());
        return apiError;
    }
    @ExceptionHandler(PersistenceException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public ApiError handlePersistenceException(PersistenceException e) {
        ApiError apiError = new ApiError();
        apiError.setMessage(e.getMessage()==null?"Database Persistence Error":e.getMessage());
        apiError.setStatus(HttpStatus.UNPROCESSABLE_ENTITY);
        apiError.setError(e.getClass().getName());
        return apiError;
    }



}
