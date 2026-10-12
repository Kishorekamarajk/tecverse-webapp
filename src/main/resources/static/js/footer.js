(function () {
    function initFooterReveal() {
        var root = document.querySelector('[data-footer-reveal]');
        if (!root) return;

        var animatedItems = root.querySelectorAll('[data-reveal-hidden]');
        if (!animatedItems.length) return;

        var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        function reveal() {
            animatedItems.forEach(function (el) {
                el.classList.remove('opacity-0', 'translate-y-8', 'scale-75');
                el.classList.add('opacity-100');
            });
        }

        if (reduceMotion || !('IntersectionObserver' in window)) {
            reveal();
            return;
        }

        var observer = new IntersectionObserver(function (entries, obs) {
            entries.forEach(function (entry) {
                if (!entry.isIntersecting) return;
                reveal();
                obs.disconnect();
            });
        }, { threshold: 0.15, rootMargin: '0px 0px -60px 0px' });

        observer.observe(root);
    }

    document.addEventListener('DOMContentLoaded', initFooterReveal);
})();
