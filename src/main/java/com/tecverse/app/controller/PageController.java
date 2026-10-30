package com.tecverse.app.controller;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.context.MessageSource;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.dao.DataIntegrityViolationException;
import static org.springframework.http.HttpStatus.NOT_FOUND;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.server.ResponseStatusException;

import com.tecverse.app.entity.ConferenceScheduleItem;
import com.tecverse.app.entity.ContactUs;
import com.tecverse.app.entity.NewsUpdate;
import com.tecverse.app.entity.SponsorEnquiry;
import com.tecverse.app.event.SponsorEnquirySavedEvent;
import com.tecverse.app.entity.ThematicDomainCard;
import com.tecverse.app.repository.ChiefGuestRepository;
import com.tecverse.app.repository.ConferenceScheduleItemRepository;
import com.tecverse.app.repository.ContactUsRepository;
import com.tecverse.app.repository.ImportantDateRepository;
import com.tecverse.app.repository.NewsUpdateRepository;
import com.tecverse.app.repository.SpeakerRepository;
import com.tecverse.app.repository.GalleryVideoRepository;
import com.tecverse.app.repository.SponsorEnquiryRepository;
import com.tecverse.app.repository.ThematicDomainCardRepository;
import com.tecverse.app.repository.ExhibitorLogoRepository;
import com.tecverse.app.service.FaqService;
import com.tecverse.app.service.MediaCoverageService;
import com.tecverse.app.security.OtpSessionVerification;
import com.tecverse.app.service.SponsorOtpService;
import com.tecverse.app.service.GalleryStorageService;
import com.tecverse.app.service.RateLimitService;
import com.tecverse.app.exception.RateLimitExceededException;
import com.tecverse.app.util.Constants;
import com.tecverse.app.util.ValidationUtil;
import com.tecverse.app.dto.InquiryForm;
import com.tecverse.app.util.ContactPhoneNumbers;
import com.tecverse.app.validator.InquiryFormValidator;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.InitBinder;
import com.tecverse.app.validator.IndianMobile;

import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.web.multipart.MultipartFile;

@Controller
public class PageController {

    private static final String CONTACT_CAPTCHA_ANSWER = "CONTACT_CAPTCHA_ANSWER";
    private static final String CONTACT_CAPTCHA_QUESTION = "CONTACT_CAPTCHA_QUESTION";
    private static final SecureRandom CAPTCHA_RANDOM = new SecureRandom();

    private final com.tecverse.app.repository.GalleryImageRepository galleryImageRepository;
    private final GalleryVideoRepository galleryVideoRepository;
    private final ContactUsRepository contactUsRepository;
    private final SponsorEnquiryRepository sponsorEnquiryRepository;
    private final ChiefGuestRepository chiefGuestRepository;
    private final ConferenceScheduleItemRepository conferenceScheduleItemRepository;
    private final ImportantDateRepository importantDateRepository;
    private final NewsUpdateRepository newsUpdateRepository;
    private final SpeakerRepository speakerRepository;
    private final ThematicDomainCardRepository thematicDomainCardRepository;
    private final ExhibitorLogoRepository exhibitorLogoRepository;
    private final FaqService faqService;
    private final MediaCoverageService mediaCoverageService;
    private final SponsorOtpService sponsorOtpService;
    private final RateLimitService rateLimitService;
    private final MessageSource messageSource;
    private final GalleryStorageService galleryStorageService;
    private final ApplicationEventPublisher eventPublisher;

    public PageController(com.tecverse.app.repository.GalleryImageRepository galleryImageRepository,
                          GalleryVideoRepository galleryVideoRepository,
                          ContactUsRepository contactUsRepository,
                          SponsorEnquiryRepository sponsorEnquiryRepository,
                          ChiefGuestRepository chiefGuestRepository,
                          ConferenceScheduleItemRepository conferenceScheduleItemRepository,
                          ImportantDateRepository importantDateRepository,
                          NewsUpdateRepository newsUpdateRepository,
                          SpeakerRepository speakerRepository,
                          ThematicDomainCardRepository thematicDomainCardRepository,
                          ExhibitorLogoRepository exhibitorLogoRepository,
                          FaqService faqService,
                          MediaCoverageService mediaCoverageService,
                          SponsorOtpService sponsorOtpService,
                          MessageSource messageSource,
                          RateLimitService rateLimitService,
                          GalleryStorageService galleryStorageService,
                          ApplicationEventPublisher eventPublisher) {
        this.galleryImageRepository = galleryImageRepository;
        this.galleryVideoRepository = galleryVideoRepository;
        this.contactUsRepository = contactUsRepository;
        this.sponsorEnquiryRepository = sponsorEnquiryRepository;
        this.chiefGuestRepository = chiefGuestRepository;
        this.conferenceScheduleItemRepository = conferenceScheduleItemRepository;
        this.importantDateRepository = importantDateRepository;
        this.newsUpdateRepository = newsUpdateRepository;
        this.speakerRepository = speakerRepository;
        this.thematicDomainCardRepository = thematicDomainCardRepository;
        this.exhibitorLogoRepository = exhibitorLogoRepository;
        this.faqService = faqService;
        this.mediaCoverageService = mediaCoverageService;
        this.sponsorOtpService = sponsorOtpService;
        this.messageSource = messageSource;
        this.rateLimitService = rateLimitService;
        this.galleryStorageService = galleryStorageService;
        this.eventPublisher = eventPublisher;
    }

    public record ThematicDomainItem(String institution, String title, String icon, String description) {
    }

    public record ConferenceScheduleSession(String title, String timeLabel, String timeValue, boolean highlighted,
                                            String imageUrl, String icon, String description) {
    }

    public record ConferenceScheduleDay(int dayNumber, String title, String dateLabel, String dateValue, String icon,
                                        List<ConferenceScheduleSession> sessions) {
    }

    public record NewsItem(
            String slug,
            String title,
            String date,
            String image,
            String excerpt,
            List<String> paragraphs
    ) {
    }

    public record StatItem(String value, String label) {
    }

    public record ContentItem(String title, String description, String icon, String image) {
    }

    public record SpeakerProfile(String name, String designation, String organization, String expertise, String image) {
    }

    public record Testimonial(String quote, String name, String role) {
    }

    @ModelAttribute
    public void disablePageCaching(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
    }

    public record RetreatPage(
            String year,
            String badge,
            String heading,
            String subheading,
            String description,
            String accent,
            String focus,
            String heroImage,
            List<String> about,
            List<ContentItem> highlights,
            List<StatItem> stats,
            List<ContentItem> gallery,
            List<ContentItem> videos,
            List<ContentItem> timeline,
            List<SpeakerProfile> speakers,
            List<ContentItem> moments,
            List<String> achievements,
            List<Testimonial> testimonials,
            List<ContentItem> faqs,
            String ctaTitle,
            String ctaText,
            String ctaLabel,
            String ctaLink
    ) {
    }

    public static class SponsorEnquiryForm {
        @NotBlank(message = "{validation.companyName.required}")
        @Size(max = 200, message = "Maximum 200 characters allowed.")
        @Pattern(regexp = Constants.ORG_NAME_REGEX, message = "Company name must contain letters and may include numbers, spaces, and & . , ' - / # + parentheses.")
        private String company;

        @NotBlank(message = "{validation.name.required}")
        @Pattern(regexp = "^[A-Za-z][A-Za-z .'-]{1,149}$", message = "Enter a valid contact name.")
        private String name;

        @Size(max = 100, message = "Maximum 100 characters allowed.")
        @Pattern(regexp = Constants.TITLE_REGEX, message = "Designation may contain letters, spaces, and & . , ' - / parentheses.")
        private String jobTitle;

        @Size(max = 100, message = "Maximum 100 characters allowed.")
        @Pattern(regexp = Constants.PLACE_REGEX, message = "City may contain letters, spaces, and . , ' - / parentheses.")
        private String city;
        @jakarta.validation.constraints.Pattern(regexp = "^$|^https?://\\S+$", message = "Enter a valid website URL starting with http:// or https://.")
        @Size(max = 255, message = "Maximum 255 characters allowed.")
        private String website;
        @Size(max = 100, message = "Maximum 100 characters allowed.")
        @Pattern(regexp = Constants.TITLE_REGEX, message = "Industry may contain letters, spaces, and & . , ' - / parentheses.")
        private String industry;

