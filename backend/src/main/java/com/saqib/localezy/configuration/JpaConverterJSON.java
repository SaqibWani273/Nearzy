package com.saqib.localezy.configuration;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.HashMap;
import java.util.Map;

@Converter(autoApply = true)
public class JpaConverterJSON implements AttributeConverter<Map<String,Object>,String> {
    @Override
    public String    convertToDatabaseColumn(Map<String, Object> map) {
       String mapString=null;
        try{
mapString= new ObjectMapper().writeValueAsString(map);
        }
        catch (Exception e){
            e.printStackTrace();
        }
        return mapString;
    }



    @Override
    public Map<String, Object> convertToEntityAttribute(String dbString) {
        Map<String, Object> map= null;
        try{
            map = new ObjectMapper().readValue(dbString, new TypeReference<HashMap<String, Object>>() {});
        }
        catch (Exception e){
            e.printStackTrace();
        }
        return map;
    }
}
