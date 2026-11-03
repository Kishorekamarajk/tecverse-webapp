document.addEventListener('click', event => {
  const editButton = event.target.closest('[data-session-edit]');
  const cancelButton = event.target.closest('[data-session-cancel]');
  const row = (editButton || cancelButton)?.closest('[data-session-row]');
  if (!row) return;

  const editableFields = row.querySelectorAll('[data-session-editable]');
  const saveButton = row.querySelector('[data-session-save]');
  const rowEditButton = row.querySelector('[data-session-edit]');
  const rowCancelButton = row.querySelector('[data-session-cancel]');

  if (editButton) {
    editableFields.forEach(field => { field.disabled = false; });
    rowEditButton.hidden = true;
    saveButton.hidden = false;
    rowCancelButton.hidden = false;
    row.querySelector('input[name="title"]')?.focus();
    return;
  }

  const updateForm = row.querySelector('form[id^="session-update-"]');
  updateForm?.reset();
  editableFields.forEach(field => { field.disabled = true; });
  rowEditButton.hidden = false;
  saveButton.hidden = true;
  rowCancelButton.hidden = true;
});
