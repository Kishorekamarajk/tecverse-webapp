package com.tecverse.app.service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;

@Service
public class AttendeeCaptchaService {
    private record Challenge(String answer, Instant expiresAt) {}
    private final SecureRandom random = new SecureRandom();
    private final Map<String, Challenge> challenges = new ConcurrentHashMap<>();
    public Map<String,String> issue() {
        cleanup(); int a=random.nextInt(9)+1, b=random.nextInt(9)+1; String id=UUID.randomUUID().toString();
        challenges.put(id,new Challenge(Integer.toString(a+b),Instant.now().plusSeconds(300)));
        return Map.of("id",id,"question",a+" + "+b+" = ?");
    }
    public boolean consume(String id,String answer) {
        Challenge c=id==null?null:challenges.remove(id);
        return c!=null && c.expiresAt().isAfter(Instant.now()) && answer!=null && c.answer().equals(answer.trim());
    }
    private void cleanup(){Instant now=Instant.now();challenges.entrySet().removeIf(e->!e.getValue().expiresAt().isAfter(now));}
}
