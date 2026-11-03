(() => {
    const dialog = document.querySelector('[data-attendee-login-dialog]');
    if (!dialog) return;
    const contextPath = (dialog.dataset.contextPath || document.body.dataset.contextPath || '').replace(/\/$/, '');
    const stylesheet = document.createElement('link');
    stylesheet.rel = 'stylesheet';
    stylesheet.href = `${contextPath}/css/attendee-login-modal.css?v=20261102-session-return`;
    document.head.appendChild(stylesheet);

    const question = dialog.querySelector('[data-attendee-captcha-question]');
    const challengeId = dialog.querySelector('[data-attendee-captcha-id]');
    const error = dialog.querySelector('[data-attendee-login-error]');
    const form = dialog.querySelector('[data-attendee-login-form]');
    const submit = form.querySelector('[type="submit"]');
    let loginCooldown = null;
    let captchaRequest = null;

    function startLoginCooldown(seconds) {
        window.clearInterval(loginCooldown);
        let remaining = Math.max(1, Math.ceil(seconds));
        submit.disabled = true;
        const update = () => {
            error.textContent = `Too many requests. Please wait ${remaining} seconds before trying again.`;
        };
        update();
        loginCooldown = window.setInterval(() => {
            remaining -= 1;
            if (remaining <= 0) {
                window.clearInterval(loginCooldown);
                loginCooldown = null;
                submit.disabled = false;
                submit.innerHTML = 'Login <span aria-hidden="true">→</span>';
                error.textContent = 'You can try signing in again.';
            } else {
                update();
            }
        }, 1000);
    }

    const retryAfter = Number(error?.dataset.retryAfter) || 0;
    if (error && retryAfter > 0) startLoginCooldown(retryAfter);

    async function refreshCaptcha() {
        if (captchaRequest) return captchaRequest;
        question.textContent = 'Loading security check…';
        challengeId.value = '';
        captchaRequest = (async () => {
          try {
            const response = await fetch(`${contextPath}/auth/captcha`, {headers: {Accept: 'application/json'}, credentials: 'same-origin'});
            if (!response.ok) throw new Error('CAPTCHA unavailable');
            const challenge = await response.json();
            question.textContent = challenge.question;
            challengeId.value = challenge.id;
          } catch (_) {
            question.textContent = 'Unable to load the security check. Refresh to try again.';
          } finally {
            captchaRequest = null;
          }
        })();
        return captchaRequest;
    }

    function openDialog() {
        if (!dialog.open) dialog.showModal();
        if (!challengeId.value) refreshCaptcha();
        window.setTimeout(() => dialog.querySelector('#attendeeLoginEmail').focus(), 0);
    }

    document.querySelectorAll('[data-attendee-login-open]').forEach(button => button.addEventListener('click', openDialog));
    document.addEventListener('open-attendee-login', openDialog);
    dialog.querySelector('[data-attendee-login-close]').addEventListener('click', () => dialog.close());
    dialog.querySelector('[data-attendee-captcha-refresh]').addEventListener('click', refreshCaptcha);
    // Keep the login modal and its challenge intact when the backdrop is clicked.
    form.addEventListener('submit', event => {
        if (!challengeId.value) {
            event.preventDefault();
            refreshCaptcha();
            return;
        }
        submit.disabled = true;
        submit.textContent = 'Signing in…';
    });

    const params = new URLSearchParams(window.location.search);
    if (params.has('login') || error) {
        openDialog();
        if (params.has('login')) history.replaceState(null, '', window.location.pathname + window.location.hash);
    }
})();
