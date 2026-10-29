(function () {
    var safeMethods = ['GET', 'HEAD', 'OPTIONS', 'TRACE'];
    var originalFetch = window.fetch.bind(window);
    var script = Array.from(document.scripts).find(function (item) {
        try { return new URL(item.src, window.location.href).pathname.endsWith('/js/main.js'); }
        catch (_) { return false; }
    });
    var scriptPath = script ? new URL(script.src, window.location.href).pathname : '';
    var appContext = scriptPath.endsWith('/js/main.js')
        ? scriptPath.slice(0, -'/js/main.js'.length)
        : '';
    var csrfEndpoint = appContext + '/csrf';
    var csrfTokenRequest = null;

    function loadCsrfToken() {
        if (!csrfTokenRequest) {
            csrfTokenRequest = originalFetch(csrfEndpoint, {
                method: 'GET',
                credentials: 'same-origin',
                cache: 'no-store',
                headers: { 'Accept': 'application/json' }
            }).then(function (response) {
                if (!response.ok) throw new Error('Could not load the request security token.');
                return response.json();
            }).catch(function (error) {
                csrfTokenRequest = null;
                throw error;
            });
        }
        return csrfTokenRequest;
    }

    window.fetch = async function (input, init) {
        init = init || {};
        var method = (init.method || (input instanceof Request ? input.method : 'GET')).toUpperCase();
        var requestUrl = new URL(typeof input === 'string' ? input : input.url, window.location.href);

        if (requestUrl.origin === window.location.origin && safeMethods.indexOf(method) < 0) {
            var csrf = await loadCsrfToken();
            var headers = new Headers(init.headers || (input instanceof Request ? input.headers : undefined));
            if (!headers.has(csrf.headerName)) headers.set(csrf.headerName, csrf.token);
            init = Object.assign({}, init, { headers: headers });
        }

        return originalFetch(input, init);
    };
})();

(function () {
    var SUPPORTED_LANGUAGES = ['en', 'ta', 'hi'];

    function currentLanguage() {
        var queryLang = new URLSearchParams(window.location.search).get('lang');
        if (SUPPORTED_LANGUAGES.indexOf(queryLang) >= 0) return queryLang;

        var lang = document.documentElement.getAttribute('lang') || 'en';
        return SUPPORTED_LANGUAGES.indexOf(lang) >= 0 ? lang : 'en';
    }

    function updateButtons(lang) {
        document.querySelectorAll('[data-language-button]').forEach(function (button) {
            var isActive = button.getAttribute('data-language-button') === lang;
            button.classList.toggle('active', isActive);
            button.setAttribute('aria-pressed', isActive ? 'true' : 'false');
        });
    }

    function changeLanguage(lang) {
        if (SUPPORTED_LANGUAGES.indexOf(lang) < 0) return;
        var url = new URL(window.location.href);
        url.searchParams.set('lang', lang);
        window.location.href = url.toString();
    }

    function initLanguageSwitcher() {
        var lang = currentLanguage();
        updateButtons(lang);

        document.querySelectorAll('[data-language-button]').forEach(function (button) {
            button.addEventListener('click', function () {
                changeLanguage(button.getAttribute('data-language-button'));
            });
        });

    }

    document.addEventListener('DOMContentLoaded', initLanguageSwitcher);
})();

(function () {
    var navbar = document.querySelector('.site-navbar');
    if (!navbar) return;

    var SCROLL_THRESHOLD = 60;

    function updateNavbar() {
        if (window.scrollY > SCROLL_THRESHOLD) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    }

    document.addEventListener('DOMContentLoaded', updateNavbar);
    window.addEventListener('scroll', updateNavbar, { passive: true });
})();

