(function () {
    'use strict';

    var intro = document.getElementById('site-intro');
    var panel = document.getElementById('site-intro-countdown-panel');
    if (!intro || !panel) return;

    var introSeenKey = 'tecverseSiteIntroSeen';                                   

    function hasSeenIntro() {
        try {
            return window.localStorage.getItem(introSeenKey) === 'true';
        } catch (error) {
            return false;
        }
    }

    function markIntroSeen() {
        try {
            window.localStorage.setItem(introSeenKey, 'true');
        } catch (error) {
            // Storage can be unavailable in private/restricted browser modes.
        }
    }

    function skipIntro() {
        intro.classList.add('site-intro--hidden');
        intro.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('site-intro-lock');
    }

    if (hasSeenIntro()) {
        skipIntro();
        return;
    }

    var target = new Date('2026-11-26T10:00:00+05:30').getTime();
    var splashDuration = 6000;
    var countdownDisplayDuration = 6000;
    var finished = false;
    var timer;
    var countdownExitTimer;

    // The exact clock sound supplied for the splash countdown.
    // It is played once from the beginning every time the splash countdown starts.
    var splashCountdownSound = new Audio('/audio/count.mpeg');
    splashCountdownSound.preload = 'auto';
    splashCountdownSound.volume = 0.90;
    var audioUnlocked = false;

    // Browsers block audible autoplay until the page has a user gesture.
    // Prime the audio element on the FIRST interaction anywhere on the
    // page — even during the initial 6s splash, before the countdown ever
    // appears — so playback is already unlocked by the time it's needed.
    function unlockAudio() {
        if (audioUnlocked) return;
        var primePromise = splashCountdownSound.play();
        if (primePromise && typeof primePromise.then === 'function') {
            primePromise.then(function () {
                audioUnlocked = true;
                splashCountdownSound.pause();
                splashCountdownSound.currentTime = 0;
                hideSoundHint();
                // If the countdown is already showing and waiting on this
                // unlock, start the clip immediately instead of at silence.
                if (intro.classList.contains('site-intro--countdown') && !finished) {
                    startSplashCountdownSound();
                }
            }).catch(function () {
                // Still blocked (e.g. no gesture yet) — will retry on the next one.
            });
        }
    }

    document.addEventListener('pointerdown', unlockAudio, { passive: true });
    document.addEventListener('touchstart', unlockAudio, { passive: true });
    document.addEventListener('keydown', unlockAudio);

    var soundHintEl = null;
    function showSoundHint(message) {
        if (audioUnlocked || !panel) return;
        if (!soundHintEl) {
            soundHintEl = document.createElement('div');
            soundHintEl.className = 'site-intro__sound-hint';
            soundHintEl.setAttribute('role', 'status');
            intro.appendChild(soundHintEl);
        }
        soundHintEl.textContent = message;
    }
    function hideSoundHint() {
        if (soundHintEl && soundHintEl.parentNode) {
            soundHintEl.parentNode.removeChild(soundHintEl);
        }
        soundHintEl = null;
    }

    function startSplashCountdownSound() {
        splashCountdownSound.pause();
        splashCountdownSound.currentTime = 0;

        var playPromise = splashCountdownSound.play();
        if (playPromise && typeof playPromise.then === 'function') {
            playPromise.then(function () {
                audioUnlocked = true;
                hideSoundHint();
            }).catch(function () {
                // Still blocked — show a tiny, unobtrusive hint so the visitor
                // knows a tap will bring the sound in, and keep retrying.
                showSoundHint('Tap anywhere for sound');
            });
        }
    }

    function retrySoundAfterInteraction() {
        if (!intro.classList.contains('site-intro--countdown') || finished) return;
        if (splashCountdownSound.paused) {
            splashCountdownSound.currentTime = 0;
            splashCountdownSound.play().then(function () {
                audioUnlocked = true;
                hideSoundHint();
            }).catch(function () {});
        }
    }

    document.addEventListener('pointerdown', retrySoundAfterInteraction, { passive: true });
    document.addEventListener('keydown', retrySoundAfterInteraction);

    function stopSplashCountdownSound() {
        splashCountdownSound.pause();
        splashCountdownSound.currentTime = 0;
    }

    function finishIntro() {
        if (finished) return;
        finished = true;
        if (timer) clearInterval(timer);
        if (countdownExitTimer) clearTimeout(countdownExitTimer);

        // Sound belongs ONLY to the splash countdown.
        stopSplashCountdownSound();
        hideSoundHint();

        intro.classList.add('site-intro--exit');
        document.body.classList.remove('site-intro-lock');

        window.setTimeout(function () {
            intro.classList.add('site-intro--hidden');
            intro.setAttribute('aria-hidden', 'true');

            var videoSection = document.getElementById('video-section');
            if (videoSection) {
                videoSection.scrollIntoView({ block: 'start' });
            }
        }, 900);
    }

    function updateCountdown() {
        var remaining = Math.max(0, target - Date.now());
        var totalSeconds = Math.floor(remaining / 1000);
        var days = Math.floor(totalSeconds / 86400);
        var hours = Math.floor((totalSeconds % 86400) / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var seconds = totalSeconds % 60;

        document.getElementById('cd-days').textContent = String(days).padStart(2, '0');
        document.getElementById('cd-hours').textContent = String(hours).padStart(2, '0');
        document.getElementById('cd-minutes').textContent = String(minutes).padStart(2, '0');
        document.getElementById('cd-seconds').textContent = String(seconds).padStart(2, '0');

        if (remaining <= 0) finishIntro();
    }

    function startCountdown() {
        intro.classList.add('site-intro--countdown');
        panel.setAttribute('aria-hidden', 'false');

        // Every splash appearance starts the supplied clock sound from 0.
        startSplashCountdownSound();

        updateCountdown();
        timer = window.setInterval(updateCountdown, 1000);

        // Keep the splash countdown visible for exactly 6 seconds.
        countdownExitTimer = window.setTimeout(finishIntro, countdownDisplayDuration);
    }

    function begin() {
        markIntroSeen();
        document.body.classList.add('site-intro-lock');

        // Invite a tap right away, during the logo phase — so by the time the
        // countdown appears 3s later, audio is already unlocked and the clip
        // starts automatically and on time.
        showSoundHint('Tap anywhere to enter');

        // Tec-verse splash remains for 6 seconds, then the 6-second countdown appears.
        window.setTimeout(function () {
            if (!finished) startCountdown();
        }, splashDuration);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', begin, { once: true });
    } else {
        begin();
    }
})();
