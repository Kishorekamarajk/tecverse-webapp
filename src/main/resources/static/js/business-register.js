(() => {
  const dialog = document.querySelector('[data-role-register-dialog]');
  if (!dialog) return;

  const role = document.getElementById('businessRegisterRole');
  const contextPath = (document.body.dataset.contextPath || '').replace(/\/$/, '');
  const paths = {
    participant: '/registration',
    exhibitor: '/exhibitor-registration',
    sponsor: '/become-sponsor'
  };

  document.querySelectorAll('[data-role-register-open]').forEach(button => {
    button.addEventListener('click', () => {
      if (!dialog.open) dialog.showModal();
    });
  });

  dialog.querySelector('[data-role-register-close]').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target === dialog) dialog.close();
  });
  dialog.querySelector('[data-role-register-continue]').addEventListener('click', () => {
    const destination = paths[role.value];
    if (destination) window.location.assign(contextPath + destination);
  });
})();
