package com.tecverse.app;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.tecverse.app.security.OtpSessionVerification;

/** Guards the security and Play-Store-readiness fixes against regressions. */
@SpringBootTest
@AutoConfigureMockMvc
class ProductionReadinessTest {

    @Autowired
    MockMvc mvc;

    @Test
    void privacyPolicyAndAccountDeletionPagesArePublic() throws Exception {
        mvc.perform(get("/privacy-policy")).andExpect(status().isOk())
                .andExpect(content().string(Matchers.containsString("Privacy Policy")));
        mvc.perform(get("/account-deletion")).andExpect(status().isOk())
                .andExpect(content().string(Matchers.containsString("Delete your TEC-VERSE account")));
    }

    @Test
    void trustedProxyRestoresHttpsForRedirectsAndHsts() throws Exception {
        MvcResult result = mvc.perform(get("/admin").with(request -> {
                    request.setRemoteAddr("10.1.2.3");
                    request.addHeader("X-Forwarded-Proto", "https");
                    request.addHeader("X-Forwarded-Host", "events.example.in");
                    return request;
                }))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().exists("Strict-Transport-Security"))
                .andReturn();
        assertThat(result.getResponse().getRedirectedUrl()).startsWith("https://events.example.in/");
    }

    @Test
    void forwardedHeadersFromUntrustedClientsAreIgnored() throws Exception {
        MvcResult result = mvc.perform(get("/admin").with(request -> {
                    request.setRemoteAddr("203.0.113.9");
                    request.addHeader("X-Forwarded-Proto", "https");
                    request.addHeader("X-Forwarded-Host", "attacker.example");
                    return request;
                }))
                .andExpect(status().is3xxRedirection())
                .andReturn();
        assertThat(result.getResponse().getRedirectedUrl()).doesNotContain("attacker.example");
    }

    @Test
    void ticketDetailsStepRequiresServerSideOtpVerification() throws Exception {
        mvc.perform(get("/ticket/details-step")).andExpect(status().isForbidden());

        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setSession(new MockHttpSession());
        OtpSessionVerification.markVerified(req, OtpSessionVerification.Purpose.TICKET, "visitor@example.in");
        // Mobile OTP verification is disabled for now, so email verification alone releases step 2.
        // Restore these lines when the mobile check in PageController.ticketDetailsStep is re-enabled.
        // mvc.perform(get("/ticket/details-step").session((MockHttpSession) req.getSession()))
        //         .andExpect(status().isForbidden());
        // OtpSessionVerification.markVerified(req, OtpSessionVerification.Purpose.TICKET_MOBILE, "9876543210");
        mvc.perform(get("/ticket/details-step").session((MockHttpSession) req.getSession()))
                .andExpect(status().isOk())
                .andExpect(content().string(Matchers.containsString("id=\"detailsForm\"")));
    }

    @Test
    void forgedGatePassBasedOnReferenceNumberIsRejected() throws Exception {
        mvc.perform(post("/api/mobile/pass/verify").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"qrToken\":\"TECVERSE26:TV26VI000003\"}"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void mobileLoginIsRateLimitedPerAccount() throws Exception {
        String body = "{\"identifier\":\"ratelimit-test@example.in\",\"password\":\"Wrong#Pass1\"}";
        int last = 0;
        for (int i = 0; i < 6; i++) {
            last = mvc.perform(post("/api/mobile/auth/login").contentType(MediaType.APPLICATION_JSON).content(body)
                            .with(request -> { request.setRemoteAddr("198.51.100.77"); return request; }))
                    .andReturn().getResponse().getStatus();
        }
        assertThat(last).isEqualTo(429);
    }

    @Test
    void passwordResetWithoutResetTokenIsRejected() throws Exception {
        mvc.perform(post("/api/mobile/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"someone@example.in\",\"newPassword\":\"New#Pass123\",\"confirmPassword\":\"New#Pass123\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void exhibitorUploadRequiresVerifiedEmail() throws Exception {
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart("/exhibitor/upload")
                        .file("file", "%PDF-1.4".getBytes())
                        .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf()))
                .andExpect(status().isForbidden());
    }
}
