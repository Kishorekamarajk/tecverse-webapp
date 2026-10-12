(function () {
    var SPEED_PX_PER_SEC = 40;

    function initTestimonialSlider() {
        var viewport = document.querySelector('[data-testimonial-viewport]');
        var track = document.querySelector('[data-testimonial-track]');
        if (!viewport || !track) return;

        var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (reduceMotion) return;

        var offset = 0;
        var paused = false;
        var loopWidth = track.scrollWidth / 2;
        var lastTimestamp = null;

        viewport.addEventListener('mouseenter', function () { paused = true; });
        viewport.addEventListener('mouseleave', function () { paused = false; });
        viewport.addEventListener('focusin', function () { paused = true; });
        viewport.addEventListener('focusout', function () { paused = false; });

        function step(timestamp) {
            if (lastTimestamp === null) lastTimestamp = timestamp;
            var delta = (timestamp - lastTimestamp) / 1000;
            lastTimestamp = timestamp;

            if (!paused) {
                offset += SPEED_PX_PER_SEC * delta;
                if (offset >= loopWidth) offset -= loopWidth;
                track.style.transform = 'translateX(' + (-offset) + 'px)';
            }

            requestAnimationFrame(step);
        }

        requestAnimationFrame(step);
    }

    document.addEventListener('DOMContentLoaded', initTestimonialSlider);
})();