(function () {
    function initNavbarDropdownAutoClose() {
        var dropdowns = document.querySelectorAll('.site-navbar .nav-item.dropdown');
        if (!dropdowns.length) return;

        var desktopQuery = window.matchMedia('(min-width: 1200px)');

        function closeDropdown(dropdown) {
            var toggle = dropdown.querySelector('.dropdown-toggle');
            var menu = dropdown.querySelector('.dropdown-menu');
            if (!toggle || !menu) return;

            if (window.bootstrap && window.bootstrap.Dropdown) {
                window.bootstrap.Dropdown.getOrCreateInstance(toggle).hide();
            }

            dropdown.classList.remove('show');
            menu.classList.remove('show');
            toggle.classList.remove('show');
            toggle.setAttribute('aria-expanded', 'false');
        }

        function closeOpenDropdownsExcept(activeDropdown) {
            if (!desktopQuery.matches) return;

            dropdowns.forEach(function (dropdown) {
                if (dropdown === activeDropdown) return;
                closeDropdown(dropdown);
            });
        }

        dropdowns.forEach(function (dropdown) {
            var toggle = dropdown.querySelector('.dropdown-toggle');

            dropdown.addEventListener('mouseleave', function () {
                if (!desktopQuery.matches) return;
                closeDropdown(dropdown);
            });

            dropdown.addEventListener('focusout', function () {
                window.setTimeout(function () {
                    if (dropdown.contains(document.activeElement)) return;
                    closeDropdown(dropdown);
                }, 0);
            });

            if (toggle) {
                toggle.addEventListener('click', function () {
                    closeOpenDropdownsExcept(dropdown);
                });
            }
        });

        document.addEventListener('pointermove', function (event) {
            if (!desktopQuery.matches) return;

            var target = event.target;
            if (!target || typeof target.closest !== 'function') return;

            var activeDropdown = target.closest('.site-navbar .nav-item.dropdown');
            if (activeDropdown) {
                closeOpenDropdownsExcept(activeDropdown);
                return;
            }

            dropdowns.forEach(function (dropdown) {
                closeDropdown(dropdown);
            });
        });
    }

    document.addEventListener('DOMContentLoaded', initNavbarDropdownAutoClose);
})();

(function () {
    function initScrollReveal() {
        var items = document.querySelectorAll('[data-reveal]');
        if (!items.length) return;

        var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (reduceMotion || !('IntersectionObserver' in window)) {
            items.forEach(function (el) { el.classList.add('reveal-visible'); });
            return;
        }

        var observer = new IntersectionObserver(function (entries, obs) {
            entries.forEach(function (entry) {
                if (!entry.isIntersecting) return;
                var el = entry.target;
                var delay = el.getAttribute('data-reveal-delay');
                if (delay) {
                    el.style.transitionDelay = delay + 'ms';
                }
                el.classList.add('reveal-visible');
                obs.unobserve(el);
            });
        }, { threshold: 0.15, rootMargin: '0px 0px -40px 0px' });

        items.forEach(function (el) { observer.observe(el); });
    }

    document.addEventListener('DOMContentLoaded', initScrollReveal);
})();

(function () {
    function initSpeakerMoreButton() {
        var button = document.querySelector('[data-speakers-more-button]');
        var moreSpeakers = document.querySelector('[data-more-speakers]');
        if (!button || !moreSpeakers) return;

        button.addEventListener('click', function () {
            moreSpeakers.classList.remove('hidden');
            moreSpeakers.classList.add('grid');
            button.parentElement.classList.add('hidden');

            moreSpeakers.querySelectorAll('[data-reveal]').forEach(function (el) {
                el.classList.add('reveal-visible');
            });
        });
    }

    document.addEventListener('DOMContentLoaded', initSpeakerMoreButton);
})();

