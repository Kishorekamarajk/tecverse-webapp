(() => {
  const roleDialog = document.querySelector('[data-role-login-dialog]');
  const otpDialog = document.querySelector('[data-business-otp-dialog]');
  if (!roleDialog || !otpDialog) return;

  const roleSelect = document.getElementById('businessLoginRole');
  const rolePicker = roleDialog.querySelector('[data-login-role-picker]');
  const rolePickerTrigger = rolePicker?.querySelector('[data-login-role-trigger]');
  const rolePickerOptions = rolePicker?.querySelector('[data-login-role-options]');
  const rolePickerCurrent = rolePicker?.querySelector('[data-login-role-current]');
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
  let sendCooldown = null;
  let pendingOtpRole = null;
  let refreshPageOnBusinessLoginClose = false;

  function contextPath() {
    return (otpDialog.dataset.contextPath || document.body.dataset.contextPath || '').replace(/\/$/, '');
  }

  function apiPath(path) { return contextPath() + path; }

  function setMessage(text, isError = false) {
    message.textContent = text || '';
    message.classList.toggle('is-error', isError);
  }

  async function readResult(response) {
    const contentType = response.headers.get('Content-Type') || '';
    const data = contentType.includes('json')
      ? await response.json().catch(() => ({}))
      : {};
    if (!response.ok) {
      const unregisteredPortalUser = (selectedRole === 'exhibitor' || selectedRole === 'sponsor') && response.status === 404;
      const message = data.message || data.error || data.detail ||
        (unregisteredPortalUser
          ? `This mobile number is not registered as a ${selectedRole}. Please register to continue.`
          : 'Unable to complete sign in. Please try again.');
      const error = new Error(message);
      error.status = response.status;
      error.retryAfter = Number(response.headers.get('Retry-After')) || 0;
      error.registrationUrl = data.registrationUrl || (unregisteredPortalUser
        ? (selectedRole === 'exhibitor' ? '/exhibitor-registration' : '/become-sponsor')
        : null);
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

  function startSendCooldown(seconds) {
    window.clearInterval(sendCooldown);
    let left = Math.max(1, Math.ceil(seconds));
    sendButton.disabled = true;
    const update = () => {
      sendButton.textContent = `Wait ${left}s`;
      setMessage(`Too many requests. Please wait ${left} seconds before trying again.`, true);
    };
    update();
    sendCooldown = window.setInterval(() => {
      left -= 1;
      if (left <= 0) {
        window.clearInterval(sendCooldown);
        sendCooldown = null;
        sendButton.disabled = false;
        sendButton.textContent = 'Send OTP';
        setMessage('You can try sending the OTP again.');
      } else {
        update();
      }
    }, 1000);
  }

  function openRoleDialog() {
    if (!roleDialog.open) roleDialog.showModal();
  }

  function openBusinessOtpLogin(role) {
    selectedRole = role;
    roleSelect.value = role;
    otpDialog.querySelector('[data-business-role-label]').textContent = `${role.toUpperCase()} PORTAL LOGIN`;
    const resumeVerification = pendingOtpRole === role;
    phoneStep.hidden = resumeVerification;
    otpStep.hidden = !resumeVerification;
    if (!resumeVerification) {
      pendingOtpRole = null;
      phone.value = '';
      otp.value = '';
    }
    registerLink.hidden = true;
    setMessage(resumeVerification ? 'Continue entering the verification code sent to your mobile.' : '');
    if (!otpDialog.open) otpDialog.showModal();
    window.setTimeout(() => (resumeVerification ? otp : phone).focus(), 0);
  }

  if (rolePicker && rolePickerTrigger && rolePickerOptions && rolePickerCurrent) {
    const roleLabels = {
      participant: '<i class="bi bi-person-badge" aria-hidden="true"></i> Participant',
      exhibitor: '<i class="bi bi-shop-window" aria-hidden="true"></i> Exhibitor',
      sponsor: '<i class="bi bi-award" aria-hidden="true"></i> Sponsor'
    };
    rolePickerTrigger.addEventListener('click', () => {
      const expanded = rolePickerTrigger.getAttribute('aria-expanded') === 'true';
      rolePickerOptions.hidden = expanded;
      rolePickerTrigger.setAttribute('aria-expanded', String(!expanded));
    });
    rolePickerOptions.querySelectorAll('[data-login-role]').forEach(option => {
      option.addEventListener('click', () => {
        const value = option.dataset.loginRole;
        roleSelect.value = value;
        rolePickerCurrent.innerHTML = roleLabels[value];
        rolePickerOptions.querySelectorAll('[data-login-role]').forEach(item => {
          item.setAttribute('aria-selected', String(item === option));
        });
        rolePickerOptions.hidden = true;
        rolePickerTrigger.setAttribute('aria-expanded', 'false');
        rolePickerTrigger.focus();
      });
    });
    rolePicker.addEventListener('keydown', event => {
      if (event.key === 'Escape' && !rolePickerOptions.hidden) {
        event.preventDefault();
        rolePickerOptions.hidden = true;
        rolePickerTrigger.setAttribute('aria-expanded', 'false');
        rolePickerTrigger.focus();
      }
    });
    document.addEventListener('click', event => {
      if (!rolePicker.contains(event.target)) {
        rolePickerOptions.hidden = true;
        rolePickerTrigger.setAttribute('aria-expanded', 'false');
      }
    });
  }

  document.querySelectorAll('[data-role-login-open]').forEach(button => button.addEventListener('click', openRoleDialog));
  document.querySelectorAll('[data-business-login-role]').forEach(button => button.addEventListener('click', () => {
    const successDialog = button.closest('#sponsorSuccessDialog');
    const exhibitorSuccessModal = button.closest('#successModal');
    refreshPageOnBusinessLoginClose = Boolean(successDialog || exhibitorSuccessModal);
    if (successDialog) successDialog.dataset.openingLogin = 'true';
    button.closest('dialog')?.close();
    exhibitorSuccessModal?.classList.add('hidden');
    openBusinessOtpLogin(button.dataset.businessLoginRole);
  }));
  roleDialog.querySelector('[data-role-login-close]').addEventListener('click', () => roleDialog.close());
  otpDialog.querySelector('[data-business-otp-close]').addEventListener('click', () => otpDialog.close());
  roleDialog.addEventListener('click', event => { if (event.target === roleDialog) roleDialog.close(); });
  otpDialog.addEventListener('click', event => { if (event.target === otpDialog) otpDialog.close(); });
  otpDialog.addEventListener('close', () => {
    if (pendingOtpRole) {
      refreshPageOnBusinessLoginClose = false;
      return;
    }
    if (!refreshPageOnBusinessLoginClose) return;
    refreshPageOnBusinessLoginClose = false;
    window.location.reload();
  });

  roleDialog.querySelector('[data-role-login-continue]').addEventListener('click', () => {
    selectedRole = roleSelect.value;
    roleDialog.close();
    if (selectedRole === 'participant') {
      document.dispatchEvent(new Event('open-attendee-login'));
      return;
    }
    openBusinessOtpLogin(selectedRole);
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
      pendingOtpRole = selectedRole;
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
        registerLink.textContent = selectedRole === 'exhibitor' ? 'Register as exhibitor' : 'Register now';
        registerLink.hidden = false;
      }
      if (error.retryAfter) startSendCooldown(error.retryAfter);
    } finally {
      if (!sendCooldown) sendButton.disabled = false;
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
      pendingOtpRole = null;
      window.location.assign(apiPath(result.redirectUrl));
    } catch (error) {
      setMessage(error.message, true);
      if (error.retryAfter) startCooldown(error.retryAfter);
    } finally {
      verifyButton.disabled = false;
    }
  });
})();
