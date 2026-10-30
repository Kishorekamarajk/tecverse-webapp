(() => {
  const roleDialog = document.querySelector('[data-role-login-dialog]');
  const otpDialog = document.querySelector('[data-business-otp-dialog]');
  if (!roleDialog || !otpDialog) return;

  const roleSelect = document.getElementById('businessLoginRole');
  const phone = document.getElementById('businessLoginPhone');
  const otp = document.getElementById('businessLoginOtp');
  const message = otpDialog.querySelector('[data-business-login-message]');
  const phoneStep = otpDialog.querySelector('[data-business-phone-step]');
  const otpStep = otpDialog.querySelector('[data-business-otp-step]');
  const registerLink = otpDialog.querySelector('[data-business-register-link]');
  const sendButton = otpDialog.querySelector('[data-business-send-otp]');
  const verifyButton = otpDialog.querySelector('[data-business-verify-otp]');
  const resendButton = otpDialog.querySelector('[data-business-resend-otp]');
  let selectedRole = 'participant';
  let cooldown = null;

  function contextPath() {
    return (document.body.dataset.contextPath || '').replace(/\/$/, '');
  }

  function apiPath(path) { return contextPath() + path; }

  function setMessage(text, isError = false) {
    message.textContent = text || '';
    message.classList.toggle('is-error', isError);
  }

  async function readResult(response) {
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      const error = new Error(data.message || data.error || 'Unable to complete sign in. Please try again.');
      error.status = response.status;
      error.retryAfter = Number(response.headers.get('Retry-After')) || 0;
      error.registrationUrl = data.registrationUrl;
      throw error;
    }
    return data;
  }

  function startCooldown(seconds = 30) {
    window.clearInterval(cooldown);
    let left = seconds;
    resendButton.disabled = true;
    resendButton.textContent = `Resend OTP in ${left}s`;
    cooldown = window.setInterval(() => {
      left -= 1;
      if (left <= 0) {
        window.clearInterval(cooldown);
        cooldown = null;
        resendButton.disabled = false;
        resendButton.textContent = 'Resend OTP';
      } else resendButton.textContent = `Resend OTP in ${left}s`;
    }, 1000);
  }

  function openRoleDialog() {
    if (!roleDialog.open) roleDialog.showModal();
  }

  document.querySelectorAll('[data-role-login-open]').forEach(button => button.addEventListener('click', openRoleDialog));
  roleDialog.querySelector('[data-role-login-close]').addEventListener('click', () => roleDialog.close());
  otpDialog.querySelector('[data-business-otp-close]').addEventListener('click', () => otpDialog.close());
  roleDialog.addEventListener('click', event => { if (event.target === roleDialog) roleDialog.close(); });
  otpDialog.addEventListener('click', event => { if (event.target === otpDialog) otpDialog.close(); });

  roleDialog.querySelector('[data-role-login-continue]').addEventListener('click', () => {
    selectedRole = roleSelect.value;
    roleDialog.close();
    if (selectedRole === 'participant') {
      document.dispatchEvent(new Event('open-attendee-login'));
      return;
    }
    otpDialog.querySelector('[data-business-role-label]').textContent = `${selectedRole.toUpperCase()} PORTAL LOGIN`;
    phoneStep.hidden = false;
    otpStep.hidden = true;
    phone.value = '';
    otp.value = '';
    registerLink.hidden = true;
    setMessage('');
    if (!otpDialog.open) otpDialog.showModal();
    window.setTimeout(() => phone.focus(), 0);
  });

  async function sendOtp() {
    const cleanPhone = phone.value.trim();
    if (!/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(cleanPhone)) {
      setMessage('Enter a valid 10-digit Indian mobile number.', true);
      phone.focus();
      return;
    }
    sendButton.disabled = true;
    resendButton.disabled = true;
    registerLink.hidden = true;
    setMessage('Checking your registration and sending the code…');
    try {
      const response = await fetch(apiPath(`/business-login/${selectedRole}/send-otp`), {
        method: 'POST', headers: {'Content-Type': 'application/json', Accept: 'application/json'},
        body: JSON.stringify({phone: cleanPhone})
      });
      const result = await readResult(response);
      phoneStep.hidden = true;
      otpStep.hidden = false;
      otp.value = '';
      setMessage(result.message);
      startCooldown();
      otp.focus();
    } catch (error) {
      setMessage(error.message, true);
      if (error.registrationUrl) {
        registerLink.href = apiPath(error.registrationUrl);
        registerLink.hidden = false;
      }
      if (error.retryAfter) startCooldown(error.retryAfter);
    } finally {
      sendButton.disabled = false;
      if (!cooldown) resendButton.disabled = true;
    }
  }

  sendButton.addEventListener('click', sendOtp);
  resendButton.addEventListener('click', sendOtp);
  phone.addEventListener('keydown', event => { if (event.key === 'Enter') { event.preventDefault(); sendOtp(); } });
  otp.addEventListener('input', () => { otp.value = otp.value.replace(/\D/g, '').slice(0, 6); });

  verifyButton.addEventListener('click', async () => {
    if (!/^\d{6}$/.test(otp.value.trim())) {
      setMessage('Enter the complete 6-digit code.', true);
      otp.focus();
      return;
    }
    verifyButton.disabled = true;
    setMessage('Verifying your code…');
    try {
      const response = await fetch(apiPath(`/business-login/${selectedRole}/verify-otp`), {
        method: 'POST', headers: {'Content-Type': 'application/json', Accept: 'application/json'},
        body: JSON.stringify({phone: phone.value.trim(), otp: otp.value.trim()})
      });
      const result = await readResult(response);
      window.location.assign(apiPath(result.redirectUrl));
    } catch (error) {
      setMessage(error.message, true);
      if (error.retryAfter) startCooldown(error.retryAfter);
    } finally {
      verifyButton.disabled = false;
    }
  });
})();
