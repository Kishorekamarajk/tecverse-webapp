(function () {
    var SETTLE_CLASSES = ['opacity-100', 'translate-x-0', 'translate-y-0', 'scale-100'];
    var HIDDEN_CLASSES = ['opacity-0', 'translate-y-4', 'translate-y-6', '-translate-y-4', '-translate-x-10', 'scale-95'];
    var COUNT_DURATION = 1400;

    function reveal(items) {
        items.forEach(function (el) {
            HIDDEN_CLASSES.forEach(function (cls) { el.classList.remove(cls); });
            SETTLE_CLASSES.forEach(function (cls) { el.classList.add(cls); });
        });
    }

    function easeOutQuad(t) {
        return 1 - (1 - t) * (1 - t);
    }

    function animateCount(el, reduceMotion) {
        if (!el.hasAttribute('data-stat-target')) return;

        var target = parseInt(el.getAttribute('data-stat-target'), 10) || 0;

        if (reduceMotion) {
            el.textContent = target;
            return;
        }

        var start = null;

        function step(timestamp) {
            if (start === null) start = timestamp;
            var progress = Math.min((timestamp - start) / COUNT_DURATION, 1);
            el.textContent = Math.round(target * easeOutQuad(progress));
            if (progress < 1) {
                requestAnimationFrame(step);
            } else {
                el.textContent = target;
            }
        }

        requestAnimationFrame(step);
    }

    function showStatSuffix(el) {
        var suffix = el.parentElement && el.parentElement.querySelector('[data-stat-suffix]');
        if (suffix) {
            suffix.hidden = false;
        }
    }

    function setStatistics(statValues, data) {
        statValues.forEach(function (el) {
            var key = el.getAttribute('data-stat-key');
            var value = Number(data && data[key]);
            if (!Number.isFinite(value) || value < 0) {
                return;
            }
            el.setAttribute('data-stat-target', Math.floor(value).toString());
            showStatSuffix(el);
        });
    }

    function statisticsUrl(root) {
        var configuredUrl = root.getAttribute('data-statistics-url');
        if (configuredUrl) return configuredUrl;

        // Derive the webapp context from this script URL when a cached/older
        // template does not provide data-statistics-url.
        var script = Array.prototype.find.call(document.scripts, function (item) {
            return item.src && item.src.indexOf('/js/about-section.js') !== -1;
        });
        if (script) {
            var scriptPath = new URL(script.src, window.location.href).pathname;
            var scriptSuffix = '/js/about-section.js';
            var suffixIndex = scriptPath.lastIndexOf(scriptSuffix);
            if (suffixIndex >= 0) {
                return scriptPath.slice(0, suffixIndex) + '/api/statistics';
            }
        }
        return '/api/statistics';
    }

    function loadStatistics(root, statValues) {
        var url = statisticsUrl(root);
        function fetchAttempt(attempt) {
            return fetch(url, {
                headers: { 'Accept': 'application/json' },
                credentials: 'same-origin'
            }).then(function (response) {
                if (!response.ok) throw new Error('Statistics API returned HTTP ' + response.status);
                return response.json();
            }).then(function (data) {
                setStatistics(statValues, data);
            }).catch(function (error) {
                if (attempt < 2) {
                    return new Promise(function (resolve) {
                        window.setTimeout(resolve, 400 * (attempt + 1));
                    }).then(function () { return fetchAttempt(attempt + 1); });
                }
                console.error('Error loading statistics:', error);
            });
        }
        return fetchAttempt(0);
    }

    function initAboutSection() {
        var root = document.querySelector('[data-about-reveal]');
        if (!root) return;

        var revealItems = root.querySelectorAll('[data-reveal-hidden]');
        var statValues = root.querySelectorAll('[data-stat-value]');
        var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        var statisticsReady = loadStatistics(root, statValues);

        function triggerAll() {
            reveal(revealItems);
            statisticsReady.then(function () {
                statValues.forEach(function (el) { animateCount(el, reduceMotion); });
            });
        }

        if (reduceMotion || !('IntersectionObserver' in window)) {
            triggerAll();
            return;
        }

        var observer = new IntersectionObserver(function (entries, obs) {
            entries.forEach(function (entry) {
                if (!entry.isIntersecting) return;
                triggerAll();
                obs.disconnect();
            });
        }, { threshold: 0.15, rootMargin: '0px 0px -80px 0px' });

        observer.observe(root);
    }

    document.addEventListener('DOMContentLoaded', initAboutSection);
})();
