package com.tecverse.app.controller;

import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.dto.RegistrationRequest;
import com.tecverse.app.dto.RegistrationResponse;
import com.tecverse.app.dto.TicketOtpSendRequest;
import com.tecverse.app.dto.TicketOtpVerifyRequest;
import com.tecverse.app.dto.TicketRegistrationRequest;
import com.tecverse.app.dto.TicketRegistrationResponse;
import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.exception.OtpVerificationRequiredException;
import com.tecverse.app.exception.DuplicateEmailException;
import com.tecverse.app.exception.DuplicatePhoneException;
import com.tecverse.app.response.ApiResponse;
import com.tecverse.app.security.OtpSessionVerification;
import com.tecverse.app.security.OtpSessionVerification.Purpose;
import com.tecverse.app.service.ExhibitorOtpService;
import com.tecverse.app.service.ExhibitorStorageService;
import com.tecverse.app.service.RegistrationService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.service.TicketRegistrationService;
import com.tecverse.app.service.QRCodeGeneratorService;
import com.tecverse.app.service.RateLimitService;
import jakarta.servlet.http.HttpServletRequest;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;

@Validated
@RestController
public class RegistrationController {
    private final RegistrationService registrationService;
    private final TicketOtpService ticketOtpService;
    private final TicketRegistrationService ticketRegistrationService;
    private final MessageSource messageSource;
    private final ExhibitorOtpService exhibitorOtpService;
    private final ExhibitorStorageService exhibitorStorageService;
    private final RateLimitService rateLimitService;
    private final QRCodeGeneratorService qrCodeGeneratorService;
    private final TicketRegistrationRepository ticketRegistrationRepository;
    private final String appUrl;

    public RegistrationController(RegistrationService registrationService, TicketOtpService ticketOtpService,
                                  TicketRegistrationService ticketRegistrationService, MessageSource messageSource, ExhibitorOtpService exhibitorOtpService, ExhibitorStorageService exhibitorStorageService, RateLimitService rateLimitService, QRCodeGeneratorService qrCodeGeneratorService, TicketRegistrationRepository ticketRegistrationRepository, @Value("${app.url:http://localhost:8080}") String appUrl) {
        this.registrationService=registrationService; this.ticketOtpService=ticketOtpService;
        this.ticketRegistrationService=ticketRegistrationService; this.messageSource=messageSource; this.exhibitorOtpService=exhibitorOtpService; this.exhibitorStorageService=exhibitorStorageService; this.rateLimitService=rateLimitService;
        this.qrCodeGeneratorService=qrCodeGeneratorService;
        this.ticketRegistrationRepository=ticketRegistrationRepository;
        this.appUrl=appUrl;
    }

