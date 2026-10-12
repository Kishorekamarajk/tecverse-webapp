package com.tecverse.app.service;

import com.tecverse.app.dto.RegistrationRequest;
import com.tecverse.app.dto.RegistrationResponse;

/**
 * Business operations behind the exhibitor registration flow: submission and the
 * AJAX duplicate-check endpoints.
 */
public interface RegistrationService {

    RegistrationResponse register(RegistrationRequest request);

    boolean checkEmailExists(String email);

    boolean checkPhoneExists(String phone);
}