        @NotBlank(message = "{validation.email.required}")
        @Email(message = "{validation.email}")
        @Size(max = 254, message = "Maximum 254 characters allowed.")
        private String email;

        @NotBlank(message = "{validation.phone.required}")
        @IndianMobile
        @Size(max = 15, message = "Maximum 15 characters allowed.")
        private String phone;

        @NotBlank(message = "{validation.sponsorshipInterest.required}")
        @Pattern(regexp = "Platinum|Gold|Silver|Copper|Bronze", message = "Please select a valid sponsorship package.")
        private String sponsorshipInterest;

        @Size(max = 5000, message = "Maximum 5000 characters allowed.")
        @Pattern(regexp = Constants.FREE_TEXT_REGEX, message = "Message contains characters that are not allowed.")
        private String message;

        private MultipartFile logoFile;

        public String getCity() { return city; }
        public void setCity(String city) { this.city = city; }
        public String getWebsite() { return website; }
        public void setWebsite(String website) { this.website = website; }
        public String getIndustry() { return industry; }
        public void setIndustry(String industry) { this.industry = industry; }

        public String getCompany() {
            return company;
        }

        public void setCompany(String company) {
            this.company = company;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getJobTitle() {
            return jobTitle;
        }

        public void setJobTitle(String jobTitle) {
            this.jobTitle = jobTitle;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getPhone() {
            return phone;
        }

        public void setPhone(String phone) {
            this.phone = phone;
        }

        public String getSponsorshipInterest() {
            return sponsorshipInterest;
        }

        public void setSponsorshipInterest(String sponsorshipInterest) {
            this.sponsorshipInterest = sponsorshipInterest;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }

        public MultipartFile getLogoFile() { return logoFile; }
        public void setLogoFile(MultipartFile logoFile) { this.logoFile = logoFile; }
    }

    private static final List<NewsItem> NEWS_ITEMS = List.of(
            new NewsItem(
                    "shri-chandubhai-virani-keynote-speaker",
                    "Shri Chandubhai Virani Joins Tech Expo Chennai 2026 As An Esteemed Speaker",
                    "18 Jun 2026",
                    "/images/about-tec.png",
                    "Tech Expo Chennai 2026 is proud to announce the participation of Shri Chandubhai Virani, Founder and Director of Balaji Wafers Pvt. Ltd.",
                    List.of(
                            "Tech Expo Chennai 2026 is proud to announce the participation of Shri Chandubhai Virani, Founder & Director of Balaji Wafers Pvt. Ltd., as an esteemed speaker for the upcoming edition of Chennai's largest technology expo.",
                            "A visionary entrepreneur and one of Chennai's most respected business leaders, Chandubhai Virani has built Balaji Wafers into one of India's most recognized FMCG brands through innovation, operational excellence, and a deep understanding of market dynamics. His entrepreneurial journey continues to inspire business leaders, startups, and aspiring entrepreneurs across the country.",
                            "As Tech Expo Chennai 2026 embraces its theme, \"Beacon of Rising Innovation & AI,\" his presence will bring valuable perspectives on business growth, scaling operations, leadership, and adapting to an ever-evolving market landscape.",
                            "Scheduled to take place from 26-27 November 2026 at GUCEC (GMDC Ground), Ahmedabad, Tech Expo Chennai 2026 will bring together 15,000+ visitors, 250+ exhibitors, and 25+ speakers from across industries to explore the future of technology, innovation, and digital transformation.",
                            "Stay tuned for more speaker announcements as we continue to build a powerful lineup of industry leaders shaping the next tech era of Chennai."
                    )
            ),
            new NewsItem(
                    "collaboration-outpacing-competition",
                    "The New Currency Of Business: Why Collaboration Is Outpacing Competition?",
                    "15 May 2026",
                    "/images/banner.jpg",
                    "The most successful tech businesses today are not the ones that outbuilt everyone else. They are the ones that partner faster and execute better.",
                    List.of(
                            "The most successful tech businesses today are not the ones that outbuilt everyone else. They are the ones that partner faster, learn faster, and execute better with the right ecosystem around them.",
                            "Across industries, collaboration has become the multiplier. It helps companies reduce duplication, access new customers, and combine specialist capabilities that would take years to build alone.",
                            "Tech Expo Chennai 2026 is designed around that shift, bringing exhibitors, buyers, innovators, and public institutions into the same room for focused business conversations."
                    )
            ),
            new NewsItem(
                    "gujarat-tech-evolution",
                    "Chennai's Tech Evolution: From Industrial Giant To Innovation Powerhouse",
                    "10 May 2026",
                    "/images/about.jpeg",
                    "Chennai has never been a state that waits. It builds, it trades, it leads, and then it reinvents.",
                    List.of(
                            "Chennai has never been a state that waits. It builds, it trades, it leads, and then it reinvents. From industrial output to intelligent enterprise, the state is moving into a new chapter.",
                            "Its established manufacturing base, business-friendly mindset, and expanding digital infrastructure make Chennai a natural home for technology-led transformation.",
                            "Tech Expo Chennai 2026 captures this momentum by connecting traditional industries with modern tools across AI, automation, cybersecurity, electronics, and digital platforms."
                    )
            ),
            new NewsItem(
                    "ai-is-the-floor",
                    "AI Is Not The Future. It's The Floor.",
                    "25 Apr 2026",
                    "/images/tech.png",
                    "Not too long ago, having a website made your business look modern. Then it became mandatory. AI is on the same trajectory.",
                    List.of(
                            "Not too long ago, having a website made your business look modern. Then it became mandatory. AI is on the same trajectory, except the curve is steeper and the timeline is shorter.",
                            "Across industries, in boardrooms and factory floors alike, the conversation has shifted from whether to adopt AI to how fast teams can make it part of daily operations.",
                            "AI is moving from differentiator to baseline. Customers expect personalization, enterprises expect automation, and investors expect intelligent systems that can scale.",
                            "This shift is not limited to the technology industry. Manufacturing, logistics, healthcare, retail, real estate, and finance are all being reshaped by intelligent workflows.",
                            "Chennai's strength has always been execution. As AI rewrites the logic of every industry it touches, the next advantage will belong to organizations that combine execution with adoption.",
                            "That is where platforms like Tec-Verse matter: they bring solution providers, industry adopters, and decision-makers into the same room so the conversation moves from concept to implementation."
                    )
            ),
            new NewsItem(
                    "gucec-ahmedabad-november",
                    "Why Every Tech Business In Chennai Needs To Be At GUCEC, A'bad This November?",
                    "18 Apr 2026",
                    "/images/img.jpeg",
                    "Chennai's tech landscape is shifting faster than most businesses realise. New players are emerging and demand is maturing.",
                    List.of(
                            "Chennai's tech landscape is shifting faster than most businesses realise. New players are emerging, customers are asking sharper questions, and the market is rewarding visible expertise.",
                            "GUCEC, Ahmedabad brings that market together in November with the right mix of exhibitors, buyers, partners, institutions, and growth-focused conversations.",
                            "For technology businesses, presence matters. A strong booth, a clear solution story, and direct conversations can create opportunities that are difficult to unlock through digital outreach alone."
                    )
            ),
            new NewsItem(
                    "teg-ignite-2026-concludes",
                    "TEG Ignite 2026 Concludes Successfully; Tech Expo Chennai 2026 Launched With 55% Inventory Booked",
                    "10 Apr 2026",
                    "/images/cdactexh.png",
                    "Tech Expo Chennai successfully hosted TEG Ignite - AI & Growth Sessions, a high-impact gathering for the technology community.",
                    List.of(
                            "Tech Expo Chennai successfully hosted TEG Ignite - AI & Growth Sessions, a high-impact gathering that brought together entrepreneurs, founders, exhibitors, and growth leaders.",
                            "The event marked an energetic launch for Tech Expo Chennai 2026, with 55% inventory already booked and strong interest from the regional technology ecosystem.",
                            "The response signals clear demand for a focused platform where businesses can showcase capability, meet serious visitors, and build partnerships for the year ahead."
                    )
            )
    );

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("thematicDomainItems", thematicDomainsForDisplay());
        model.addAttribute("chiefGuests", chiefGuestRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc());
        model.addAttribute("importantDates", importantDateRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc());
        model.addAttribute("homeSpeakers", speakerRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc());
        model.addAttribute("homeExhibitors", exhibitorLogoRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc());
        model.addAttribute("mediaCoverage", mediaCoverageService.getLatestMediaCoverage());
        model.addAttribute("homeFaqs", faqService.activeFaqs(FaqService.HOME));
        return "home";
    }

