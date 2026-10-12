(function initTecVerseLandingAnimation() {
    var landing = document.querySelector("[data-tecverse-landing-animation]");
    var countdown = document.querySelector("[data-tecverse-countdown]");
    if (!landing || !countdown) return;

    var targetDate = new Date(2026, 10, 26, 0, 0, 0);
    var navbar = document.querySelector(".site-navbar");
    var values = {
        days: countdown.querySelector('[data-unit="days"]'),
        hours: countdown.querySelector('[data-unit="hours"]'),
        minutes: countdown.querySelector('[data-unit="minutes"]'),
        seconds: countdown.querySelector('[data-unit="seconds"]')
    };
    var labels = countdown.querySelectorAll(".tecverse-countdown-label");
    var countdownInterval;
    var autoAdvanceTimer;
    var hasAutoAdvanced = false;

    function pad(value) {
        return String(value).padStart(2, "0");
    }

    function updateCountdown() {
        var remaining = targetDate.getTime() - Date.now();

        if (remaining <= 0) {
            countdown.classList.add("is-complete");
            values.days.textContent = "00";
            values.hours.textContent = "00";
            values.minutes.textContent = "00";
            values.seconds.textContent = "00";
            labels[0].textContent = "STARTED";
            return;
        }

        var totalSeconds = Math.floor(remaining / 1000);
        var days = Math.floor(totalSeconds / 86400);
        var hours = Math.floor((totalSeconds % 86400) / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var seconds = totalSeconds % 60;

        values.days.textContent = pad(days);
        values.hours.textContent = pad(hours);
        values.minutes.textContent = pad(minutes);
        values.seconds.textContent = pad(seconds);
    }

    function setCompactLabels(isCompact) {
        labels.forEach(function (label) {
            label.textContent = label.getAttribute(isCompact ? "data-label-short" : "data-label-full");
        });
    }

    function placeFloatingCountdown() {
        var destination = destinationForCountdown();

        if (window.gsap) {
            gsap.set(countdown, {
                left: destination.x,
                top: destination.y,
                xPercent: -50,
                yPercent: -50,
                y: 0,
                opacity: 1,
                scale: 1,
                transformOrigin: "center center"
            });
            return;
        }

        countdown.style.left = destination.x + "px";
        countdown.style.top = destination.y + "px";
        countdown.style.transform = "translate(-50%, -50%)";
    }

    function setFloatingCountdown(isFloating, shouldPlace) {
        if (navbar) {
            navbar.classList.toggle("is-landing-visible", isFloating);
        }
        countdown.classList.toggle("is-compact", isFloating);
        countdown.classList.toggle("is-floating", isFloating);
        setCompactLabels(isFloating);

        if (isFloating && shouldPlace) {
            placeFloatingCountdown();
        }
    }

    function autoAdvanceToHero() {
        if (hasAutoAdvanced || window.scrollY > 12) return;

        var nextSection = landing.nextElementSibling;
        if (!nextSection) return;

        hasAutoAdvanced = true;
        setFloatingCountdown(true, true);
        nextSection.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    function scheduleAutoAdvance(delay) {
        if (autoAdvanceTimer) {
            window.clearTimeout(autoAdvanceTimer);
        }

        autoAdvanceTimer = window.setTimeout(autoAdvanceToHero, delay);
    }

    function destinationForCountdown() {
        var destination = document.querySelector("[data-tecverse-countdown-destination]");
        var destinationRect = destination ? destination.getBoundingClientRect() : null;
        var navbarRect = navbar ? navbar.getBoundingClientRect() : { bottom: 76 };
        var languageSwitcher = document.querySelector(".navbar-language-switcher");
        var languageRect = languageSwitcher ? languageSwitcher.getBoundingClientRect() : null;
        var compactWidth = window.innerWidth < 576 ? 180 : 210;
        var compactHeight = window.innerWidth < 576 ? 42 : 48;
        var viewportPadding = window.innerWidth < 576 ? 12 : 18;

        if (languageRect && languageRect.width > 0 && languageRect.height > 0) {
            var centeredBelowLanguage = languageRect.left + languageRect.width / 2;
            var minX = viewportPadding + compactWidth / 2;
            var maxX = window.innerWidth - viewportPadding - compactWidth / 2;

            return {
                x: Math.min(Math.max(centeredBelowLanguage, minX), maxX),
                y: Math.max(navbarRect.bottom, languageRect.bottom) + 12 + compactHeight / 2
            };
        }

        if (destinationRect) {
            return {
                x: destinationRect.left + destinationRect.width / 2,
                y: destinationRect.top + destinationRect.height / 2
            };
        }

        return {
            x: window.innerWidth / 2,
            y: navbarRect.bottom + (window.innerWidth < 576 ? 42 : 54)
        };
    }

    function initScrollAnimation() {
        if (!window.gsap || !window.ScrollTrigger || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
            function updateFallbackNavbar() {
                setFloatingCountdown(window.scrollY > landing.offsetHeight * 0.55, true);
            }

            updateFallbackNavbar();
            window.addEventListener("scroll", updateFallbackNavbar, { passive: true });
            scheduleAutoAdvance(1800);
            return;
        }

        gsap.registerPlugin(ScrollTrigger);

        var title = landing.querySelector(".tecverse-landing-title");
        var titleMask = landing.querySelector("[data-tecverse-title-video-mask]");
        var titleVideo = landing.querySelector(".tecverse-title-mask-video");
        var kicker = landing.querySelector(".tecverse-landing-kicker");
        var leftPanel = landing.querySelector(".tecverse-split-panel--left");
        var rightPanel = landing.querySelector(".tecverse-split-panel--right");
        var destination = destinationForCountdown();

        gsap.set([title, titleMask], {
            scale: 0.82,
            opacity: 0,
            transformOrigin: "center center"
        });
        gsap.set(titleVideo, { scale: 1.12, opacity: 1 });

        var introTimeline = gsap.timeline({
            defaults: { ease: "power3.out" },
            onComplete: function () {
                scheduleAutoAdvance(350);
            }
        });

        introTimeline
            .to(titleVideo, { scale: 1, duration: 1.1 }, 0)
            .to([title, titleMask], {
            scale: 1,
            opacity: 1,
            duration: 0.95,
            ease: "expo.out",
            delay: 0.12
            }, 0)
            .to(leftPanel, { yPercent: -104, opacity: 0, duration: 1.1, ease: "power4.inOut" }, 1.45)
            .to(rightPanel, { yPercent: 104, opacity: 0, duration: 1.1, ease: "power4.inOut" }, 1.45)
            .to([title, titleMask], { y: -70, scale: 0.82, opacity: 0.18, duration: 0.9, ease: "power3.inOut" }, 1.52)
            .to(titleVideo, { scale: 1.08, opacity: 0.38, duration: 0.9, ease: "power3.inOut" }, 1.52)
            .to(countdown, { y: 46, opacity: 0, duration: 0.72, ease: "power3.inOut" }, 1.7);

        gsap.set(countdown, {
            left: "50%",
            top: function () {
                if (window.innerWidth < 576) return "calc(50% + 210px)";
                if (window.innerWidth < 992) return "calc(50% + clamp(180px, 27vh, 220px))";
                return "calc(50% + clamp(196px, 27vh, 252px))";
            },
            xPercent: -50,
            yPercent: -50,
            scale: 1,
            transformOrigin: "center center"
        });

        var timeline = gsap.timeline({
            defaults: { ease: "none" },
            scrollTrigger: {
                trigger: landing,
                start: "top top",
                end: "+=1200",
                scrub: true,
                pin: true,
                anticipatePin: 1,
                invalidateOnRefresh: true,
                onRefresh: function () {
                    destination = destinationForCountdown();
                },
                onUpdate: function (self) {
                    setFloatingCountdown(self.progress > 0.68, false);
                },
                onLeave: function () {
                    setFloatingCountdown(true, true);
                },
                onEnterBack: function () {
                    setFloatingCountdown(true, true);
                }
            }
        });

        timeline
            .to(leftPanel, { yPercent: -104, opacity: 0 }, 0)
            .to(rightPanel, { yPercent: 104, opacity: 0 }, 0)
            .to(kicker, { y: -42, opacity: 0 }, 0)
            .to([title, titleMask], { y: -120, scale: 0.26, opacity: 0.62 }, 0)
            .to(titleVideo, { scale: 1.08, opacity: 0.2 }, 0)
            .to(countdown, {
                left: function () { return destination.x; },
                top: function () { return destination.y; },
                xPercent: -50,
                yPercent: -50,
                scale: 1,
                transformOrigin: "center center"
            }, 0)
            .to([title, titleMask], { opacity: 0 }, 0.72);

        window.addEventListener("resize", function () {
            ScrollTrigger.refresh();
            if (countdown.classList.contains("is-floating")) {
                placeFloatingCountdown();
            }
        }, { passive: true });

        window.addEventListener("scroll", function () {
            if (window.scrollY > 12 && autoAdvanceTimer) {
                window.clearTimeout(autoAdvanceTimer);
                autoAdvanceTimer = null;
            }

            if (countdown.classList.contains("is-floating") && window.scrollY > landing.offsetHeight * 0.55) {
                placeFloatingCountdown();
            }
        }, { passive: true });
    }

    updateCountdown();
    countdownInterval = window.setInterval(updateCountdown, 1000);
    if (navbar) {
        navbar.classList.remove("is-landing-visible");
    }

    document.addEventListener("visibilitychange", function () {
        if (document.hidden) {
            window.clearInterval(countdownInterval);
            return;
        }

        updateCountdown();
        countdownInterval = window.setInterval(updateCountdown, 1000);
    });

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initScrollAnimation);
    } else {
        initScrollAnimation();
    }
})();
