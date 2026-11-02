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

    async function refreshCaptcha() {
        question.textContent = 'Loading security check…';
        challengeId.value = '';
        try {
            const response = await fetch(`${contextPath}/auth/captcha`, {headers: {Accept: 'application/json'}, credentials: 'same-origin'});
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
