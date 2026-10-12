(() => {
  const $ = window.jQuery;
  if (!$ || !$.validator) return;

  const markupPattern = /<\/?[a-z][\s\S]*?>|<\s*script\b|javascript\s*:/i;
  $.validator.addMethod('safeText', function (value, element) {
    return this.optional(element) || !markupPattern.test(value);
  }, 'HTML tags and scripts are not allowed.');
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
  $(function () {
    $(selector).each(function () {
      const form = this;
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
    });
  });
})();
