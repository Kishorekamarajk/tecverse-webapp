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

    // Talks to the YouTube embed over postMessage (no external API script, so the CSP stays as-is).
    // The video is revealed only once it is actually playing and YouTube's start-up control overlay
    // (prev / pause / next) has faded, and hidden again if playback pauses or autoplay is blocked.
    var YT_ORIGIN = 'https://www.youtube.com';
    var YT_PLAYING = 1;
    var CONTROLS_FADE_MS = 2500;

    function setVideoVisible(wrap, visible) {
        wrap.classList.toggle('opacity-0', !visible);
        wrap.classList.toggle('opacity-100', visible);
    }

    function initHeroVideoPlayer(wrap) {
        var iframe = wrap.querySelector('[data-hero-video]');
        if (!iframe) return;

        var revealTimer = null;
        var captionsRemoved = false;
        var heardFromPlayer = false;

        // Fallback for when the player never answers (e.g. messaging blocked): show it as before.
        window.setTimeout(function () {
            if (!heardFromPlayer) setVideoVisible(wrap, true);
        }, 8000);

        function send(func, args) {
            if (!iframe.contentWindow) return;
            iframe.contentWindow.postMessage(JSON.stringify({ event: 'command', func: func, args: args || [] }), YT_ORIGIN);
        }

        function removeCaptions() {
            send('unloadModule', ['captions']);
            send('unloadModule', ['cc']);
            send('setOption', ['captions', 'track', {}]);
        }

        function listen() {
            if (!iframe.contentWindow) return;
            iframe.contentWindow.postMessage(JSON.stringify({ event: 'listening', id: 'hero-video' }), YT_ORIGIN);
        }

        window.addEventListener('message', function (e) {
            if (e.origin !== YT_ORIGIN || e.source !== iframe.contentWindow) return;
            var data;
            try { data = typeof e.data === 'string' ? JSON.parse(e.data) : e.data; } catch (err) { return; }
            if (!data) return;
            heardFromPlayer = true;

            var state = data.event === 'onStateChange' ? data.info
                : (data.event === 'infoDelivery' && data.info && typeof data.info.playerState === 'number') ? data.info.playerState
                : null;

            if (!captionsRemoved && (data.event === 'onReady' || data.event === 'initialDelivery' || state === YT_PLAYING)) {
                captionsRemoved = true;
                removeCaptions();
            }
            if (state === null) return;

            if (state === YT_PLAYING) {
                removeCaptions();
                if (!revealTimer && !wrap.classList.contains('opacity-100')) {
                    revealTimer = window.setTimeout(function () {
                        revealTimer = null;
                        setVideoVisible(wrap, true);
                    }, CONTROLS_FADE_MS);
                }
            } else if (state === 2 || state === -1) {
                // Paused or unstarted (autoplay blocked): YouTube shows its controls, so keep it hidden.
                window.clearTimeout(revealTimer);
                revealTimer = null;
                setVideoVisible(wrap, false);
            }
        });

        iframe.addEventListener('load', listen);
        listen();
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

    ready(function () {
        var revealItems = document.querySelectorAll('[data-hero-reveal]');
        var videoWrap = document.querySelector('[data-hero-video-wrap]');
        var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        sizeHeroVideo();
        initHeroCountdown();
        window.addEventListener('resize', sizeHeroVideo);
        if (videoWrap) initHeroVideoPlayer(videoWrap);

        if (reduceMotion) {
            revealItems.forEach(settle);
            return;
        }

        requestAnimationFrame(function () {
            revealItems.forEach(settle);
        });
    });
})();
