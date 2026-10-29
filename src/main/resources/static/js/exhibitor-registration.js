(() => {
  const form = document.getElementById('exhibitorForm');
  if (!form) return;

  const contextPath = ((document.body && document.body.dataset.contextPath) || '').replace(/\/$/, '');
  const apiPath = path => (contextPath === '/' ? '' : contextPath) + path;
  const stallSlides = [
    { name: 'Signature', size: '6 × 3 m', price: '₹5,00,000', passes: '4 technical-session passes', image: '/images/exhibitor-stall-signature-footprint.png' },
    { name: 'Standard', size: '3 × 3 m', price: '₹2,50,000', passes: '3 technical-session passes', image: '/images/exhibitor-stall-standard-footprint.png' },
    { name: 'Compact', size: '3 × 2 m', price: '₹1,25,000', passes: '2 technical-session passes', image: '/images/exhibitor-stall-compact-footprint.png' },
    { name: 'Showcase', size: '2 × 2 m', price: '₹50,000', passes: '0 technical-session passes', image: '/images/exhibitor-stall-showcase-footprint.png' }
  ];
  const adImage = document.getElementById('simpleAdImage');
  const adName = document.getElementById('simpleAdName');
  const adSize = document.getElementById('simpleAdSize');
  const adPrice = document.getElementById('simpleAdPrice');
  const adPasses = document.getElementById('simpleAdPasses');
  const adDots = [...document.querySelectorAll('.simple-ad-dots [data-ad-slide]')];
  let activeAdSlide = 0;
  let adTimer;

  function showStallSlide(index) {
    if (!adImage || !adName || !adSize || !adPrice || !adPasses) return;
    activeAdSlide = (index + stallSlides.length) % stallSlides.length;
    const slide = stallSlides[activeAdSlide];
    adImage.style.opacity = '0';
    window.setTimeout(() => {
      adImage.src = apiPath(slide.image);
      adImage.alt = slide.name + ' exhibitor stall, ' + slide.size;
      adImage.style.opacity = '1';
    }, 120);
    adName.textContent = slide.name;
    adSize.textContent = slide.size;
    adPrice.textContent = slide.price;
    adPasses.textContent = slide.passes;
    adDots.forEach((dot, dotIndex) => {
      const active = dotIndex === activeAdSlide;
      dot.classList.toggle('active', active);
      dot.setAttribute('aria-pressed', String(active));
    });
  }

  function restartAdRotation() {
    window.clearInterval(adTimer);
    if (adDots.length) adTimer = window.setInterval(() => showStallSlide(activeAdSlide + 1), 4500);
  }

  adDots.forEach((dot, index) => dot.addEventListener('click', () => {
    showStallSlide(index);
    restartAdRotation();
  }));
  showStallSlide(0);
  restartAdRotation();
  const pages = [...form.querySelectorAll('.simple-form-page')];
  const progressTrack = form.querySelector('.simple-progress-track');
  const progressFill = document.getElementById('simpleProgressFill');
  const progressDots = [...form.querySelectorAll('.simple-progress-dot')];
  const formStatus = document.getElementById('formStatus');
  const emailRegistrationStatus = document.getElementById('emailRegistrationStatus');
  const mobileRegistrationStatus = document.getElementById('mobileRegistrationStatus');
  const email = form.elements.email;
  const fullName = form.elements.fullName;
  const phone = form.elements.phone;
  const phoneOtp = document.getElementById('phoneOtp');
  const phoneOtpWrap = document.getElementById('phoneOtpWrap');
  const phoneOtpStatus = document.getElementById('phoneOtpStatus');
  const otp = document.getElementById('otp');
  const otpWrap = document.getElementById('otpWrap');
  const otpStatus = document.getElementById('otpStatus');
  const sendButton = document.getElementById('sendOtp');
  const sendMobileButton = document.getElementById('sendMobileOtp');
  const resendEmailButton = document.getElementById('resendEmailOtp');
  const resendMobileButton = document.getElementById('resendMobileOtp');
  const verifyButton = document.getElementById('verifyOtp');
  const verifyPhoneButton = document.getElementById('verifyPhoneOtp');
  const submitButton = document.getElementById('submitExhibitor');
  let currentPage = 1;
  let verifiedEmail = '';
  let verifiedPhone = '';
  let savedDraft = {};
  let submitting = false;
  const otpCooldownTimers = new WeakMap();
  const phoneOtpDigits = [...document.querySelectorAll('#phoneOtpInputs input')];
  const emailOtpDigits = [...document.querySelectorAll('#emailOtpInputs input')];
  const citySelect = document.getElementById('exhibitorCity');
  const cityOther = document.getElementById('exhibitorCityOther');

  const exhibitorStates = [
    'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat','Haryana',
    'Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur',
    'Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana',
    'Tripura','Uttar Pradesh','Uttarakhand','West Bengal','Andaman and Nicobar Islands','Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu','Delhi','Jammu and Kashmir','Ladakh','Lakshadweep','Puducherry'
  ];
  const exhibitorCities = [
    'Agartala','Agra','Ahmedabad','Aizawl','Ajmer','Aligarh','Alappuzha','Amaravati','Amritsar','Anand','Anantapur','Asansol','Ayodhya',
    'Bareilly','Bathinda','Begusarai','Belagavi','Bengaluru','Berhampur','Bharatpur','Bhagalpur','Bhavnagar','Bhilai','Bhopal','Bhubaneswar','Bikaner','Bilaspur','Bokaro',
    'Chandigarh','Chennai','Chhatrapati Sambhajinagar','Coimbatore','Cuttack','Daman','Darjeeling','Davangere','Dehradun','Delhi','Dewas','Dhanbad','Dharamshala','Dibrugarh','Dindigul','Durg','Durgapur',
    'Erode','Faridabad','Gandhinagar','Gangtok','Gaya','Ghaziabad','Gorakhpur','Guntur','Gurugram','Guwahati','Gwalior','Haldwani','Haridwar','Hisar','Hosur','Howrah','Hubballi-Dharwad','Hyderabad',
    'Imphal','Indore','Itanagar','Jabalpur','Jaipur','Jaisalmer','Jalandhar','Jalgaon','Jammu','Jamnagar','Jamshedpur','Jhansi','Jodhpur','Jorhat','Kadapa','Kakinada','Kalaburagi','Kannur','Kanpur',
    'Kanchipuram','Karimnagar','Karnal','Kasaragod','Kharagpur','Kochi','Kohima','Kolhapur','Kolkata','Kollam','Kota','Kottayam','Kozhikode','Kurnool','Leh','Lucknow','Ludhiana','Madurai','Malappuram',
    'Mangaluru','Manali','Margao','Mathura','Meerut','Mirzapur','Mohali','Moradabad','Mumbai','Muzaffarpur','Mysuru','Nagercoil','Nagpur','Nanded','Nashik','Navi Mumbai','Nellore','Nizamabad','Noida',
    'Panaji','Panipat','Pathankot','Patiala','Patna','Puducherry','Pune','Puri','Prayagraj','Raipur','Rajahmundry','Rajkot','Ranchi','Rishikesh','Rohtak','Roorkee','Rourkela','Salem','Sambalpur','Sangli',
    'Satna','Shillong','Shimla','Shivamogga','Siliguri','Silchar','Sikar','Solapur','Srinagar','Surat','Thanjavur','Thane','Thiruvananthapuram','Thoothukudi','Thrissur','Tiruchirappalli','Tirunelveli','Tiruppur',
    'Tirupati','Udaipur','Ujjain','Vadodara','Varanasi','Vasco da Gama','Vellore','Vijayawada','Visakhapatnam','Warangal'
  ].sort((a, b) => a.localeCompare(b));

  function populateLocationSelect(select, options, prompt, includeOther = false) {
    options.forEach(value => select.add(new Option(value, value)));
    if (includeOther) select.add(new Option('Other', '__OTHER__'));
    const picker = document.querySelector(`[data-location-picker="${select.id}"]`);
    const menu = picker.querySelector('.location-picker-menu');
    const search = picker.querySelector('.location-picker-search');
    const optionList = picker.querySelector('.location-picker-options');
    const emptyState = picker.querySelector('.location-picker-empty');
    const label = picker.querySelector('.location-picker-value');
    options.concat(includeOther ? ['Other'] : []).forEach(value => {
      const option = document.createElement('button');
      option.type = 'button';
      option.className = 'location-picker-option';
      option.setAttribute('role', 'option');
      option.setAttribute('aria-selected', 'false');
      option.dataset.value = value === 'Other' ? '__OTHER__' : value;
      option.textContent = value;
      optionList.appendChild(option);
      option.addEventListener('click', () => {
        select.value = option.dataset.value;
        trigger.setAttribute('aria-invalid', 'false');
        label.textContent = value;
        label.classList.remove('location-placeholder');
        menu.querySelectorAll('[role="option"]').forEach(item => item.setAttribute('aria-selected', String(item === option)));
        search.value = '';
        filterLocationOptions(optionList, emptyState, '');
        closeLocationPicker(picker);
        select.dispatchEvent(new Event('change', { bubbles: true }));
      });
    });
    const trigger = picker.querySelector('.location-picker-trigger');
    trigger.addEventListener('click', () => {
      if (menu.hidden) openLocationPicker(picker);
      else closeLocationPicker(picker);
    });
    trigger.addEventListener('keydown', event => {
      if (event.key === 'ArrowDown' || event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        openLocationPicker(picker);
        search.focus();
      }
    });
    search.addEventListener('input', () => filterLocationOptions(optionList, emptyState, search.value));
    menu.addEventListener('keydown', event => {
      const optionsInMenu = [...menu.querySelectorAll('[role="option"]')].filter(option => !option.hidden);
      const current = optionsInMenu.indexOf(document.activeElement);
      if (event.key === 'Escape') { event.preventDefault(); closeLocationPicker(picker); trigger.focus(); }
      if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();
        const delta = event.key === 'ArrowDown' ? 1 : -1;
        optionsInMenu[(current + delta + optionsInMenu.length) % optionsInMenu.length]?.focus();
      }
      if (event.key === 'Home') { event.preventDefault(); optionsInMenu[0]?.focus(); }
      if (event.key === 'End') { event.preventDefault(); optionsInMenu.at(-1)?.focus(); }
    });
  }

  function filterLocationOptions(optionList, emptyState, query) {
    const prefix = query.trim().toLocaleLowerCase();
    let visibleCount = 0;
    optionList.querySelectorAll('[role="option"]').forEach(option => {
      const matches = !prefix || option.textContent.trim().toLocaleLowerCase().startsWith(prefix);
      option.hidden = !matches;
      if (matches) visibleCount += 1;
    });
    emptyState.hidden = visibleCount > 0;
  }

  function openLocationPicker(picker) {
    const menu = picker.querySelector('.location-picker-menu');
    menu.hidden = false;
    picker.querySelector('.location-picker-trigger').setAttribute('aria-expanded', 'true');
    const search = picker.querySelector('.location-picker-search');
    search.setAttribute('aria-expanded', 'true');
    search.value = '';
    filterLocationOptions(picker.querySelector('.location-picker-options'), picker.querySelector('.location-picker-empty'), '');
    search.focus();
  }

  function closeLocationPicker(picker) {
    picker.querySelector('.location-picker-menu').hidden = true;
    picker.querySelector('.location-picker-trigger').setAttribute('aria-expanded', 'false');
    picker.querySelector('.location-picker-search').setAttribute('aria-expanded', 'false');
  }

  document.addEventListener('click', event => {
    document.querySelectorAll('.location-picker').forEach(picker => {
      if (!picker.contains(event.target)) closeLocationPicker(picker);
    });
  });

  populateLocationSelect(citySelect, exhibitorCities, 'Select a city', true);
  populateLocationSelect(document.getElementById('exhibitorState'), exhibitorStates, 'Select a state or union territory');
  citySelect.addEventListener('change', () => {
    const isOther = citySelect.value === '__OTHER__';
    cityOther.disabled = !isOther;
    cityOther.required = isOther;
    cityOther.classList.toggle('hidden', !isOther);
    if (!isOther) cityOther.value = '';
    else cityOther.focus();
  });

  const normalizedPhone = value => value.trim().replace(/^\+91[-\s]?/, '').replace(/\D/g, '');

  function wireOtpDigits(inputs, valueField) {
    const sync = () => { valueField.value = inputs.map(input => input.value).join(''); };
    inputs.forEach((input, index) => {
      input.addEventListener('input', () => {
        const digits = input.value.replace(/\D/g, '').slice(0, inputs.length - index);
        if (digits.length > 1) {
          [...digits].forEach((digit, offset) => { inputs[index + offset].value = digit; });
        } else {
          input.value = digits;
        }
        sync();
        if (digits && inputs[Math.min(index + digits.length, inputs.length - 1)]) {
          inputs[Math.min(index + digits.length, inputs.length - 1)].focus();
        }
      });
      input.addEventListener('keydown', event => {
        if (event.key === 'Backspace' && !input.value && inputs[index - 1]) inputs[index - 1].focus();
        if (event.key === 'ArrowLeft' && inputs[index - 1]) inputs[index - 1].focus();
        if (event.key === 'ArrowRight' && inputs[index + 1]) inputs[index + 1].focus();
      });
      input.addEventListener('paste', event => {
        const pasted = event.clipboardData?.getData('text')?.replace(/\D/g, '').slice(0, inputs.length);
        if (!pasted) return;
        event.preventDefault();
        inputs.forEach((digitInput, digitIndex) => { digitInput.value = pasted[digitIndex] || ''; });
        sync();
        inputs[Math.min(pasted.length, inputs.length) - 1]?.focus();
      });
    });
  }

  function clearOtpDigits(inputs, valueField) {
    inputs.forEach(input => { input.value = ''; });
    valueField.value = '';
  }

  wireOtpDigits(phoneOtpDigits, phoneOtp);
  wireOtpDigits(emailOtpDigits, otp);

  function startOtpCooldown(button, seconds = 60) {
    const existingTimer = otpCooldownTimers.get(button);
    if (existingTimer) window.clearInterval(existingTimer);
    let remaining = Math.max(1, Math.ceil(seconds));
    button.disabled = true;
    button.textContent = 'Resend in ' + remaining + 's';
    const timer = window.setInterval(() => {
      remaining -= 1;
      if (remaining <= 0) {
        window.clearInterval(timer);
        otpCooldownTimers.delete(button);
        button.disabled = false;
        button.textContent = 'Resend OTP';
        return;
      }
      button.textContent = 'Resend in ' + remaining + 's';
    }, 1000);
    otpCooldownTimers.set(button, timer);
  }

  function clearOtpCooldown(button) {
    const timer = otpCooldownTimers.get(button);
    if (timer) window.clearInterval(timer);
    otpCooldownTimers.delete(button);
  }

  function setOtpLoading(button, loading) {
    if (loading) {
      if (!button.dataset.defaultLabel) button.dataset.defaultLabel = button.textContent.trim();
      button.disabled = true;
      button.setAttribute('aria-busy', 'true');
      button.innerHTML = '<span class="simple-loading-spinner" aria-hidden="true"></span><span class="visually-hidden">Please wait</span>';
      return;
    }
    button.removeAttribute('aria-busy');
    if (!otpCooldownTimers.has(button)) {
      button.disabled = false;
      button.textContent = button.dataset.defaultLabel || 'Send OTP';
    }
  }

  function throwIfOtpRequestFailed(response, result, fallback) {
    if (response.ok && result.success) return;
    const error = Error(result.message || fallback);
    const retryAfter = Number(response.headers.get('Retry-After'));
    if (Number.isFinite(retryAfter) && retryAfter > 0) error.retryAfter = retryAfter;
    throw error;
  }

  function showPage(number) {
    currentPage = number;
    pages.forEach((page, index) => {
      const isHidden = index + 1 !== number;
      page.hidden = isHidden;
      page.classList.toggle('hidden', isHidden);
    });
    const progress = pages.length > 1 ? (number - 1) / (pages.length - 1) : 1;
    progressFill.style.width = 'calc((100% - 14px) * ' + progress + ')';
    progressDots.forEach((dot, index) => {
      dot.classList.toggle('active', index + 1 === number);
      dot.classList.toggle('complete', index + 1 < number);
      if (index + 1 === number) dot.setAttribute('aria-current', 'step');
      else dot.removeAttribute('aria-current');
    });
    pages[number - 1]?.querySelector('input, select')?.focus({ preventScroll: true });
  }

  function showError(input, message) {
    input.setAttribute('aria-invalid', 'true');
    input.closest('.simple-control')?.setAttribute('aria-invalid', 'true');
    if (input.name === 'phone') {
      document.getElementById('phone-error')?.remove();
      const phoneError = document.getElementById('phoneFieldError');
      if (phoneError) {
        phoneError.textContent = message;
        phoneError.hidden = false;
      }
      return;
    }
    const label = input.closest('label');
    let error = label && label.querySelector('.field-error');
    if (!error && label) {
      error = document.createElement('small');
      error.className = 'field-error';
      error.setAttribute('role', 'alert');
      label.appendChild(error);
    }
    if (error) error.textContent = message;
  }

  function clearError(input) {
    input.removeAttribute('aria-invalid');
    input.closest('.simple-control')?.removeAttribute('aria-invalid');
    if (input.name === 'phone') {
      const phoneError = document.getElementById('phoneFieldError');
      if (phoneError) { phoneError.textContent = ''; phoneError.hidden = true; }
      return;
    }
    const error = input.closest('label')?.querySelector('.field-error');
    if (error) error.remove();
  }

  function validatePage(page) {
    let firstInvalid = null;
    page.querySelectorAll('input, select').forEach(input => {
      if (input.id === 'exhibitorCity' || input.id === 'exhibitorState') return;
      if (input.id === 'otp') return;
      clearError(input);
      if (!input.checkValidity() && !firstInvalid) firstInvalid = input;
    });
    if (firstInvalid) {
      firstInvalid.reportValidity();
      firstInvalid.focus();
      return false;
    }
    if (page.dataset.page === '2') {
      const missingPicker = !citySelect.value || (citySelect.value === '__OTHER__' && !cityOther.value.trim())
        ? citySelect
        : !document.getElementById('exhibitorState').value ? document.getElementById('exhibitorState') : null;
      if (missingPicker) {
        const trigger = document.querySelector(`[data-location-picker="${missingPicker.id}"] .location-picker-trigger`);
        trigger.setAttribute('aria-invalid', 'true');
        trigger.focus();
        return false;
      }
    }
    if (page.dataset.page === '1') {
      if (!/^[A-Za-z][A-Za-z .'-]{1,149}$/.test(fullName.value.trim())) {
        showError(fullName, 'Enter a valid contact name.');
        fullName.focus();
        return false;
      }
      if (!/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(phone.value.trim())) {
        showError(phone, 'Enter a valid 10-digit Indian mobile number.');
        phone.focus();
        return false;
      }
    }
    return true;
  }

  form.querySelectorAll('input, select').forEach(input => {
    input.addEventListener('input', () => {
      clearError(input);
      formStatus.textContent = '';
      if (input === email) emailRegistrationStatus.textContent = '';
      if (input === phone) mobileRegistrationStatus.textContent = '';
      if (input === email && email.value.trim() !== verifiedEmail) {
        verifiedEmail = '';
        clearOtpCooldown(sendButton);
        sendButton.disabled = false;
        sendButton.textContent = 'Send OTP';
        sendButton.classList.remove('is-verified');
        sendButton.removeAttribute('aria-label');
        otpWrap.classList.add('hidden');
        otpStatus.textContent = '';
      }
      if (input === phone && normalizedPhone(phone.value) !== verifiedPhone) {
        verifiedPhone = '';
        clearOtpCooldown(sendMobileButton);
        sendMobileButton.disabled = false;
        sendMobileButton.textContent = 'Send OTP';
        sendMobileButton.classList.remove('is-verified');
        sendMobileButton.removeAttribute('aria-label');
        phoneOtpWrap.classList.add('hidden');
        phoneOtpStatus.textContent = '';
      }
    });
    input.addEventListener('change', () => clearError(input));
    if (input === phone) {
      input.addEventListener('blur', () => {
        const value = phone.value.trim();
        if (value && !/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(value)) {
          showError(phone, 'Enter a valid 10-digit Indian mobile number.');
        }
      });
    }
  });

  sendButton.addEventListener('click', async () => {
    if (!email.checkValidity()) {
      email.reportValidity();
      return;
    }
    if (!/^[A-Za-z][A-Za-z .'-]{1,149}$/.test(fullName.value.trim())) {
      showError(fullName, 'Enter the contact name before verifying email.');
      fullName.focus();
      return;
    }
    setOtpLoading(sendButton, true);
    otpStatus.textContent = '';
    emailRegistrationStatus.textContent = 'Sending OTP… Please wait.';
    emailRegistrationStatus.style.color = '#52677d';
    try {
      const response = await fetch(apiPath('/exhibitor/send-otp'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.value.trim(), name: fullName.value.trim(), phone: phone.value.trim() })
      });
      const result = await response.json().catch(() => ({}));
      throwIfOtpRequestFailed(response, result, 'Unable to send OTP.');
      verifiedEmail = '';
      emailRegistrationStatus.textContent = '';
      clearOtpDigits(emailOtpDigits, otp);
      document.getElementById('otpEmailDestination').textContent = email.value.trim();
      otpWrap.classList.remove('hidden');
      otpStatus.textContent = result.message || 'OTP sent to your official email.';
      emailOtpDigits[0]?.focus();
      startOtpCooldown(sendButton);
      startOtpCooldown(resendEmailButton);
    } catch (error) {
      const message = error.message || 'Unable to send OTP.';
      const phoneDuplicate = /already registered/i.test(message) && /mobile|phone/i.test(message);
      const status = phoneDuplicate ? mobileRegistrationStatus : emailRegistrationStatus;
      status.textContent = message;
      status.style.color = '#b42318';
      if (error.retryAfter) { startOtpCooldown(sendButton, error.retryAfter); startOtpCooldown(resendEmailButton, error.retryAfter); }
      else if (/temporarily down|unable to send/i.test(message) && !phoneDuplicate) { startOtpCooldown(sendButton); startOtpCooldown(resendEmailButton); }
    } finally {
      setOtpLoading(sendButton, false);
    }
  });

  sendMobileButton.addEventListener('click', async () => {
    if (!/^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(phone.value.trim())) {
      showError(phone, 'Enter a valid 10-digit Indian mobile number.');
      phone.focus();
      return;
    }
    setOtpLoading(sendMobileButton, true);
    phoneOtpStatus.textContent = '';
    mobileRegistrationStatus.textContent = 'Sending OTP… Please wait.';
    mobileRegistrationStatus.style.color = '#52677d';
    try {
      const response = await fetch(apiPath('/exhibitor/send-mobile-otp'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: phone.value.trim() })
      });
      const result = await response.json().catch(() => ({}));
      throwIfOtpRequestFailed(response, result, 'Unable to send mobile OTP.');
      verifiedPhone = '';
      mobileRegistrationStatus.textContent = '';
      clearOtpDigits(phoneOtpDigits, phoneOtp);
      document.getElementById('otpMobileDestination').textContent = phone.value.trim();
      phoneOtpWrap.classList.remove('hidden');
      phoneOtpStatus.textContent = result.message || 'OTP sent to your mobile number.';
      phoneOtpStatus.style.color = '#52677d';
      phoneOtpDigits[0]?.focus();
      startOtpCooldown(sendMobileButton);
      startOtpCooldown(resendMobileButton);
    } catch (error) {
      mobileRegistrationStatus.textContent = error.message || 'Unable to send mobile OTP.';
      mobileRegistrationStatus.style.color = '#b42318';
      if (error.retryAfter) { startOtpCooldown(sendMobileButton, error.retryAfter); startOtpCooldown(resendMobileButton, error.retryAfter); }
      else if (/sms gateway|temporarily unavailable|temporarily down/i.test(error.message || '')) { startOtpCooldown(sendMobileButton); startOtpCooldown(resendMobileButton); }
    } finally {
      setOtpLoading(sendMobileButton, false);
    }
  });

  resendEmailButton.addEventListener('click', () => sendButton.click());
  resendMobileButton.addEventListener('click', () => sendMobileButton.click());

  verifyPhoneButton.addEventListener('click', async () => {
    if (!/^\d{6}$/.test(phoneOtp.value.trim())) {
      phoneOtpStatus.textContent = 'Enter the 6-digit mobile OTP.';
      phoneOtpDigits[0]?.focus();
      return;
    }
    verifyPhoneButton.disabled = true;
    try {
      const response = await fetch(apiPath('/exhibitor/verify-mobile-otp'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: phone.value.trim(), otp: phoneOtp.value.trim() })
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok || !result.success) throw Error(result.message || 'Mobile OTP verification failed.');
      verifiedPhone = normalizedPhone(phone.value);
      phoneOtpWrap.classList.add('hidden');
      clearOtpCooldown(sendMobileButton);
      sendMobileButton.disabled = true;
      sendMobileButton.textContent = 'Verified';
      sendMobileButton.classList.add('is-verified');
      sendMobileButton.setAttribute('aria-label', 'Mobile number verified');
      mobileRegistrationStatus.textContent = 'Mobile number verified.';
      mobileRegistrationStatus.style.color = '#16834f';
    } catch (error) {
      phoneOtpStatus.textContent = error.message || 'Mobile OTP verification failed.';
      phoneOtpStatus.style.color = '#b42318';
    } finally {
      verifyPhoneButton.disabled = false;
    }
  });

  verifyButton.addEventListener('click', async () => {
    if (!/^\d{6}$/.test(otp.value.trim())) {
      otpStatus.textContent = 'Enter the 6-digit OTP.';
      emailOtpDigits[0]?.focus();
      return;
    }
    verifyButton.disabled = true;
    try {
      const response = await fetch(apiPath('/exhibitor/verify-otp'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.value.trim(), otp: otp.value.trim() })
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok || !result.success) throw Error(result.message || 'OTP verification failed.');
      verifiedEmail = email.value.trim();
      otpWrap.classList.add('hidden');
      clearOtpCooldown(sendButton);
      sendButton.disabled = true;
      sendButton.textContent = 'Verified';
      sendButton.classList.add('is-verified');
      sendButton.setAttribute('aria-label', 'Email address verified');
      emailRegistrationStatus.textContent = 'Email verified.';
      emailRegistrationStatus.style.color = '#16834f';
    } catch (error) {
      otpStatus.textContent = error.message || 'OTP verification failed.';
      otpStatus.style.color = '#b42318';
    } finally {
      verifyButton.disabled = false;
    }
  });

  form.querySelectorAll('[data-next]').forEach(button => {
    button.addEventListener('click', () => {
      const page = pages[currentPage - 1];
      if (!validatePage(page)) return;
      if (currentPage === 1 && verifiedEmail !== email.value.trim()) {
        otpStatus.textContent = 'Verify your official email with OTP to continue.';
        email.focus();
        return;
      }
      if (currentPage === 1 && verifiedPhone !== normalizedPhone(phone.value)) {
        phoneOtpStatus.textContent = 'Verify your mobile number with OTP to continue.';
        phone.focus();
        return;
      }
      savedDraft = Object.fromEntries(new FormData(form).entries());
      if (currentPage < pages.length) showPage(currentPage + 1);
    });
  });

  form.querySelectorAll('[data-back]').forEach(button => {
    button.addEventListener('click', () => {
      Object.entries(savedDraft).forEach(([name, value]) => {
        const input = form.elements[name];
        if (input && !input.value) input.value = value;
      });
      showPage(Math.max(1, currentPage - 1));
    });
  });

  document.querySelectorAll('.select-package').forEach(button => {
    button.addEventListener('click', () => {
      showPage(1);
      document.getElementById('exhibitor-flow')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });

  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (submitting) return;
    const invalidPage = pages.find(page => [...page.querySelectorAll('input, select')].some(input => input.required && !input.checkValidity()));
    if (invalidPage) {
      showPage(Number(invalidPage.dataset.page));
      invalidPage.querySelector('input:invalid, select:invalid')?.reportValidity();
      return;
    }
    if (verifiedEmail !== email.value.trim()) {
      showPage(1);
      otpStatus.textContent = 'Verify your official email with OTP before submitting.';
      email.focus();
      return;
    }
    if (verifiedPhone !== normalizedPhone(phone.value)) {
      showPage(1);
      phoneOtpStatus.textContent = 'Verify your mobile number with OTP before submitting.';
      phone.focus();
      return;
    }
    if (!validatePage(pages[0])) {
      showPage(1);
      return;
    }

    submitting = true;
    submitButton.disabled = true;
    submitButton.setAttribute('aria-busy', 'true');
    submitButton.innerHTML = '<span class="submit-spinner" aria-hidden="true"></span><span class="submit-label">Saving registration...</span>';
    formStatus.textContent = '';
    try {
      const payload = Object.fromEntries(new FormData(form).entries());
      if (payload.city === '__OTHER__') {
        payload.city = (payload.cityOther || '').trim();
        delete payload.cityOther;
      }
      const response = await fetch(apiPath('/register'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(payload)
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok || !result.success) {
        const errors = result.data || {};
        Object.entries(errors).forEach(([name, message]) => {
          const input = form.elements[name];
          if (!input) return;
          showError(input, message);
          const owner = pages.find(page => page.contains(input));
          if (owner) showPage(Number(owner.dataset.page));
        });
        throw Error(result.message || 'Unable to submit the application.');
      }
      document.getElementById('referenceBox').textContent = result.data?.referenceNumber || '';
      document.getElementById('successModal').classList.remove('hidden');
      if (typeof window.celebrateRegistration === 'function') window.celebrateRegistration();
    } catch (error) {
      const message = error.message || 'Something went wrong. Please try again.';
      formStatus.textContent = message;
      formStatus.style.color = '#b42318';
      if (/already registered/i.test(message)) {
        showPage(1);
        if (/email/i.test(message)) {
          emailRegistrationStatus.textContent = message;
          emailRegistrationStatus.style.color = '#b42318';
          email.focus();
        } else if (/mobile|phone/i.test(message)) {
          mobileRegistrationStatus.textContent = message;
          mobileRegistrationStatus.style.color = '#b42318';
          phone.focus();
        }
      }
    } finally {
      submitting = false;
      submitButton.disabled = false;
      submitButton.removeAttribute('aria-busy');
      submitButton.innerHTML = '<span class="submit-label">Submit application</span><i class="bi bi-arrow-right" aria-hidden="true"></i>';
    }
  });

  document.querySelectorAll('.close-modal').forEach(button => {
    button.addEventListener('click', () => button.closest('.exv-modal')?.classList.add('hidden'));
  });

  showPage(1);
})();
