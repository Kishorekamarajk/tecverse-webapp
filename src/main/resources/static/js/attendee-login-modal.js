(() => {
    const stylesheet = document.createElement('link');
    stylesheet.rel = 'stylesheet';
    stylesheet.href = '/css/attendee-login-modal.css?v=20261030-brand-colors';
    document.head.appendChild(stylesheet);

    const dialog = document.querySelector('[data-attendee-login-dialog]');
    if (!dialog) return;

    const question = dialog.querySelector('[data-attendee-captcha-question]');
    const challengeId = dialog.querySelector('[data-attendee-captcha-id]');
    const error = dialog.querySelector('[data-attendee-login-error]');
    const form = dialog.querySelector('[data-attendee-login-form]');

    async function refreshCaptcha() {
        question.textContent = 'Loading security check…';
        challengeId.value = '';
        try {
            const response = await fetch('/auth/captcha', {headers: {Accept: 'application/json'}, credentials: 'same-origin'});
            if (!response.ok) throw new Error('CAPTCHA unavailable');
            const challenge = await response.json();
            question.textContent = challenge.question;
            challengeId.value = challenge.id;
        } catch (_) {
            question.textContent = 'Unable to load the security check. Refresh to try again.';
        }
    }

    function openDialog() {
        if (!dialog.open) dialog.showModal();
        refreshCaptcha();
        window.setTimeout(() => dialog.querySelector('#attendeeLoginEmail').focus(), 0);
    }

    document.querySelectorAll('[data-attendee-login-open]').forEach(button => button.addEventListener('click', openDialog));
    document.addEventListener('open-attendee-login', openDialog);
    dialog.querySelector('[data-attendee-login-close]').addEventListener('click', () => dialog.close());
    dialog.querySelector('[data-attendee-captcha-refresh]').addEventListener('click', refreshCaptcha);
    dialog.querySelector('[data-attendee-password-toggle]').addEventListener('click', event => {
        const button = event.currentTarget;
        const password = dialog.querySelector('#attendeeLoginPassword');
        const visible = password.type === 'text';
        password.type = visible ? 'password' : 'text';
        button.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
        button.setAttribute('aria-pressed', String(!visible));
        button.innerHTML = visible
            ? '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>'
            : '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m3 3 18 18M10.6 10.6a2 2 0 0 0 2.8 2.8"/><path d="M9.9 5.2A10 10 0 0 1 12 5c6.5 0 10 7 10 7a14 14 0 0 1-3.2 4.1M6.2 6.2C3.5 8 2 12 2 12s3.5 7 10 7a9.8 9.8 0 0 0 3-.5"/></svg>';
    });
    dialog.addEventListener('click', event => {
        if (event.target === dialog) dialog.close();
    });
    form.addEventListener('submit', event => {
        if (!challengeId.value) {
            event.preventDefault();
            refreshCaptcha();
            return;
        }
        const submit = form.querySelector('[type="submit"]');
        submit.disabled = true;
        submit.textContent = 'Signing in…';
    });

    const params = new URLSearchParams(window.location.search);
    if (params.has('login') || error) {
        openDialog();
        if (params.has('login')) history.replaceState(null, '', window.location.pathname + window.location.hash);
    }
})();
