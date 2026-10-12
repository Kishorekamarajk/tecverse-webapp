(function () {
    var SETTLE_CLASSES = ['opacity-100', 'translate-y-0', 'scale-100'];
    var HIDDEN_CLASSES = ['opacity-0', 'translate-y-8', 'translate-y-6', 'scale-75'];

    function settle(el) {
        HIDDEN_CLASSES.forEach(function (cls) { el.classList.remove(cls); });
        SETTLE_CLASSES.forEach(function (cls) { el.classList.add(cls); });
    }

    function ready(fn) {
        if (document.readyState !== 'loading') {
            fn();
        } else {
            document.addEventListener('DOMContentLoaded', fn);
        }
    }

    function sizeHeroVideo() {
        var wrap = document.querySelector('[data-hero-video-wrap]');
        var iframe = document.querySelector('[data-hero-video]');
        if (!wrap || !iframe) return;

        var videoRatio = 16 / 9;
        var w = wrap.clientWidth;
        var h = wrap.clientHeight;
        var containerRatio = w / h;

        var newW, newH;
        if (containerRatio > videoRatio) {
            newW = w;
            newH = w / videoRatio;
        } else {
            newH = h;
            newW = h * videoRatio;
        }

        iframe.style.width = newW + 'px';
        iframe.style.height = newH + 'px';
    }

    function initHeroCountdown() {
        var countdown = document.querySelector('[data-hero-countdown]');
        if (!countdown) return;

        var target = new Date('2026-11-26T10:00:00+05:30').getTime();
        var units = {
            days: countdown.querySelector('[data-hero-countdown-unit="days"]'),
            hours: countdown.querySelector('[data-hero-countdown-unit="hours"]'),
            minutes: countdown.querySelector('[data-hero-countdown-unit="minutes"]'),
            seconds: countdown.querySelector('[data-hero-countdown-unit="seconds"]')
        };

        function pad(value) {
            return String(value).padStart(2, '0');
        }

        function setText(unit, value) {
            if (units[unit]) {
                units[unit].textContent = unit === 'days' ? String(value).padStart(3, '0') : pad(value);
            }
        }

        function update() {
            var remaining = Math.max(0, target - Date.now());
            var totalSeconds = Math.floor(remaining / 1000);

            setText('days', Math.floor(totalSeconds / 86400));
            setText('hours', Math.floor((totalSeconds % 86400) / 3600));
            setText('minutes', Math.floor((totalSeconds % 3600) / 60));
            setText('seconds', totalSeconds % 60);
        }

        update();
        window.setInterval(update, 1000);
    }

    function disableHeroCaptions() {
        var iframe = document.querySelector('[data-hero-video]');
        if (!iframe) return;

        function unloadCaptions(player) {
            ['captions', 'cc'].forEach(function (moduleName) {
                try {
                    player.unloadModule(moduleName);
                } catch (error) {
                    // The player may not expose a caption module for this video.
                }
            });
        }

        function createPlayer() {
            if (!window.YT || !window.YT.Player) return;
            new window.YT.Player(iframe, {
                playerVars: { controls: 0, cc_load_policy: 0 },
                events: {
                    onReady: function (event) {
                        unloadCaptions(event.target);
                    },
                    onStateChange: function (event) {
                        unloadCaptions(event.target);
                    }
                }
            });
        }

        if (window.YT && window.YT.Player) {
            createPlayer();
            return;
        }

        var previousReady = window.onYouTubeIframeAPIReady;
        window.onYouTubeIframeAPIReady = function () {
            if (typeof previousReady === 'function') previousReady();
            createPlayer();
        };

        if (!document.querySelector('script[src="https://www.youtube.com/iframe_api"]')) {
            var script = document.createElement('script');
            script.src = 'https://www.youtube.com/iframe_api';
            document.head.appendChild(script);
        }
    }

    ready(function () {
        var revealItems = document.querySelectorAll('[data-hero-reveal]');
        var videoWrap = document.querySelector('[data-hero-video-wrap]');
        var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        sizeHeroVideo();
        initHeroCountdown();
        disableHeroCaptions();
        window.addEventListener('resize', sizeHeroVideo);

        if (reduceMotion) {
            revealItems.forEach(settle);
            if (videoWrap) {
                videoWrap.classList.remove('opacity-0');
                videoWrap.classList.add('opacity-100');
            }
            return;
        }

        requestAnimationFrame(function () {
            if (videoWrap) {
                videoWrap.classList.remove('opacity-0');
                videoWrap.classList.add('opacity-100');
            }
            revealItems.forEach(settle);
        });
    });
})();
