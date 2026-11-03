(() => {
  const dialog = document.querySelector('[data-role-register-dialog]');
  if (!dialog) return;

  const role = dialog.querySelector('#businessRegisterRole');
  const continueButton = dialog.querySelector('[data-role-register-continue]');
  const picker = dialog.querySelector('[data-register-role-picker]');
  const pickerTrigger = dialog.querySelector('[data-register-role-trigger]');
  const pickerOptions = dialog.querySelector('[data-register-role-options]');
  const pickerCurrent = dialog.querySelector('[data-register-role-current]');

  function closePicker(returnFocus = false) {
    if (!pickerOptions || !pickerTrigger) return;
    pickerOptions.hidden = true;
    pickerTrigger.setAttribute('aria-expanded', 'false');
    if (returnFocus) pickerTrigger.focus();
  }

  pickerTrigger?.addEventListener('click', () => {
    const opening = pickerOptions.hidden;
    pickerOptions.hidden = !opening;
    pickerTrigger.setAttribute('aria-expanded', String(opening));
    if (opening) pickerOptions.querySelector('[aria-selected="true"]')?.focus();
  });

  pickerOptions?.querySelectorAll('[data-register-role]').forEach(option => {
    option.addEventListener('click', () => {
      role.value = option.dataset.registerRole;
      pickerCurrent.textContent = option.querySelector('span').textContent;
      pickerOptions.querySelectorAll('[data-register-role]').forEach(item => {
        item.setAttribute('aria-selected', String(item === option));
      });
      closePicker(true);
    });
    option.addEventListener('keydown', event => {
      const options = [...pickerOptions.querySelectorAll('[data-register-role]')];
      const index = options.indexOf(option);
      if (event.key === 'Escape') { event.preventDefault(); closePicker(true); }
      else if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();
        options[(index + (event.key === 'ArrowDown' ? 1 : options.length - 1)) % options.length].focus();
      }
    });
  });

  picker?.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !pickerOptions.hidden) { event.preventDefault(); closePicker(true); }
  });
  document.addEventListener('click', event => {
    if (picker && !picker.contains(event.target)) closePicker();
  });

  document.querySelectorAll('[data-role-register-open]').forEach(button => {
    button.addEventListener('click', () => dialog.showModal());
  });

  dialog.querySelector('[data-role-register-close]')?.addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target === dialog) dialog.close();
  });

  continueButton?.addEventListener('click', () => {
    const registrationPaths = {
      participant: '/registration',
      exhibitor: '/exhibitor-registration',
      sponsor: '/become-sponsor'
    };
    const contextPath = (dialog.dataset.contextPath || document.body.dataset.contextPath || '').replace(/\/$/, '');
    window.location.assign(contextPath + registrationPaths[role.value]);
  });
})();
