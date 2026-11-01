(() => {
  const dialog = document.querySelector('[data-role-register-dialog]');
  if (!dialog) return;

  const role = dialog.querySelector('#businessRegisterRole');
  const continueButton = dialog.querySelector('[data-role-register-continue]');

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
    const contextPath = (document.body.dataset.contextPath || '').replace(/\/$/, '');
    window.location.assign(contextPath + registrationPaths[role.value]);
  });
})();
