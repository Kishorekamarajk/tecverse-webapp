package com.tecverse.app.config;

import java.io.IOException;

import org.springframework.boot.jackson.JsonComponent;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.tecverse.app.util.ValidationUtil;

/** Applies the same markup rejection to strings submitted in JSON request bodies. */
@JsonComponent
public class UserInputStringDeserializer extends JsonDeserializer<String> {

    @Override
    public String deserialize(JsonParser parser, DeserializationContext context) throws IOException {
        String value = parser.getValueAsString();
        if (ValidationUtil.containsUnsafeMarkup(value)) {
            throw JsonMappingException.from(parser, "HTML tags and script input are not allowed.");
        }
        return value;
    }
}