(function () {
    function initChiefGuestsCarousel() {
        document.querySelectorAll('[data-chief-guests-carousel]').forEach(function (carousel) {
            var track = carousel.querySelector('[data-chief-guests-track]');
            var slides = Array.prototype.slice.call(carousel.querySelectorAll('[data-chief-guests-slide]'));
            var dotsWrap = carousel.querySelector('[data-chief-guests-dots]');
            if (!track || !slides.length || !dotsWrap) return;

            var dots = Array.prototype.slice.call(dotsWrap.querySelectorAll('[data-chief-guests-dot]'));
            var activeIndex = 0;
            var timer = null;

            function totalSlides() {
                return slides.length;
            }

            function syncDots() {
                var total = totalSlides();
                dots.forEach(function (dot, index) {
                    var hidden = index >= total;
                    dot.hidden = hidden;
                    dot.classList.toggle('active', !hidden && index === activeIndex);
                    dot.setAttribute('aria-pressed', !hidden && index === activeIndex ? 'true' : 'false');
                });
            }

            function goTo(index) {
                var total = totalSlides();
                activeIndex = (index + total) % total;
                track.style.transform = 'translateX(-' + (activeIndex * 100) + '%)';
                syncDots();
            }

            function start() {
                stop();
                if (totalSlides() <= 1) return;
                timer = window.setInterval(function () {
                    goTo(activeIndex + 1);
                }, 3500);
            }

            function stop() {
                if (!timer) return;
                window.clearInterval(timer);
                timer = null;
            }

            dots.forEach(function (dot) {
                dot.addEventListener('click', function () {
                    var index = parseInt(dot.getAttribute('data-chief-guests-dot'), 10);
                    if (!Number.isFinite(index)) return;
                    goTo(index);
                    start();
                });
            });

            carousel.addEventListener('mouseenter', stop);
            carousel.addEventListener('mouseleave', start);
            carousel.addEventListener('focusin', stop);
            carousel.addEventListener('focusout', start);

            window.addEventListener('resize', function () {
                if (activeIndex >= totalSlides()) activeIndex = 0;
                goTo(activeIndex);
                start();
            });

            goTo(0);
            start();
        });
    }

    document.addEventListener('DOMContentLoaded', initChiefGuestsCarousel);
})();

(function () {
    function markRequiredFields(root) {
        var fields = root.querySelectorAll('form input[required], form select[required], form textarea[required]');
        fields.forEach(function (field) {
            if (field.type === 'hidden' || field.type === 'button' || field.type === 'submit') return;

            var label = field.closest('label');
            if (!label && field.id) {
                label = document.querySelector('label[for="' + CSS.escape(field.id) + '"]');
            }
            if (!label || label.querySelector('.required-field-marker, .tr-required-star')) return;
            if (label.textContent.trim().endsWith('*')) {
                var walker = document.createTreeWalker(label, NodeFilter.SHOW_TEXT);
                var textNodes = [];
                while (walker.nextNode()) textNodes.push(walker.currentNode);
                var trailingText = textNodes.reverse().find(function (textNode) { return /\*\s*$/.test(textNode.nodeValue); });
                if (trailingText) {
                    trailingText.nodeValue = trailingText.nodeValue.replace(/\*\s*$/, '');
                    var labelText = document.createElement('span');
                    labelText.className = 'required-field-label-text';
                    trailingText.parentNode.insertBefore(labelText, trailingText);
                    labelText.appendChild(trailingText);
                    var existingMarker = document.createElement('span');
                    existingMarker.className = 'required-field-marker';
                    existingMarker.setAttribute('aria-hidden', 'true');
                    existingMarker.textContent = ' *';
                    labelText.appendChild(existingMarker);
                }
                return;
            }

            var marker = document.createElement('span');
            marker.className = 'required-field-marker';
            marker.setAttribute('aria-hidden', 'true');
            marker.textContent = ' *';

            if (field.type === 'checkbox' || field.type === 'radio') {
                label.appendChild(marker);
            } else if (field.closest('label')) {
                label.insertBefore(marker, field);
            } else {
                label.appendChild(marker);
            }
        });
    }

    function initRequiredFieldMarkers() {
        markRequiredFields(document);
        if (window.MutationObserver) {
            new MutationObserver(function (mutations) {
                mutations.forEach(function (mutation) {
                    mutation.addedNodes.forEach(function (node) {
                        if (node.nodeType === 1) markRequiredFields(node);
                    });
                });
            }).observe(document.body, { childList: true, subtree: true });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initRequiredFieldMarkers);
    } else {
        initRequiredFieldMarkers();
    }
})();