    private List<ThematicDomainItem> thematicDomainsForDisplay() {
        return thematicDomainCardRepository.findByActiveTrueOrderByInstitutionAscDisplayOrderAscIdAsc()
                .stream()
                .map(PageController::thematicDomainItem)
                .toList();
    }

    private static ThematicDomainItem thematicDomainItem(ThematicDomainCard card) {
        return new ThematicDomainItem(
                card.getInstitution(),
                card.getTitle(),
                card.getIcon(),
                card.getDescription()
        );
    }

    @GetMapping("/about")
    public String about() {
        return "about";
    }

    @ModelAttribute("contactCountries")
    public List<ContactPhoneNumbers.Country> contactCountries() {
        return ContactPhoneNumbers.countries();
    }

    @InitBinder("inquiry")
    public void configureInquiryValidation(WebDataBinder binder) {
        if (!(binder.getTarget() instanceof InquiryForm)) {
            return;
        }
        binder.setAllowedFields("name", "email", "phone", "company", "jobTitle", "country", "message", "sponsorshipInterest");
        binder.addValidators(new InquiryFormValidator());
    }

    @GetMapping({"/inquiry", "/inquiry.html"})
    public String inquiry(Model model, HttpSession session) {
        model.addAttribute("inquiry", new InquiryForm());
        prepareCaptcha(model, session);
        return "fragments/inquiry";
    }

    @PostMapping({"/inquiry", "/inquiry.html"})
    public String submitInquiry(@Valid @ModelAttribute("inquiry") InquiryForm inquiry,
                                BindingResult bindingResult,
                                @RequestParam(value = "type", required = false) String type,
                                @RequestParam(value = "captchaAnswer", required = false) String captchaAnswer,
                                Model model,
                                HttpSession session,
                                HttpServletRequest httpRequest,
                                HttpServletResponse response) {
        if (!"exhibitor".equalsIgnoreCase(type) && !isCaptchaValid(captchaAnswer, session)) {
            bindingResult.reject("captcha.invalid", "Please solve the CAPTCHA correctly.");
            session.removeAttribute(CONTACT_CAPTCHA_ANSWER);
            session.removeAttribute(CONTACT_CAPTCHA_QUESTION);
        }

        if (bindingResult.hasErrors()) {
            prepareCaptcha(model, session);
            model.addAttribute("inquirySubmitFailed", true);
            return "fragments/inquiry";
        }

        try {
            rateLimitService.check(httpRequest, "inquiry-submit", inquiry.getEmail(), 5, Duration.ofHours(1), 15, Duration.ofHours(1));
        } catch (RateLimitExceededException ex) {
            response.setStatus(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS.value());
            bindingResult.reject("inquiry.rateLimit", ex.getMessage());
            prepareCaptcha(model, session);
            model.addAttribute("inquirySubmitFailed", true);
            return "fragments/inquiry";
        }

        String normalizedEmail = inquiry.getEmail().trim().toLowerCase();
        String normalizedPhone = ContactPhoneNumbers.normalize(inquiry.getPhone(), inquiry.getCountry());

        boolean duplicateEmail = contactUsRepository.existsByEmailIgnoreCase(normalizedEmail);
        boolean duplicatePhone = normalizedPhone != null
                && contactUsRepository.existsByPhoneNumber(normalizedPhone);
        if (duplicateEmail || duplicatePhone) {
            if (duplicateEmail) {
                bindingResult.rejectValue("email", "inquiry.email.duplicate",
                        "This email address has already been used for an inquiry.");
            }
            if (duplicatePhone) {
                bindingResult.rejectValue("phone", "inquiry.phone.duplicate",
                        "This phone number has already been used for an inquiry.");
            }
            prepareCaptcha(model, session);
            model.addAttribute("inquirySubmitFailed", true);
            return "fragments/inquiry";
        }

        ContactUs contactUs = new ContactUs();
        contactUs.setFullName(inquiry.getName().trim());
        contactUs.setEmail(normalizedEmail);
        contactUs.setPhoneNumber(normalizedPhone);
        contactUs.setCompanyName(inquiry.getCompany().trim());
        contactUs.setJobTitle(blankToNull(inquiry.getJobTitle()));
        contactUs.setCountry(blankToNull(inquiry.getCountry()));
        contactUs.setMessage(inquiry.getMessage().trim());
        try {
            contactUsRepository.saveAndFlush(contactUs);
        } catch (DataIntegrityViolationException ex) {
            // A concurrent submission may pass the pre-save checks. The table's
            // unique constraints remain the final guard against duplicate contacts.
            bindingResult.reject("inquiry.contact.duplicate",
                    "This email address or phone number has already been used for an inquiry.");
            prepareCaptcha(model, session);
            model.addAttribute("inquirySubmitFailed", true);
            return "fragments/inquiry";
        }

        model.addAttribute("successMessage", message("contact.form.success"));
        model.addAttribute("inquiry", new InquiryForm());
        session.removeAttribute(CONTACT_CAPTCHA_ANSWER);
        session.removeAttribute(CONTACT_CAPTCHA_QUESTION);
        prepareCaptcha(model, session);
        return "fragments/inquiry";
    }

    private static void prepareCaptcha(Model model, HttpSession session) {
        Integer answer = (Integer) session.getAttribute(CONTACT_CAPTCHA_ANSWER);
        if (answer == null) {
            int first = CAPTCHA_RANDOM.nextInt(8) + 2;
            int second = CAPTCHA_RANDOM.nextInt(8) + 2;
            answer = first + second;
            session.setAttribute(CONTACT_CAPTCHA_ANSWER, answer);
            session.setAttribute(CONTACT_CAPTCHA_QUESTION, first + " + " + second + " = ?");
        }

        model.addAttribute("captchaQuestion", session.getAttribute(CONTACT_CAPTCHA_QUESTION));
    }

    private static boolean isCaptchaValid(String captchaAnswer, HttpSession session) {
        Integer expectedAnswer = (Integer) session.getAttribute(CONTACT_CAPTCHA_ANSWER);
        if (expectedAnswer == null || captchaAnswer == null || captchaAnswer.isBlank()) {
            return false;
        }

        return String.valueOf(expectedAnswer).equals(captchaAnswer.trim());
    }

    private static String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }

    @GetMapping({"/become-sponsor", "/becomesponsor", "/become-sponsor.html"})
    public String becomeSponsor(Model model) {
        model.addAttribute("inquiry", new SponsorEnquiryForm());
        return "become-sponsor";
    }

    // @GetMapping({"/became-sponser", "/becamesponser", "/become-sponser"})
    // public String legacyBecomeSponsor() {
    //     return "redirect:/become-sponsor";
    // }

