// Strips characters a field must not contain as the user types or pastes. The server applies
// the same rules, so this only improves the experience; it is not the security control.
(() => {
  const PERSON = /[^A-Za-z .'-]/g;
  const TITLE = /[^\p{L}\p{M} &.,'’()/-]/gu;
  const PLACE = /[^\p{L}\p{M} .,'’()/-]/gu;
  const ORG = /[^\p{L}\p{M}\p{N} &.,'’()/#+-]/gu;
  const MOBILE = /[^0-9+]/g;
  const DIGITS = /\D/g;
  const NO_SPACE = /\s/g;
  const ADDRESS = /[^\p{L}\p{M}\p{N}\s,./#()&'’:-]/gu;
  const TEXT = /[<>{}[\]\\`^|~$=*"]/g;
  const MEASURE = /[^\p{L}\p{N} ×.,()/-]/gu;

  const FILTERS = {
    exhibitorForm: {
      companyName: ORG, industry: TITLE, fullName: PERSON, designation: TITLE,
      phone: MOBILE, whatsappNumber: MOBILE, alternateMobileNumber: MOBILE, alternateContactPerson: PERSON,
      website: NO_SPACE, linkedin: NO_SPACE, gst: /[^A-Za-z0-9]/g, companyRegistrationNumber: /[^A-Za-z0-9/-]/g,
      companyAddress: ADDRESS, city: PLACE, state: PLACE, country: PLACE,
      productServiceCategory: ORG, productTechnologyName: ORG, productCategory: ORG,
      companyDescription: TEXT, productDescription: TEXT, specialRequirements: TEXT, machineryEquipment: TEXT,
      utilityRequirements: TEXT, equipmentImpact: TEXT, equipmentDimensions: MEASURE, equipmentWeight: MEASURE,
      '#otp': DIGITS
    },
    sponsorForm: {
      company: ORG, name: PERSON, jobTitle: TITLE, phone: MOBILE, city: PLACE,
      website: NO_SPACE, industry: TITLE, message: TEXT, '#sponsorOtp': DIGITS
    }
  };
  const UPPERCASE = new Set(['gst', 'companyRegistrationNumber']);

  function filterFor(el) {
    const rules = el.form && FILTERS[el.form.id];
    if (!rules) return null;
    return (el.id && rules['#' + el.id]) || (el.name && rules[el.name]) || null;
  }

  function clean(el) {
    const block = filterFor(el);
    if (!block) return;
    let value = el.value.replace(block, '');
    if (el.tagName !== 'TEXTAREA') value = value.replace(/^\s+/, '').replace(/ {2,}/g, ' ');
    if (MOBILE === block) value = value.replace(/(?!^)\+/g, '');
    if (UPPERCASE.has(el.name)) value = value.toUpperCase();
    if (value === el.value) return;
    const caret = Math.max(0, (el.selectionStart ?? value.length) - (el.value.length - value.length));
    el.value = value;
    try { el.setSelectionRange(caret, caret); } catch (_error) { /* not a text input */ }
  }

  // Capture phase so values are cleaned before any field validation listeners run.
  document.addEventListener('input', (e) => { if (!e.isComposing) clean(e.target); }, true);
  document.addEventListener('compositionend', (e) => clean(e.target), true);
})();

(() => {
  const $ = window.jQuery;
  if (!$ || !$.validator) return;

  const markupPattern = /<\/?[a-z][\s\S]*?>|<\s*script\b|javascript\s*:/i;
  $.validator.addMethod('safeText', function (value, element) {
    return this.optional(element) || !markupPattern.test(value);
  }, 'HTML tags and scripts are not allowed.');
  $.validator.addMethod('containsLetter', function (value, element) {
    return this.optional(element) || /\p{L}/u.test(value);
  }, 'This name must contain letters, not only numbers or symbols.');
  $.validator.addMethod('indianMobile', function (value, element) {
    return this.optional(element) || /^(?:\+91[-\s]?)?[6-9]\d{9}$/.test(value.trim());
  }, 'Enter a valid 10-digit Indian mobile number.');
  $.validator.addMethod('gstin', function (value, element) {
    return this.optional(element) || /^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/i.test(value.trim());
  }, 'Enter a valid 15-character GSTIN.');
  $.validator.addMethod('linkedinUrl', function (value, element) {
    return this.optional(element) || /^https?:\/\/([a-z]{2,3}\.)?linkedin\.com\/.+/i.test(value.trim());
  }, 'Enter a valid LinkedIn URL.');
  $.validator.addMethod('pdfUnderOneMb', function (_value, element) {
    const file = element.files && element.files[0];
    return !file || (/\.pdf$/i.test(file.name) && file.size <= 1024 * 1024);
  }, 'Choose a PDF file no larger than 1 MB.');

  function fieldRules(element) {
    const rules = {};
    const $field = $(element);
    if (element.required || $field.attr('aria-required') === 'true') rules.required = true;
    if (element.type === 'email') rules.email = true;
    if (element.type === 'url') rules.url = true;
    if (element.minLength > 0) rules.minlength = element.minLength;
    if (element.maxLength > 0) rules.maxlength = element.maxLength;
    if (element.type === 'number' && element.min !== '') rules.min = Number(element.min);
    if (element.type === 'number' && element.max !== '') rules.max = Number(element.max);
    if (element.pattern) rules.matchesPattern = element.pattern;
    if (element.id === 'confirmPassword') rules.equalTo = '#password';

    if (['text', 'email', 'url', 'search', 'tel', 'textarea'].includes(element.type) || element.tagName === 'TEXTAREA') {
      rules.safeText = true;
    }
    if (['phone', 'mobile', 'whatsappNumber', 'alternateMobileNumber'].includes(element.name)) rules.indianMobile = true;
    if (['company', 'companyName', 'organizationName', 'collegeName', 'universityName',
      'productServiceCategory', 'productTechnologyName', 'productCategory'].includes(element.name)) rules.containsLetter = true;
    if (element.name === 'gst') rules.gstin = true;
    if (element.name === 'linkedin') rules.linkedinUrl = true;
    if ((element.id === 'logoFile' || element.id === 'documents') && element.type === 'file') rules.pdfUnderOneMb = true;
    if (element.name === 'attendanceDays' && element.type === 'checkbox') rules.required = true;
    return rules;
  }

  $.validator.addMethod('matchesPattern', function (value, element, pattern) {
    if (this.optional(element)) return true;
    try { return new RegExp(`^(?:${pattern})$`).test(value); } catch (_error) { return true; }
  }, 'Please match the requested format.');

  const selector = 'form[data-jquery-validate], form[data-admin-validation], #sponsorForm, #exhibitorForm, #detailsForm, form[data-inquiry-form], #adminLoginForm';
  function initForm(form) {
      if (!form) return;
      if (form.matches('.compact-contact-form')) return;
      if ($(form).data('validator')) return;
      const rules = {};
      $(form).find('input, select, textarea').each(function () {
        if (!this.name) return;
        const field = fieldRules(this);
        if (Object.keys(field).length) rules[this.name] = { ...(rules[this.name] || {}), ...field };
      });
      $(form).validate({
        rules,
        ignore: ':hidden:not(#logoFile):not(#documents):not(#exhibitorForm *)',
        errorElement: 'small',
        errorClass: 'jquery-validation-error',
        errorPlacement(error, element) {
          error.css({ display: 'block', color: '#b42318', fontSize: '0.82rem', marginTop: '0.25rem' });
          const container = element.closest('.form-check, .input-group');
          error.insertAfter(container.length ? container : element);
        },
        highlight(element) {
          $(element).attr('aria-invalid', 'true').addClass('is-invalid');
        },
        unhighlight(element) {
          $(element).removeAttr('aria-invalid').removeClass('is-invalid');
        }
      });
      const validator = $(form).data('validator');
      const observeDynamicFields = () => $(form).find('input, select, textarea').each(function () {
        if (!this.name || this.dataset.jqueryRulesApplied) return;
        const field = fieldRules(this);
        if (Object.keys(field).length) $(this).rules('add', field);
        this.dataset.jqueryRulesApplied = 'true';
      });
      observeDynamicFields();
      new MutationObserver(observeDynamicFields).observe(form, { childList: true, subtree: true });
  }

  // Forms inserted after page load (e.g. the server-released ticket details step) call this.
  window.TecverseValidation = { init: initForm };
  $(function () {
    $(selector).each(function () { initForm(this); });
  });
})();
