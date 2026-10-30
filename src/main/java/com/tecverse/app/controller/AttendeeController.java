package com.tecverse.app.controller;

import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.service.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.time.Duration;
import java.util.Map;
import java.util.Objects;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Controller
public class AttendeeController {
    private final MobileSessionService sessions; private final AttendeeCaptchaService captcha; private final RateLimitService limits; private final ThematicReservationService reservations; private final FaqService faqService; private final Duration sessionLifetime;
    public AttendeeController(MobileSessionService sessions,AttendeeCaptchaService captcha,RateLimitService limits,ThematicReservationService reservations,FaqService faqService,@org.springframework.beans.factory.annotation.Value("${tecverse.mobile.session-ttl:PT12H}") Duration sessionLifetime){this.sessions=sessions;this.captcha=captcha;this.limits=limits;this.reservations=reservations;this.faqService=faqService;this.sessionLifetime=sessionLifetime;}
    @GetMapping("/auth") public String auth(){return "auth-selection";}
    @GetMapping("/login") public String login(){return "redirect:/?login=1";}
    @GetMapping("/auth/captcha") @ResponseBody public Map<String,String> loginCaptcha(){return captcha.issue();}
    @PostMapping("/login") public String authenticate(@RequestParam String email,@RequestParam String password,@RequestParam String captchaId,@RequestParam String captchaAnswer,HttpServletRequest request,HttpServletResponse response,org.springframework.web.servlet.mvc.support.RedirectAttributes flash){
        try{limits.check(request,"attendee-login",email==null?null:email.trim().toLowerCase(),5,Duration.ofMinutes(15),30,Duration.ofMinutes(15));if(!captcha.consume(captchaId,captchaAnswer))throw new IllegalArgumentException("CAPTCHA is invalid or expired. Please try again.");Map<String,Object> result=sessions.login(email==null?null:email.trim().toLowerCase(),password);String token=Objects.toString(result.get("accessToken"));var cookie=org.springframework.http.ResponseCookie.from("TECVERSE_ATTENDEE",token).httpOnly(true).secure(request.isSecure()).sameSite("Lax").path("/").maxAge(sessionLifetime).build();response.addHeader(HttpHeaders.SET_COOKIE,cookie.toString());return "redirect:/dashboard";}catch(RuntimeException error){flash.addFlashAttribute("loginError",error instanceof IllegalArgumentException?error.getMessage():"Unable to sign in. Please check your details and try again.");return "redirect:/?login=1";}}
    @GetMapping("/dashboard") public String dashboard(@CookieValue(value="TECVERSE_ATTENDEE",required=false) String token,Model model,HttpServletResponse response){response.setHeader("Cache-Control","no-store");TicketRegistration attendee=require(token);model.addAttribute("attendee",attendee);model.addAttribute("attendeeCategoryLabel",displayLabel(attendee.getCategory()));model.addAttribute("attendeeSignedIn",true);model.addAttribute("attendeeOrganization",firstNonBlank(attendee.getCollegeName(),attendee.getUniversityName(),attendee.getOrganizationName(),attendee.getCentralMinistry(),attendee.getStateDepartment()));model.addAttribute("attendeeDesignation",firstNonBlank(attendee.getDesignation(),attendee.getAcademiaRole()));model.addAttribute("reservations",reservations.myReservations(attendee.getId()));model.addAttribute("sessions",reservations.publicSessions(attendee.getId()));model.addAttribute("registrationDays",displayLabel(attendee.getAttendanceDays()));model.addAttribute("registrationStatus","Registered");model.addAttribute("participantFaqs",faqService.activeFaqs(FaqService.PARTICIPANT));return "attendee-dashboard";}
    @PostMapping("/logout") public String logout(@CookieValue(value="TECVERSE_ATTENDEE",required=false) String token,HttpServletRequest request,HttpServletResponse response){sessions.logoutToken(token);response.addHeader(HttpHeaders.SET_COOKIE,org.springframework.http.ResponseCookie.from("TECVERSE_ATTENDEE","").httpOnly(true).secure(request.isSecure()).sameSite("Lax").path("/").maxAge(Duration.ZERO).build().toString());return "redirect:/login?logout";}
    @PostMapping("/dashboard/sessions/{id}") public String reserve(@CookieValue(value="TECVERSE_ATTENDEE",required=false) String token,@PathVariable Long id,org.springframework.web.servlet.mvc.support.RedirectAttributes flash){TicketRegistration attendee=require(token);try{reservations.reserve(attendee.getId(),id);flash.addFlashAttribute("successMessage","Session reserved.");}catch(RuntimeException e){flash.addFlashAttribute("errorMessage",e.getMessage());}return "redirect:/dashboard#sessions";}
    @PostMapping("/dashboard/reservations/{id}/cancel") public String cancel(@CookieValue(value="TECVERSE_ATTENDEE",required=false) String token,@PathVariable Long id,org.springframework.web.servlet.mvc.support.RedirectAttributes flash){TicketRegistration attendee=require(token);try{reservations.cancel(attendee.getId(),id);flash.addFlashAttribute("successMessage","Reservation cancelled.");}catch(RuntimeException e){flash.addFlashAttribute("errorMessage",e.getMessage());}return "redirect:/dashboard#sessions";}
    private TicketRegistration require(String token){try{return sessions.requireToken(token);}catch(RuntimeException e){throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,"Please sign in to continue.");}}
    private static String firstNonBlank(String... values){for(String value:values)if(value!=null&&!value.isBlank())return value;return "Not provided";}
    private static String displayLabel(String value){return value==null?"":value.replace('_',' ').toLowerCase(java.util.Locale.ENGLISH);}
}