    @PostMapping({"/become-sponsor", "/becomesponsor", "/become-sponsor.html", "/became-sponser", "/becamesponser", "/become-sponser"})
    public String submitSponsorInquiry(@Valid @ModelAttribute("inquiry") SponsorEnquiryForm inquiry, BindingResult bindingResult, Model model,
                                       HttpServletRequest httpRequest, HttpServletResponse response) {
        model.addAttribute("inquiry", inquiry);
        if (bindingResult.hasErrors()) {
            model.addAttribute("sponsorInquiryFailed", true);
            return "become-sponsor";
        }

        try {
            rateLimitService.check(httpRequest, "sponsor-submit", inquiry.getEmail(), 3, Duration.ofHours(1), 10, Duration.ofHours(1));
        } catch (RateLimitExceededException ex) {
            response.setStatus(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS.value());
            model.addAttribute("sponsorEnquiryError", ex.getMessage());
            model.addAttribute("sponsorInquiryFailed", true);
            return "become-sponsor";
        }

        String normalizedEmail = inquiry.getEmail().trim().toLowerCase();
        String normalizedPhone = ValidationUtil.normalizeIndianMobile(inquiry.getPhone());

        if (!sponsorOtpService.isVerified(normalizedEmail)
                || !OtpSessionVerification.isVerified(httpRequest, OtpSessionVerification.Purpose.SPONSOR, normalizedEmail)) {
            response.setStatus(org.springframework.http.HttpStatus.FORBIDDEN.value());
            model.addAttribute("sponsorEnquiryError", "Please verify your email with OTP before submitting.");
            model.addAttribute("sponsorInquiryFailed", true);
            return "become-sponsor";
        }

        if (!OtpSessionVerification.isVerified(httpRequest, OtpSessionVerification.Purpose.SPONSOR_MOBILE, normalizedPhone)) {
            response.setStatus(org.springframework.http.HttpStatus.FORBIDDEN.value());
            model.addAttribute("sponsorEnquiryError", "Please verify your mobile number with OTP before submitting.");
            model.addAttribute("sponsorInquiryFailed", true);
            return "become-sponsor";
        }

        if (sponsorEnquiryRepository.existsByEmail(normalizedEmail)) {
            model.addAttribute("sponsorEnquiryError", message("api.email.registered"));
            model.addAttribute("sponsorInquiryFailed", true);
            return "become-sponsor";
        }
        if (sponsorEnquiryRepository.existsByPhone(normalizedPhone)) {
            model.addAttribute("sponsorEnquiryError", message("api.phone.registered"));
            model.addAttribute("sponsorInquiryFailed", true);
            return "become-sponsor";
        }

        String logoUrl = null;
        if (inquiry.getLogoFile() != null && !inquiry.getLogoFile().isEmpty()) {
            try {
                logoUrl = galleryStorageService.uploadImage(inquiry.getLogoFile(), "sponsors");
            } catch (RuntimeException ex) {
                model.addAttribute("sponsorEnquiryError", ex.getMessage());
                model.addAttribute("sponsorInquiryFailed", true);
                return "become-sponsor";
            }
        }

        SponsorEnquiry sponsorEnquiry = SponsorEnquiry.builder()
                .company(inquiry.getCompany().trim())
                .name(inquiry.getName().trim())
                .designation(blankToNull(inquiry.getJobTitle()))
                .city(blankToNull(inquiry.getCity()))
                .website(blankToNull(inquiry.getWebsite()))
                .industry(blankToNull(inquiry.getIndustry()))
                .email(normalizedEmail)
                .phone(normalizedPhone)
                .sponsorshipInterest(inquiry.getSponsorshipInterest().trim())
                .emailVerified(true)
                .status("NEW")
                .paymentStatus("PENDING_CONTACT")
                .message(blankToNull(inquiry.getMessage()))
                .logoUrl(logoUrl)
                .build();
        sponsorEnquiryRepository.save(sponsorEnquiry);
        eventPublisher.publishEvent(new SponsorEnquirySavedEvent(
                normalizedEmail,
                sponsorEnquiry.getName(),
                sponsorEnquiry.getCompany(),
                sponsorEnquiry.getSponsorshipInterest()));
        sponsorOtpService.consume(normalizedEmail);
        OtpSessionVerification.consume(httpRequest, OtpSessionVerification.Purpose.SPONSOR);
        OtpSessionVerification.consume(httpRequest, OtpSessionVerification.Purpose.SPONSOR_MOBILE);

        model.addAttribute("sponsorInquirySubmitted", true);
        model.addAttribute("inquiry", new SponsorEnquiryForm());
        return "become-sponsor";
    }

    @GetMapping({"/privacy-policy", "/privacy-policy/", "/privacy", "/privacy/", "/privacy-policy.html", "/privacy.html"})
    public String privacyPolicy() {
        return "privacy-policy";
    }

    @GetMapping({"/terms-and-conditions", "/terms-and-conditions/", "/terms", "/terms/"})
    public String termsAndConditions() {
        return "terms-and-conditions";
    }

    @GetMapping({"/account-deletion", "/account-deletion/", "/delete-account", "/delete-account/", "/account-deletion.html"})
    public String accountDeletion() {
        return "account-deletion";
    }

    @GetMapping("/exhibitor-registration")
    public String exhibitorRegistration(HttpServletRequest request) {
        // A page reload starts a fresh exhibitor application and requires fresh OTP checks.
        OtpSessionVerification.consume(request, OtpSessionVerification.Purpose.EXHIBITOR);
        OtpSessionVerification.consume(request, OtpSessionVerification.Purpose.EXHIBITOR_MOBILE);
        return "exhibitor-registration";
    }

    @GetMapping({"/registration", "/ticket", "/ticket.html", "/book-your-ticket"})
    public String ticket(Model model) {
        model.addAttribute("ticketFaqs", faqService.activeFaqs(FaqService.TICKET));
        return "ticket";
    }

