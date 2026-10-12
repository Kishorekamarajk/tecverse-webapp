(() => {
  const colors = ['#0b8a65', '#ffb36b', '#3aa0ff', '#0b6b68', '#ffd166'];

  window.celebrateRegistration = () => {
    if (window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) return;

    const canvas = document.createElement('canvas');
    canvas.setAttribute('aria-hidden', 'true');
    canvas.style.cssText = 'position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:20000';
    document.body.appendChild(canvas);

    const context = canvas.getContext('2d');
    if (!context) {
      canvas.remove();
      return;
    }

    const scale = Math.min(window.devicePixelRatio || 1, 2);
    const width = window.innerWidth;
    const height = window.innerHeight;
    canvas.width = width * scale;
    canvas.height = height * scale;
    context.scale(scale, scale);

    const centerX = width / 2;
    const originY = Math.min(height * 0.42, 360);
    const particles = Array.from({ length: 120 }, () => {
      const angle = Math.random() * Math.PI * 2;
      const speed = 3 + Math.random() * 8;
      return {
        x: centerX + (Math.random() - 0.5) * 100,
        y: originY + (Math.random() - 0.5) * 24,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 3,
        size: 4 + Math.random() * 6,
        rotation: Math.random() * Math.PI,
        spin: (Math.random() - 0.5) * 0.22,
        color: colors[Math.floor(Math.random() * colors.length)]
      };
    });

    const startedAt = performance.now();
    const duration = 2600;
    const draw = (now) => {
      const elapsed = now - startedAt;
      context.clearRect(0, 0, width, height);
      context.globalAlpha = Math.max(0, 1 - Math.max(0, elapsed - 1900) / 700);

      particles.forEach((particle) => {
        particle.x += particle.vx;
        particle.y += particle.vy;
        particle.vy += 0.16;
        particle.vx *= 0.992;
        particle.rotation += particle.spin;

        context.save();
        context.translate(particle.x, particle.y);
        context.rotate(particle.rotation);
        context.fillStyle = particle.color;
        context.fillRect(-particle.size / 2, -particle.size / 2, particle.size, particle.size * 1.6);
        context.restore();
      });

      if (elapsed < duration) window.requestAnimationFrame(draw);
      else canvas.remove();
    };

    window.requestAnimationFrame(draw);
  };
})();
