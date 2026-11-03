(() => {
  const attendeeSignedIn = document.body.dataset.attendeeSignedIn === 'true';
  const dialog = document.getElementById('sessionAccessDialog');
  if (!dialog) return;

  const contextPath = (document.body.dataset.contextPath || '').replace(/\/$/, '');
  const registeredButton = dialog.querySelector('[data-session-registered]');
  const newUserButton = dialog.querySelector('[data-session-new-user]');
  const closeButton = dialog.querySelector('[data-session-access-close]');
  const confirmDialog = document.getElementById('sessionConfirmDialog');
  const confirmDescription = confirmDialog.querySelector('#sessionConfirmDescription');
  const confirmYesButton = confirmDialog.querySelector('[data-session-confirm-yes]');
  const confirmNoButton = confirmDialog.querySelector('[data-session-confirm-no]');
  let selectedForm = null;
  let confirmedForm = null;

  document.querySelectorAll('.public-sessions__reserve-form').forEach(form => {
    form.addEventListener('submit', event => {
      if (confirmedForm === form) {
        confirmedForm = null;
        return;
      }

      event.preventDefault();
      selectedForm = form;
      if (attendeeSignedIn) {
        const title = form.closest('.public-sessions__card')?.querySelector('h3')?.textContent.trim();
        confirmDescription.textContent = `Would you like to reserve your place${title ? ` in "${title}"` : ' in this session'}?`;
        confirmDialog.showModal();
      } else {
        dialog.showModal();
      }
    });
  });

  document.querySelectorAll('.public-sessions__cancel-form').forEach(form => {
    form.addEventListener('submit', event => {
      if (confirmedForm === form) {
        confirmedForm = null;
        return;
      }

      event.preventDefault();
      selectedForm = form;
      confirmDialog.querySelector('#sessionConfirmTitle').textContent = 'Cancel your reservation?';
      confirmDescription.textContent = 'Are you sure you want to cancel this session reservation?';
      confirmYesButton.textContent = 'Yes, cancel reservation';
      confirmDialog.showModal();
    });
  });

  function continueWithSessionReservation(destination) {
    const sessionId = selectedForm?.dataset.sessionReserve;
    if (!sessionId || !/^[1-9]\d*$/.test(sessionId)) return;
    const handoff = document.createElement('form');
    handoff.method = 'post';
    handoff.action = `${contextPath}/sessions/pending`;
    const csrf = selectedForm.querySelector('input[name="_csrf"]');
    if (csrf) {
      const csrfInput = document.createElement('input');
      csrfInput.type = 'hidden';
      csrfInput.name = csrf.name;
      csrfInput.value = csrf.value;
      handoff.appendChild(csrfInput);
    }
    for (const [name, value] of [['sessionId', sessionId], ['destination', destination]]) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      handoff.appendChild(input);
    }
    document.body.appendChild(handoff);
    handoff.submit();
  }

  registeredButton.addEventListener('click', () => {
    continueWithSessionReservation('login');
  });

  newUserButton.addEventListener('click', () => {
    continueWithSessionReservation('registration');
  });

  closeButton.addEventListener('click', () => {
    selectedForm = null;
    dialog.close();
  });

  dialog.addEventListener('click', event => {
    if (event.target === dialog) {
      selectedForm = null;
      dialog.close();
    }
  });

  confirmYesButton.addEventListener('click', () => {
    if (!selectedForm) return;
    const form = selectedForm;
    selectedForm = null;
    confirmedForm = form;
    confirmDialog.close();
    confirmYesButton.textContent = 'Yes, reserve my place';
    form.requestSubmit();
  });

  confirmNoButton.addEventListener('click', () => {
    selectedForm = null;
    confirmDialog.close();
  });

  confirmDialog.addEventListener('close', () => {
    selectedForm = null;
    confirmDialog.querySelector('#sessionConfirmTitle').textContent = 'Confirm your session';
    confirmYesButton.textContent = 'Yes, reserve my place';
  });

  const pendingSessionId = document.body.dataset.pendingSessionReservation;
  if (attendeeSignedIn && pendingSessionId) {
    const pendingForm = [...document.querySelectorAll('.public-sessions__reserve-form')]
      .find(form => form.dataset.sessionReserve === pendingSessionId);
    if (pendingForm) {
      selectedForm = pendingForm;
      const title = pendingForm.closest('.public-sessions__card')?.querySelector('h3')?.textContent.trim();
      confirmDescription.textContent = `Would you like to reserve your place${title ? ` in "${title}"` : ' in this session'}?`;
      confirmDialog.showModal();
    }
  }

  const errorDialog = document.getElementById('sessionErrorDialog');
  if (errorDialog) {
    errorDialog.showModal();
    errorDialog.querySelectorAll('[data-session-error-close]').forEach(button => {
      button.addEventListener('click', () => errorDialog.close());
    });
    errorDialog.addEventListener('click', event => {
      if (event.target === errorDialog) errorDialog.close();
    });
  }
})();