    @PostMapping(value={"/register","/register.html"},consumes=MediaType.APPLICATION_JSON_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<RegistrationResponse>> register(@Valid @RequestBody RegistrationRequest request, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "exhibitor-registration", request.getEmail(), 5, Duration.ofHours(1), 20, Duration.ofHours(1));
        OtpSessionVerification.require(httpRequest, Purpose.EXHIBITOR, request.getEmail());
        String verifiedPhone = requireIndianMobile(request.getPhone());
        if (!OtpSessionVerification.isVerified(httpRequest, Purpose.EXHIBITOR_MOBILE, verifiedPhone)) {
            throw new OtpVerificationRequiredException("Please verify your mobile number with OTP before submitting.");
        }
        RegistrationResponse response = registrationService.register(request);
        OtpSessionVerification.consume(httpRequest, Purpose.EXHIBITOR);
        OtpSessionVerification.consume(httpRequest, Purpose.EXHIBITOR_MOBILE);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(message("api.registration.submitted"),response));
    }
    @PostMapping(value={"/register","/register.html"},consumes=MediaType.APPLICATION_FORM_URLENCODED_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<RegistrationResponse>> registerForm(@Valid @ModelAttribute RegistrationRequest request, HttpServletRequest httpRequest){return register(request, httpRequest);}
    @GetMapping(value={"/check-email","/check-email.html"},produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Boolean>> checkEmail(@RequestParam @Email @NotBlank @Size(max=254) String email, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "check-email", null, 0, Duration.ofMinutes(10), 20, Duration.ofMinutes(10));
        boolean exists=registrationService.checkEmailExists(email);
        return ResponseEntity.ok(ApiResponse.success(exists?message("api.email.registered"):message("api.email.available"),exists));
    }
    @GetMapping(value={"/check-phone","/check-phone.html"},produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Boolean>> checkPhone(@RequestParam @NotBlank @Size(max=32) String phone, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "check-phone", null, 0, Duration.ofMinutes(10), 20, Duration.ofMinutes(10));
        boolean exists=registrationService.checkPhoneExists(phone);
        return ResponseEntity.ok(ApiResponse.success(exists?message("api.phone.registered"):message("api.phone.available"),exists));
    }


    @PostMapping(value="/exhibitor/send-otp", consumes=MediaType.APPLICATION_JSON_VALUE, produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> exhibitorSendOtp(@RequestBody java.util.Map<String,String> body, HttpServletRequest httpRequest){
        String email = body.get("email"), name = body.get("name");
        if (email == null || email.length() > 254 || !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new IllegalArgumentException("Enter a valid official email address.");
        if (name == null || !name.matches("^[A-Za-z][A-Za-z .'-]{1,149}$")) throw new IllegalArgumentException("Enter a valid contact name.");
        rateLimitService.check(httpRequest, "otp-send", email, 3, Duration.ofMinutes(3), 30, Duration.ofMinutes(3));
        if (registrationService.checkEmailExists(email)) throw new DuplicateEmailException("This email is already registered.");
        String phone = body.get("phone");
        if (phone != null && !phone.isBlank() && registrationService.checkPhoneExists(requireIndianMobile(phone))) {
            throw new DuplicatePhoneException("This mobile number is already registered.");
        }
        rateLimitService.check(httpRequest, "exhibitor-email-otp-resend-cooldown", email,
                1, Duration.ofSeconds(60), 100, Duration.ofMinutes(1));
        exhibitorOtpService.send(email, name); return ResponseEntity.ok(ApiResponse.success("OTP sent to your official email."));
    }
    @PostMapping(value="/exhibitor/verify-otp", consumes=MediaType.APPLICATION_JSON_VALUE, produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> exhibitorVerifyOtp(@RequestBody java.util.Map<String,String> body, HttpServletRequest httpRequest){
        String email = body.get("email"), otp = body.get("otp");
        if (email == null || email.length() > 254 || !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new IllegalArgumentException("Enter a valid official email address.");
        if (otp == null || !otp.matches("^\\d{6}$")) throw new IllegalArgumentException("Enter the 6-digit OTP.");
        rateLimitService.check(httpRequest, "otp-verify", email, 5, Duration.ofMinutes(3), 60, Duration.ofMinutes(3));
        exhibitorOtpService.verify(email, otp);
        OtpSessionVerification.markVerified(httpRequest, Purpose.EXHIBITOR, email);
        return ResponseEntity.ok(ApiResponse.success("Official email verified."));
    }
    @PostMapping(value="/exhibitor/send-mobile-otp", consumes=MediaType.APPLICATION_JSON_VALUE, produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> exhibitorSendMobileOtp(@RequestBody java.util.Map<String,String> body, HttpServletRequest httpRequest){
        String phone = requireIndianMobile(body.get("phone"));
        rateLimitService.check(httpRequest, "exhibitor-sms-otp-send", phone, 3, Duration.ofMinutes(3), 20, Duration.ofMinutes(3));
        rateLimitService.check(httpRequest, "exhibitor-sms-otp-daily", phone, 10, Duration.ofDays(1), 100, Duration.ofDays(1));
        if (registrationService.checkPhoneExists(phone)) throw new DuplicatePhoneException("This mobile number is already registered.");
        rateLimitService.check(httpRequest, "exhibitor-sms-otp-resend-cooldown", phone,
                1, Duration.ofSeconds(60), 100, Duration.ofMinutes(1));
        ticketOtpService.sendExhibitorMobileOtp(phone);
        return ResponseEntity.ok(ApiResponse.success("OTP sent to your mobile number."));
    }
    @PostMapping(value="/exhibitor/verify-mobile-otp", consumes=MediaType.APPLICATION_JSON_VALUE, produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> exhibitorVerifyMobileOtp(@RequestBody java.util.Map<String,String> body, HttpServletRequest httpRequest){
        String phone = requireIndianMobile(body.get("phone")), otp = body.get("otp");
        if (otp == null || !otp.matches("^\\d{6}$")) throw new IllegalArgumentException("Enter the 6-digit OTP.");
        rateLimitService.check(httpRequest, "exhibitor-sms-otp-verify", phone, 5, Duration.ofMinutes(1), 60, Duration.ofMinutes(1));
        ticketOtpService.verifyMobileOtp(phone, otp);
        OtpSessionVerification.markVerified(httpRequest, Purpose.EXHIBITOR_MOBILE, phone);
        return ResponseEntity.ok(ApiResponse.success("Mobile number verified successfully."));
    }
    @PostMapping(value="/exhibitor/upload", consumes=MediaType.MULTIPART_FORM_DATA_VALUE, produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<String>> exhibitorUpload(@RequestParam("file") org.springframework.web.multipart.MultipartFile file, @RequestParam(value="reference",defaultValue="pending") @Size(max=100) String reference, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "exhibitor-upload", null, 0, Duration.ofHours(1), 10, Duration.ofHours(1));
        // Only a visitor who has verified an official email in this session may upload documents.
        if (!OtpSessionVerification.hasVerification(httpRequest, Purpose.EXHIBITOR)) {
            throw new OtpVerificationRequiredException("Please verify your official email with OTP before uploading documents.");
        }
        String savedPath = exhibitorStorageService.upload(file, reference);
        return ResponseEntity.ok(ApiResponse.success("Document uploaded successfully.", savedPath));
    }

    @PostMapping(value="/ticket/send-otp",consumes=MediaType.APPLICATION_JSON_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> sendTicketOtp(@Valid @RequestBody TicketOtpSendRequest request, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "otp-send", request.getEmail(), 3, Duration.ofMinutes(1), 30, Duration.ofMinutes(1));
        ticketOtpService.sendOtp(request); return ResponseEntity.ok(ApiResponse.success("OTP sent. Please check your email."));
    }
    @PostMapping(value="/ticket/verify-otp",consumes=MediaType.APPLICATION_JSON_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> verifyTicketOtp(@Valid @RequestBody TicketOtpVerifyRequest request, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "otp-verify", request.getEmail(), 5, Duration.ofMinutes(1), 60, Duration.ofMinutes(1));
        ticketOtpService.verifyOtp(request.getEmail(),request.getOtp());
        OtpSessionVerification.markVerified(httpRequest, Purpose.TICKET, request.getEmail());
        return ResponseEntity.ok(ApiResponse.success("OTP verified successfully."));
    }
    @PostMapping(value="/ticket/send-mobile-otp",consumes=MediaType.APPLICATION_JSON_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> sendTicketMobileOtp(@RequestBody java.util.Map<String,String> body, HttpServletRequest httpRequest){
        String phone = requireIndianMobile(body.get("phone"));
        // Each SMS costs money: tighter limits than email, plus a daily cap per number.
        rateLimitService.check(httpRequest, "sms-otp-send", phone, 3, Duration.ofMinutes(3), 20, Duration.ofMinutes(3));
        rateLimitService.check(httpRequest, "sms-otp-daily", phone, 10, Duration.ofDays(1), 100, Duration.ofDays(1));
        ticketOtpService.sendMobileOtp(phone);
        return ResponseEntity.ok(ApiResponse.success("OTP has been sent to your mobile number."));
    }
    @PostMapping(value="/ticket/verify-mobile-otp",consumes=MediaType.APPLICATION_JSON_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> verifyTicketMobileOtp(@RequestBody java.util.Map<String,String> body, HttpServletRequest httpRequest){
        String phone = requireIndianMobile(body.get("phone")), otp = body.get("otp");
        if (otp == null || !otp.matches("^\\d{6}$")) throw new IllegalArgumentException("Enter the 6-digit OTP.");
        rateLimitService.check(httpRequest, "sms-otp-verify", phone, 5, Duration.ofMinutes(1), 60, Duration.ofMinutes(1));
        ticketOtpService.verifyMobileOtp(phone, otp);
        OtpSessionVerification.markVerified(httpRequest, Purpose.TICKET_MOBILE, phone);
        return ResponseEntity.ok(ApiResponse.success("Mobile number verified successfully."));
    }
    private static String requireIndianMobile(String phone){
        if (phone == null || !phone.trim().matches("^(?:\\+91[-\\s]?)?[6-9]\\d{9}$")) throw new IllegalArgumentException("Enter a valid 10-digit Indian mobile number.");
        return com.tecverse.app.util.ValidationUtil.normalizeIndianMobile(phone.trim());
    }
    @PostMapping(value="/ticket/register",consumes=MediaType.APPLICATION_JSON_VALUE,produces=MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<TicketRegistrationResponse>> ticketRegister(@Valid @RequestBody TicketRegistrationRequest request, HttpServletRequest httpRequest){
        rateLimitService.check(httpRequest, "ticket-registration", request.getEmail(), 5, Duration.ofHours(1), 20, Duration.ofHours(1));
        OtpSessionVerification.require(httpRequest, Purpose.TICKET, request.getEmail());
        String phone = request.getPhone() == null ? "" : com.tecverse.app.util.ValidationUtil.normalizeIndianMobile(request.getPhone().trim());
        if (!OtpSessionVerification.isVerified(httpRequest, Purpose.TICKET_MOBILE, phone)) {
            throw new OtpVerificationRequiredException("Please verify your mobile number with OTP before submitting.");
        }
        TicketRegistrationResponse response = ticketRegistrationService.register(request);
        OtpSessionVerification.consume(httpRequest, Purpose.TICKET);
        OtpSessionVerification.consume(httpRequest, Purpose.TICKET_MOBILE);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success("Registration completed.",response));
    }

    @GetMapping(value="/ticket/qr",produces=MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> ticketQr(
            @RequestParam @NotBlank @Pattern(regexp="[a-f0-9]{32}") String token) throws java.io.IOException {
        if (ticketRegistrationRepository.findByScanToken(token).isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND,"Registration not found");
        }
        String scanUrl=appUrl.replaceAll("/+$", "")+"/ticket/scan/"+token;
        byte[] png = qrCodeGeneratorService.generateQRCodeImageBytes(scanUrl, 250, 250);
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_PNG)
                .cacheControl(org.springframework.http.CacheControl.noStore())
                .body(png);
    }

    @GetMapping(value="/ticket/scan/{token}",produces=MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> scanTicket(
            @org.springframework.web.bind.annotation.PathVariable @NotBlank @Pattern(regexp="[a-f0-9]{32}") String token) {
        TicketRegistration registration=ticketRegistrationRepository.findByScanToken(token)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND,"Registration not found"));
        String days=java.util.Arrays.stream(registration.getAttendanceDays().split(","))
                .map(String::trim)
                .map(day -> switch(day) {
                    case "DAY_1" -> "26 November 2026";
                    case "DAY_2" -> "27 November 2026";
                    case "BOTH" -> "26 and 27 November 2026";
                    default -> day;
                }).collect(java.util.stream.Collectors.joining(", "));
        // Resolve the logo against the host serving this scan page. app.url may point at
        // production while the same application is being tested on localhost.
        String logoUrl="/images/tecverselogo.png";
        String body="<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Registration verified | Tec-Verse 2026</title><style>body{margin:0;padding:24px;background:#f4f6fb;font:16px/1.5 system-ui,sans-serif;color:#18233b}.card{max-width:440px;margin:6vh auto;background:white;border-radius:18px;overflow:hidden;box-shadow:0 16px 40px #13214a1a}.head{padding:24px;text-align:center;background:linear-gradient(135deg,#0b2852,#5125b9);color:white}.head img{width:58px;height:58px;object-fit:contain;background:white;border-radius:50%;padding:5px}.head h1{font-size:22px;margin:12px 0 0}.body{padding:20px 24px}.row{padding:12px 0;border-bottom:1px solid #edf0f6}.label{display:block;font-size:12px;text-transform:uppercase;letter-spacing:.08em;color:#68728a}.value{display:block;font-weight:650;overflow-wrap:anywhere}.foot{text-align:center;padding:0 20px 20px;color:#68728a;font-size:13px}</style></head><body><main class=\"card\"><header class=\"head\"><img src=\""+htmlEscape(logoUrl)+"\" alt=\"Tec-Verse\"><h1>Registration verified</h1></header><section class=\"body\">"
                +scanRow("Name",registration.getOfficialName())+scanRow("Email",registration.getEmail())
                +scanRow("Reference",registration.getReferenceNumber())+scanRow("Preferred days",days)
                +scanRow("Venue","Chennai Trade Centre, Chennai")
                +"</section><footer class=\"foot\">Password is not displayed for account security.</footer></main></body></html>";
        return ResponseEntity.ok().contentType(MediaType.TEXT_HTML).cacheControl(org.springframework.http.CacheControl.noStore()).body(body);
    }
    private static String scanRow(String label,String value) {
        return "<div class=\"row\"><span class=\"label\">"+htmlEscape(label)+"</span><span class=\"value\">"+htmlEscape(value==null?"":value)+"</span></div>";
    }
    private static String htmlEscape(String value) {
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
    private String message(String code){return messageSource.getMessage(code,null,LocaleContextHolder.getLocale());}
}