    /**
     * Step 2 of ticket registration. The server, not the browser, decides whether the visitor may
     * continue: the form is returned only to a session that completed OTP verification server-side.
     */
    @GetMapping("/ticket/details-step")
    public String ticketDetailsStep(HttpServletRequest request, HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        if (!OtpSessionVerification.hasVerification(request, OtpSessionVerification.Purpose.TICKET)) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Email verification is required.");
        }
        // Temporary mobile OTP bypass; restore this check to require mobile verification.
        // if (!OtpSessionVerification.hasVerification(request, OtpSessionVerification.Purpose.TICKET_MOBILE)) {
        //     throw new ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Mobile number verification is required.");
        // }
        return "fragments/ticket-details-step :: detailsStep";
    }

    @GetMapping({"/ticket/confirmation", "/ticket/confirmation.html"})
    public String ticketConfirmation(@RequestParam(required = false) String pass,
                                     @RequestParam(required = false) String email,
                                     Model model) {
        model.addAttribute("selectedPass", blankToNull(pass) == null ? "Tec-Verse Pass" : pass.trim());
        model.addAttribute("verifiedEmail", blankToNull(email) == null ? "your verified email" : email.trim());
        return "ticket-confirmation";
    }

    @GetMapping("/gallery")
    public String gallery(Model model) {
        model.addAttribute("galleryImages", galleryImageRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc());
        model.addAttribute("galleryVideos", galleryVideoRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc());
        return "gallery";
    }

    @GetMapping({"/retreat-{year}", "/retreat/{year}", "/retreat {year}"})
    public String retreat(@PathVariable("year") String year, Model model) {
        RetreatPage retreatPage = switch (year) {
            case "2024" -> retreat2024();
            case "2025" -> retreat2025();
            case "2026" -> retreat2026();
            default -> throw new ResponseStatusException(NOT_FOUND);
        };

        model.addAttribute("retreat", retreatPage);
        model.addAttribute("conferenceScheduleDays", conferenceScheduleDays());
        model.addAttribute("retreatFaqs", faqService.activeFaqs(FaqService.RETREAT));
        return "retreat";
    }

    private List<ConferenceScheduleDay> conferenceScheduleDays() {
        Map<Integer, List<ConferenceScheduleItem>> grouped = new LinkedHashMap<>();
        conferenceScheduleItemRepository.findByActiveTrueOrderByDayNumberAscDisplayOrderAscIdAsc()
                .forEach(item -> grouped.computeIfAbsent(item.getDayNumber(), key -> new ArrayList<>()).add(item));

        return grouped.entrySet().stream()
                .map(entry -> {
                    ConferenceScheduleItem first = entry.getValue().getFirst();
                    List<ConferenceScheduleSession> sessions = entry.getValue().stream()
                            .map(item -> {
                                SchedulePresentation presentation = schedulePresentation(item.getSessionTitle(), entry.getKey());
                                return new ConferenceScheduleSession(
                                        item.getSessionTitle(), item.getTimeLabel(), item.getTimeValue(), item.isHighlighted(),
                                        item.getImageUrl(), presentation.icon(), presentation.description());
                            })
                            .toList();
                    return new ConferenceScheduleDay(
                            entry.getKey(),
                            first.getDayTitle(),
                            first.getDateLabel(),
                            first.getDateValue(),
                            entry.getKey() == 1 ? "cpu" : "lightning-charge",
                            sessions
                    );
                })
                .toList();
    }

    private record SchedulePresentation(String icon, String description) { }

    private static SchedulePresentation schedulePresentation(String title, int dayNumber) {
        return switch (title) {
            case "Registration" -> new SchedulePresentation("people-fill", "Guest registration and welcome desk.");
            case "Arrival of Guests" -> new SchedulePresentation("people-fill", "Welcome our distinguished guests.");
            case "Tamil Thai Vazthu", "Tamil Thai Vazhthu" -> new SchedulePresentation("music-note-beamed", "A soulful invocation.");
            case "Inaugural Ceremony (Lamp Lighting)" -> new SchedulePresentation("lightbulb-fill", "Lighting the lamp to mark the beginning.");
            case "Keynote Address by Chief Guest" -> new SchedulePresentation("person-workspace", dayNumber == 2 ? "Vision for a sustainable future." : "Insights for a smarter tomorrow.");
            case "Product Launch / IoA / MoU" -> new SchedulePresentation("rocket-takeoff-fill", "Unveiling new opportunities.");
            case "Stall Visit by Chief Guest" -> new SchedulePresentation("shop", "Exploring innovation at the stalls.");
            case "Stall Visit by College Students" -> new SchedulePresentation("shop", "Engaging with young innovators.");
            case "Lunch Break" -> new SchedulePresentation("fork-knife", "Networking over lunch.");
            case "High Tea" -> new SchedulePresentation("cup-hot-fill", dayNumber == 2 ? "Refresh and recharge." : "Refresh and connect.");
            case "Cultural Program" -> new SchedulePresentation("masks-theater-fill", "Celebrating our diverse talent.");
            case "Dinner" -> new SchedulePresentation("egg-fried", "An evening of networking.");
            case "Welcome Address" -> new SchedulePresentation("person-fill", "Setting the tone for an inspiring day.");
            case "MoU Signing Inauguration" -> new SchedulePresentation("file-earmark-text-fill", "Strengthening collaborations.");
            default -> new SchedulePresentation("calendar-event", "Tec-Verse 2026 event schedule.");
        };
    }

    private static RetreatPage retreat2024() {
        return new RetreatPage(
                "2024",
                "CDAC Annual Retreat 2024",
                "Foundation of Innovation",
                "Building Stronger Research Communities Through Collaboration",
                "The inaugural CDAC Annual Retreat 2024 brought together researchers, scientists, engineers, technology leaders, government representatives and academic institutions to foster collaboration, exchange breakthrough ideas and strengthen India's indigenous digital technology ecosystem. The event established a platform for innovation, knowledge sharing and future-ready research initiatives.",
                "blue",
                "Launch year, research collaboration, and technology showcase",
                unsplash("photo-1519389950473-47ba0277781c", "1200", "800"),
                List.of(
                        "CDAC Annual Retreat 2024 was conceived as a national forum for aligning research capability with mission-scale digital priorities. It gave teams across centres a shared stage to present prototypes, exchange technical learning and convert institutional knowledge into collaborative action.",
                        "The retreat highlighted why collaboration is central to public technology delivery. Researchers, government stakeholders, academia and industry partners worked through practical challenges in computing, security, electronics and digital governance, creating pathways for joint development rather than isolated experimentation.",
                        "Focused sessions examined indigenous research initiatives across artificial intelligence, high performance computing, cyber security, health informatics and smart systems. Demonstrations helped participants understand how laboratory progress can mature into platforms, tools and citizen-scale digital infrastructure.",
                        "By closing with a future roadmap, the 2024 retreat established a disciplined foundation for annual review, stronger partnerships and measurable innovation outcomes aligned with India's self-reliant digital technology ambitions."
                ),
                List.of(
                        item("Technology Showcase", "Live demonstrations introduced research prototypes, advanced computing tools and digital solutions developed across CDAC centres for public-sector and enterprise use.", "cpu-fill", "photo-1550751827-4bd374c3f58b"),
                        item("Leadership Address", "Senior leaders shared priorities for indigenous innovation, secure digital platforms and collaborative research delivery across national technology missions.", "mic-fill", "photo-1505373877841-8d25f7d46678"),
                        item("Innovation Awards", "Outstanding teams were recognized for applied research, engineering discipline and technology work with potential for national deployment.", "award-fill", "photo-1523580494863-6f3031224c94"),
                        item("Networking Sessions", "Scientists, engineers, academic researchers and public institutions connected around common programs, implementation challenges and partnership opportunities.", "people-fill", "photo-1517245386807-bb43f82c33c4")
                ),
                List.of(stat("300+", "Participants"), stat("40+", "Sessions"), stat("20+", "Research Teams"), stat("15", "Industry Partners"), stat("35", "Technology Demonstrations")),
                gallery2024(),
                videosFor("Opening Ceremony", "Leadership Keynote", "Innovation Showcase", "Technology Demonstrations", "Closing Ceremony"),
                timelineFor("research teams", "prototype demonstrations", "inaugural roadmap"),
                speakers2024(),
                momentsFor("2024", "The inaugural retreat turned individual research achievements into a shared institutional narrative."),
                List.of(
                        "Established the CDAC Annual Retreat as a recurring platform for research collaboration.",
                        "Showcased 35 technology demonstrations spanning computing, cyber security and digital governance.",
                        "Facilitated new conversations between academia, public institutions and applied engineering teams.",
                        "Recognized high-impact research teams through innovation awards.",
                        "Created a practical roadmap for stronger indigenous digital technology development."
                ),
                testimonialsFor("2024"),
                faqs(),
                "Continue the Journey",
                "The inaugural retreat created the foundation. The next chapter expands the platform into deeper industry, academia and government collaboration.",
                "Explore Retreat 2025",
                "/retreat-2025"
        );
    }

    private static RetreatPage retreat2025() {
        return new RetreatPage(
                "2025",
                "CDAC Annual Retreat 2025",
                "Accelerating Digital Transformation",
                "Driving Innovation Through Emerging Technologies",
                "Building upon the success of the inaugural retreat, CDAC Retreat 2025 expanded its focus towards Artificial Intelligence, Cyber Security, Cloud Computing, Digital Governance, Semiconductor Technologies and Startup Innovation. The retreat created meaningful collaborations between government, industry and academia for the next generation of digital transformation.",
                "purple",
                "Industry partnerships, AI demonstrations, innovation awards, and panel discussions",
                unsplash("photo-1558494949-ef010cbdcc31", "1200", "800"),
                List.of(
                        "CDAC Annual Retreat 2025 advanced the platform from knowledge exchange to accelerated transformation. The agenda connected emerging technologies with national implementation priorities, giving participants a clear view of how research can scale into secure, resilient and citizen-centric systems.",
                        "Collaboration was positioned as the operating model for digital transformation. Government departments, industry partners, startups and academic institutions examined how shared standards, interoperable platforms and trusted infrastructure can reduce duplication and improve delivery velocity.",
                        "Research sessions focused on artificial intelligence, cyber security, cloud computing, semiconductor technologies, digital governance and startup-led innovation. The retreat encouraged teams to move from proof of concept to deployment readiness through mentoring, validation and partnership tracks.",
                        "The 2025 roadmap emphasized ecosystem maturity: stronger industry participation, expanded project showcases, applied research partnerships and more structured mechanisms for translating CDAC innovations into national digital capability."
                ),
                List.of(
                        item("AI Innovation Lab", "Applied AI teams presented models, decision-support systems and automation frameworks designed for trustworthy digital public services.", "robot", "photo-1677442136019-21780ecad995"),
                        item("Cyber Security Forum", "Security specialists explored threat intelligence, resilient architectures and indigenous tools for protecting national digital infrastructure.", "shield-lock-fill", "photo-1563986768609-322da13575f3"),
                        item("Startup Collaboration", "Emerging companies met researchers and public stakeholders to identify pilots, product validation opportunities and joint innovation pathways.", "rocket-takeoff-fill", "photo-1556761175-b413da4baf72"),
                        item("Digital Governance Panels", "Policy, engineering and program leaders discussed scalable governance platforms, cloud adoption and citizen-service modernization.", "building-fill-gear", "photo-1552664730-d307ca884978")
                ),
                List.of(stat("450+", "Participants"), stat("65", "Sessions"), stat("50", "Projects"), stat("35", "Organizations"), stat("25", "Industry Partners")),
                gallery2025(),
                videosFor("Opening Ceremony", "Leadership Keynote", "AI Innovation Showcase", "Cyber Security Demonstrations", "Closing Ceremony"),
                timelineFor("digital transformation leaders", "AI and cyber security showcases", "ecosystem roadmap"),
                speakers2025(),
                momentsFor("2025", "The second retreat converted momentum into a broader ecosystem for technology adoption."),
                List.of(
                        "Presented 50 projects across AI, cyber security, cloud and semiconductor domains.",
                        "Expanded participation to 35 organizations from government, academia, industry and startups.",
                        "Created structured collaboration tracks for applied research and pilot-ready solutions.",
                        "Strengthened industry engagement through focused demonstrations and panel discussions.",
                        "Advanced digital transformation priorities through practical roadmaps and expert sessions."
                ),
                testimonialsFor("2025"),
                faqs(),
                "Discover What's Next",
                "Retreat 2025 expanded the ecosystem. Retreat 2026 carries that ambition into national-scale digital futures.",
                "Explore Retreat 2026",
                "/retreat-2026"
        );
    }

    private static RetreatPage retreat2026() {
        return new RetreatPage(
                "2026",
                "CDAC Annual Retreat 2026",
                "Building India's Digital Future",
                "Empowering Innovation for a Self-Reliant Digital Nation",
                "CDAC Retreat 2026 showcased India's technological advancements through national collaborations, cutting-edge research, indigenous innovations and strategic partnerships. The retreat emphasized future technologies including AI, Quantum Computing, High Performance Computing, Electronics System Design and Digital Public Infrastructure.",
                "teal",
                "National collaborations, emerging technologies, startup ecosystem, and future roadmap",
                unsplash("photo-1518770660439-4636190af475", "1200", "800"),
                List.of(
                        "CDAC Annual Retreat 2026 positioned indigenous technology development at the centre of India's digital future. The retreat brought together national stakeholders to assess frontier research, mission platforms and the partnerships required for strategic digital capability.",
                        "The program reinforced collaboration as a national advantage. Government leaders, engineers, scientists, academic researchers, startups and industry experts worked across disciplines to connect future technologies with secure deployment, manufacturing readiness and digital public infrastructure.",
                        "Research initiatives spanned artificial intelligence, quantum computing, high performance computing, electronics system design, cyber resilience and large-scale public platforms. Sessions were designed to make technical progress visible, testable and relevant to national priorities.",
                        "The future roadmap focused on self-reliance, trusted technology stacks, talent development and sustained collaboration. Retreat 2026 converted CDAC's research depth into a confident vision for the next generation of public digital infrastructure."
                ),
                List.of(
                        item("Quantum & HPC Pavilion", "Researchers demonstrated high-performance and quantum-ready computing capabilities for complex scientific, government and enterprise workloads.", "stars", "photo-1518770660439-4636190af475"),
                        item("Digital Public Infrastructure", "Teams showcased secure, interoperable platforms designed to strengthen citizen services, governance systems and national-scale delivery.", "diagram-3-fill", "photo-1551288049-bebda4e38f71"),
                        item("Electronics Design Track", "Experts presented advances in ESDM, embedded systems and semiconductor-aligned research supporting self-reliant technology development.", "memory", "photo-1581091226825-a6a2a5aee158"),
                        item("Strategic Partnerships", "Leaders from government, academia and industry shaped collaboration models for long-term research, standards and implementation programs.", "handshake", "photo-1556761175-5973dc0f32e7")
                ),
                List.of(stat("700+", "Participants"), stat("80", "Sessions"), stat("60", "Research Projects"), stat("25", "Industry Partners"), stat("50", "Technology Demonstrations")),
                gallery2026(),
                videosFor("Opening Ceremony", "National Leadership Keynote", "Future Technology Showcase", "Quantum and HPC Demonstrations", "Closing Ceremony"),
                timelineFor("national technology delegates", "future technology demonstrations", "self-reliant digital nation roadmap"),
                speakers2026(),
                momentsFor("2026", "The 2026 retreat framed India's next digital decade through research, resilience and self-reliance."),
                List.of(
                        "Showcased 60+ research projects across AI, quantum computing, HPC and electronics design.",
                        "Hosted 50 technology demonstrations focused on indigenous innovation and strategic capability.",
                        "Strengthened national technology partnerships across public institutions, academia and industry.",
                        "Promoted trusted digital public infrastructure and secure government enterprise platforms.",
                        "Defined a future roadmap for self-reliant digital technology ecosystems."
                ),
                testimonialsFor("2026"),
                faqs(),
                "Join Future Retreats",
                "Stay connected with CDAC as research communities, government programs and industry partners build the next generation of digital capability.",
                "Stay Connected with CDAC",
                "/inquiry"
        );
    }

    private static List<ContentItem> gallery2024() {
        return List.of(
                item("Research Collaboration Workshop", "Scientists exchanging ideas during collaborative sessions on mission-oriented technology programs.", "people", "photo-1517245386807-bb43f82c33c4"),
                item("Technology Demonstration", "Researchers showcasing indigenous innovations in computing, security and digital platforms.", "cpu", "photo-1550751827-4bd374c3f58b"),
                item("Leadership Address", "Distinguished leaders outlining a shared vision for public digital innovation.", "mic", "photo-1505373877841-8d25f7d46678"),
                item("Innovation Awards", "Celebrating excellence in applied research and technology development.", "award", "photo-1523580494863-6f3031224c94"),
                item("HPC Research Review", "Technical teams presenting high performance computing use cases for scientific workloads.", "hdd-network", "photo-1558494949-ef010cbdcc31"),
                item("Cyber Security Briefing", "Experts reviewing secure architectures for resilient public digital infrastructure.", "shield", "photo-1563986768609-322da13575f3"),
                item("Academic Roundtable", "Researchers and institutions mapping opportunities for shared laboratories and training.", "mortarboard", "photo-1522202176988-66273c2fd55f"),
                item("Prototype Showcase", "Engineering teams presenting working models and research prototypes.", "boxes", "photo-1581090464777-f3220bbe1b8b"),
                item("Delegate Interaction", "Participants connecting across centres, institutions and technical disciplines.", "chat", "photo-1556761175-b413da4baf72"),
                item("Digital Governance Session", "Program teams discussing platforms for citizen-centric service delivery.", "building", "photo-1552664730-d307ca884978"),
                item("Innovation Lab Visit", "Attendees exploring applied research environments and development facilities.", "beaker", "photo-1581091226825-a6a2a5aee158"),
                item("Closing Plenary", "The retreat concluded with a forward roadmap for CDAC research collaboration.", "flag", "photo-1521737711867-e3b97375f902")
        );
    }

    private static List<ContentItem> gallery2025() {
        return List.of(
                item("AI Research Showcase", "Teams demonstrating responsible AI applications for public and enterprise transformation.", "robot", "photo-1677442136019-21780ecad995"),
                item("Cloud Computing Track", "Architects presenting scalable cloud platforms for government-grade workloads.", "cloud", "photo-1558494949-ef010cbdcc31"),
                item("Cyber Range Demonstration", "Security teams simulating threat scenarios and resilient response workflows.", "shield-lock", "photo-1563986768609-322da13575f3"),
                item("Startup Innovation Pavilion", "Founders discussing pilot opportunities with researchers and institutional leaders.", "rocket", "photo-1556761175-b413da4baf72"),
                item("Semiconductor Dialogue", "Experts examining electronics, chips and strategic technology manufacturing readiness.", "memory", "photo-1518770660439-4636190af475"),
                item("Government Technology Forum", "Public-sector leaders reviewing implementation models for digital governance.", "building-gear", "photo-1552664730-d307ca884978"),
                item("Data Centre Systems", "Infrastructure teams presenting resilient hosting and compute environments.", "server", "photo-1551808525-51a94da548ce"),
                item("Innovation Awards", "Recognizing teams that advanced applied research and engineering excellence.", "award", "photo-1523580494863-6f3031224c94"),
                item("Panel Discussion", "Experts debating the next phase of national digital transformation.", "people", "photo-1505373877841-8d25f7d46678"),
                item("Research Poster Walk", "Scholars presenting focused findings to technical reviewers and collaborators.", "clipboard-data", "photo-1522202176988-66273c2fd55f"),
                item("Networking Evening", "Industry experts interacting with research teams and program leaders.", "cup-hot", "photo-1517245386807-bb43f82c33c4"),
                item("Valedictory Session", "Participants closed the retreat with commitments for continued collaboration.", "flag", "photo-1521737711867-e3b97375f902")
        );
    }

    private static List<ContentItem> gallery2026() {
        return List.of(
                item("Future Technology Plenary", "National leaders presenting the vision for self-reliant digital technology capability.", "stars", "photo-1505373877841-8d25f7d46678"),
                item("Quantum Computing Dialogue", "Researchers exploring quantum-ready algorithms, systems and applied research priorities.", "brilliance", "photo-1518770660439-4636190af475"),
                item("HPC Demonstration Zone", "Teams showcasing advanced computing for scientific, industrial and strategic workloads.", "cpu-fill", "photo-1558494949-ef010cbdcc31"),
                item("Digital Public Infrastructure Lab", "Platform teams demonstrating secure, interoperable systems for population-scale services.", "diagram-3", "photo-1551288049-bebda4e38f71"),
                item("Electronics System Design", "Engineers presenting embedded systems and electronics design capabilities.", "memory", "photo-1581091226825-a6a2a5aee158"),
                item("Robotics and Automation", "Innovation teams demonstrating intelligent systems for practical field applications.", "robot", "photo-1485827404703-89b55fcc595e"),
                item("Cyber Resilience Briefing", "Security leaders outlining trusted architectures for national digital infrastructure.", "shield-lock", "photo-1563986768609-322da13575f3"),
                item("Startup Research Connect", "Startups and CDAC teams identifying translational research and deployment pathways.", "rocket", "photo-1556761175-5973dc0f32e7"),
                item("Government Roundtable", "Departments and technologists aligning future programs with implementation priorities.", "building", "photo-1552664730-d307ca884978"),
                item("Innovation Awards", "Celebrating research outcomes with strategic relevance and implementation potential.", "award", "photo-1523580494863-6f3031224c94"),
                item("Strategic Partnership Signing", "Institutions formalizing collaboration for long-term digital technology programs.", "pen", "photo-1521791136064-7986c2920216"),
                item("Closing Vision Session", "The retreat closed with a roadmap for India's next digital decade.", "flag", "photo-1521737711867-e3b97375f902")
        );
    }

    private static List<ContentItem> videosFor(String opening, String keynote, String showcase, String demos, String closing) {
        return List.of(
                item(opening, "A polished record of the inaugural moments, lamp lighting, welcome remarks and institutional priorities that set the tone for the retreat.", "play-circle", "photo-1505373877841-8d25f7d46678"),
                item(keynote, "Leadership perspectives on national digital capability, research excellence and the technology roadmap ahead.", "mic-fill", "photo-1523580494863-6f3031224c94"),
                item(showcase, "Featured innovations from CDAC teams, including research prototypes, platforms and applied technology demonstrations.", "collection-play", "photo-1550751827-4bd374c3f58b"),
                item(demos, "Hands-on demonstrations covering advanced computing, cyber security, electronics, cloud and digital public infrastructure.", "camera-video", "photo-1558494949-ef010cbdcc31"),
                item(closing, "A concise summary of achievements, awards, collaborations and commitments for the year ahead.", "flag-fill", "photo-1521737711867-e3b97375f902")
        );
    }

    private static List<ContentItem> timelineFor(String audience, String showcase, String roadmap) {
        return List.of(
                item("Registration", "Delegates completed credentialing, received program kits and connected with the retreat coordination desk.", "person-badge", null),
                item("Welcome Breakfast", "Participants gathered informally with " + audience + " before the formal sessions began.", "cup-hot", null),
                item("Opening Ceremony", "The retreat opened with institutional welcome remarks, mission context and ceremonial proceedings.", "door-open", null),
                item("Keynote Session", "Senior leaders shared strategic priorities for indigenous innovation and digital transformation.", "mic", null),
                item("Research Showcase", "Teams presented progress, research outcomes and project roadmaps across CDAC technology domains.", "clipboard-data", null),
                item("Technology Demonstrations", "The agenda moved into " + showcase + " with live walkthroughs and technical Q&A.", "cpu", null),
                item("Networking Lunch", "Delegates used curated table conversations to identify collaboration and pilot opportunities.", "people", null),
                item("Panel Discussion", "Experts examined implementation challenges, standards, adoption pathways and future skills.", "chat-square-text", null),
                item("Awards Ceremony", "Outstanding researchers and teams were recognized for contribution, execution and technical impact.", "award", null),
                item("Closing Address", "The final session consolidated learnings into an " + roadmap + ".", "flag", null)
        );
    }

    private static List<SpeakerProfile> speakers2024() {
        return List.of(
                speaker("Dr. Rajesh Kumar", "Director", "Centre for Development of Advanced Computing", "Artificial Intelligence Research", "photo-1560250097-0b93528c311a"),
                speaker("Dr. Meera Sharma", "Senior Scientist", "High Performance Computing Division", "Supercomputing Applications", "photo-1573496359142-b8d87734a5a2"),
                speaker("Mr. Arvind Nair", "Technology Advisor", "Digital India Mission", "Digital Governance Platforms", "photo-1568602471122-7832951cc4c5"),
                speaker("Dr. Kavita Menon", "Professor", "National Institute of Technology", "Collaborative Research Models", "photo-1580894732444-8ecded7900cd"),
                speaker("Ms. Priya Desai", "Program Lead", "Government Technology Cell", "Public Digital Services", "photo-1494790108377-be9c29b29330"),
                speaker("Dr. Sameer Iyer", "Principal Engineer", "Advanced Computing Systems", "Indigenous Computing", "photo-1500648767791-00dcc994a43e"),
                speaker("Ms. Nandita Rao", "Innovation Manager", "CDAC Research Programs", "Technology Commercialization", "photo-1534751516642-a1af1ef26a56"),
                speaker("Prof. Amit Bhatia", "Research Chair", "Academic Technology Consortium", "Applied Engineering Education", "photo-1519085360753-af0119f7cbe7")
        );
    }

    private static List<SpeakerProfile> speakers2025() {
        return List.of(
                speaker("Dr. Ananya Sen", "Executive Director", "Centre for Development of Advanced Computing", "Digital Transformation", "photo-1573496358961-3c82861ab8f4"),
                speaker("Dr. Vikram Joshi", "Chief Scientist", "Artificial Intelligence Group", "Responsible AI Systems", "photo-1560250097-0b93528c311a"),
                speaker("Ms. Ritu Malhotra", "Cyber Security Lead", "National Security Technology Program", "Cyber Resilience", "photo-1580894732444-8ecded7900cd"),
                speaker("Mr. Devendra Shah", "Cloud Architect", "Government Cloud Mission", "Secure Cloud Platforms", "photo-1568602471122-7832951cc4c5"),
                speaker("Dr. Farah Khan", "Semiconductor Researcher", "Electronics Systems Division", "Semiconductor Technologies", "photo-1494790108377-be9c29b29330"),
                speaker("Mr. Karan Mehta", "Founder", "GovTech Startup Network", "Startup Innovation", "photo-1500648767791-00dcc994a43e"),
                speaker("Prof. Leena Nambiar", "Dean Research", "Institute of Digital Sciences", "Academic Partnerships", "photo-1534751516642-a1af1ef26a56"),
                speaker("Ms. Shalini Gupta", "Mission Director", "Digital Governance Office", "Citizen Service Platforms", "photo-1573497019940-1c28c88b4f3e")
        );
    }

    private static List<SpeakerProfile> speakers2026() {
        return List.of(
                speaker("Dr. Suresh Pillai", "Director General", "Centre for Development of Advanced Computing", "National Digital Capability", "photo-1560250097-0b93528c311a"),
                speaker("Dr. Isha Raman", "Quantum Research Lead", "Future Computing Division", "Quantum Computing", "photo-1573496359142-b8d87734a5a2"),
                speaker("Mr. Prakash Nair", "Chief Architect", "Digital Public Infrastructure Program", "Interoperable Platforms", "photo-1568602471122-7832951cc4c5"),
                speaker("Dr. Neelima Rao", "Principal Scientist", "High Performance Computing Mission", "Exascale Systems", "photo-1580894732444-8ecded7900cd"),
                speaker("Mr. Abhinav Reddy", "Technology Advisor", "Ministry Digital Programs", "Government Enterprise Technology", "photo-1500648767791-00dcc994a43e"),
                speaker("Dr. Pooja Shah", "ESDM Specialist", "Electronics System Design Group", "Embedded and Semiconductor Systems", "photo-1494790108377-be9c29b29330"),
                speaker("Prof. Harish Kulkarni", "Chair", "National Research Collaboration Council", "Academic Research Networks", "photo-1519085360753-af0119f7cbe7"),
                speaker("Ms. Tara Kapoor", "Industry Partnership Lead", "Strategic Technology Forum", "Public-Private Innovation", "photo-1534751516642-a1af1ef26a56")
        );
    }

    private static List<ContentItem> momentsFor(String year, String intro) {
        return List.of(
                item("Innovation", intro + " Teams demonstrated solutions shaped by technical rigor, public purpose and deployment awareness.", "lightbulb", null),
                item("Collaboration", "The retreat created working conversations between centres, ministries, academia, startups and industry partners.", "people", null),
                item("Knowledge Sharing", "Deep technical sessions converted research learning into reusable insight for programs across the ecosystem.", "journal-code", null),
                item("Networking", "Curated interactions helped participants identify mentors, pilots, collaborators and implementation pathways.", "diagram-3", null),
                item("Leadership", "Senior voices connected technology ambition with national priorities and institutional accountability.", "person-check", null),
                item("Research", "Project teams presented evidence, prototypes and future milestones across strategic domains.", "search", null),
                item("Technology", "Demonstrations made advanced systems tangible through live walkthroughs, architecture reviews and use cases.", "cpu", null),
                item("Future Vision", "Retreat " + year + " closed with a forward-looking roadmap for self-reliant digital innovation.", "stars", null)
        );
    }

    private static List<Testimonial> testimonialsFor(String year) {
        return List.of(
                new Testimonial("Retreat " + year + " demonstrated the strength of CDAC's research community. The discussions moved beyond presentations and created actionable pathways for indigenous platforms, advanced computing and trusted digital infrastructure.", "Director", "Centre for Development of Advanced Computing"),
                new Testimonial("The retreat gave scientists a valuable opportunity to compare methods, refine project directions and understand deployment expectations. It strengthened the bridge between laboratory research and national technology programs.", "Senior Scientist", "Advanced Computing Division"),
                new Testimonial("For industry, the retreat offered rare access to serious technical teams and government priorities in one setting. The quality of conversations made collaboration more focused, credible and implementation-oriented.", "Industry Expert", "Technology Solutions Partner"),
                new Testimonial("As a research scholar, I found the sessions inspiring and practical. The exposure to senior scientists, real project reviews and future technology tracks helped me understand how research can serve national impact.", "Research Scholar", "Academic Research Institution"),
                new Testimonial("The retreat aligned innovation with governance needs in a meaningful way. It helped public institutions see emerging technologies not as isolated pilots, but as building blocks for resilient digital services.", "Government Official", "Digital Governance Program")
        );
    }

    private static List<ContentItem> faqs() {
        return List.of(
                item("Who can attend the retreat?", "The retreat is designed for CDAC teams, government stakeholders, invited industry partners, academic institutions, startups, researchers and technology leaders connected to the event agenda.", "question-circle", null),
                item("How are speakers selected?", "Speakers are selected based on domain expertise, relevance to the annual theme, contribution to national digital priorities and ability to share actionable technical insight.", "question-circle", null),
                item("Can industry organizations participate?", "Yes. Industry participation is encouraged through invited sessions, technology demonstrations, partnership discussions, startup showcases and selected collaboration tracks.", "question-circle", null),
                item("How can researchers present projects?", "Researchers may submit or nominate projects through the retreat coordination process, including abstracts, demonstrations, posters or centre-level recommendations.", "question-circle", null),
                item("Will participation certificates be provided?", "Participation certificates may be issued to registered delegates, speakers, presenters and contributors according to the retreat's official participation guidelines.", "question-circle", null),
                item("Are startup demonstrations included?", "Where aligned with the annual theme, startups can participate in innovation showcases, pilot discussions and curated networking with research and government stakeholders.", "question-circle", null),
                item("What technology domains are covered?", "The program covers AI, cyber security, HPC, cloud, quantum computing, ESDM, digital governance, data platforms, health informatics and other strategic technologies.", "question-circle", null),
                item("Is the retreat open to students?", "Selected students, research scholars and academic representatives may be invited through institutional channels, especially for research showcases and knowledge sessions.", "question-circle", null),
                item("Can organizations propose collaboration?", "Yes. Organizations can propose collaboration through official channels, detailing the technology area, expected outcomes, research relevance and implementation pathway.", "question-circle", null),
                item("Where will official updates be published?", "Official schedules, participation details, speaker announcements and post-event updates will be shared through CDAC and Tec-Verse communication channels.", "question-circle", null)
        );
    }

    private static ContentItem item(String title, String description, String icon, String imageId) {
        return new ContentItem(title, description, icon, imageId == null ? null : unsplash(imageId, "900", "650"));
    }

    private static StatItem stat(String value, String label) {
        return new StatItem(value, label);
    }

    private static SpeakerProfile speaker(String name, String designation, String organization, String expertise, String imageId) {
        return new SpeakerProfile(name, designation, organization, expertise, unsplash(imageId, "500", "500"));
    }

    private static String unsplash(String imageId, String width, String height) {
        return "https://images.unsplash.com/" + imageId + "?auto=format&fit=crop&w=" + width + "&h=" + height + "&q=80";
    }

    @GetMapping("/news-updates")
    public String newsUpdates(Model model) {
        model.addAttribute("newsItems", newsUpdatesForDisplay());
        return "news-updates";
    }

    @GetMapping("/news-updates/{slug}")
    public String newsDetail(@PathVariable("slug") String slug, Model model) {
        NewsItem newsItem = newsUpdateRepository.findBySlugAndActiveTrue(slug)
                .map(PageController::newsItem)
                .orElseGet(() -> NEWS_ITEMS.stream()
                        .filter(item -> item.slug().equals(slug))
                        .findFirst()
                        .orElseThrow(() -> new ResponseStatusException(NOT_FOUND)));

        model.addAttribute("newsItem", newsItem);
        return "news-detail";
    }

    private List<NewsItem> newsUpdatesForDisplay() {
        List<NewsItem> updates = newsUpdateRepository.findByActiveTrueOrderByPublishedDateDescIdDesc()
                .stream()
                .map(PageController::newsItem)
                .toList();
        return updates.isEmpty() ? NEWS_ITEMS : updates;
    }

    private static NewsItem newsItem(NewsUpdate update) {
        return new NewsItem(
                update.getSlug(),
                update.getTitle(),
                update.getDateLabel(),
                update.getImageUrl(),
                update.getDisplayExcerpt(),
                update.getParagraphs()
        );
    }

    private String message(String code) {
        return messageSource.getMessage(code, null, LocaleContextHolder.getLocale());
    }

}
