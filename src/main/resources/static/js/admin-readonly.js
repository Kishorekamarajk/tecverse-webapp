(function () {
  const sidebar = document.querySelector('.admin-sidebar[data-read-only="true"]');
  if (!sidebar) return;

  document.documentElement.classList.add('admin-view-only');

  document.querySelectorAll('.admin-main-panel a[href]').forEach((link) => {
    let path;
    try {
      path = new URL(link.href, window.location.href).pathname.toLowerCase();
    } catch (_) {
      return;
    }
    if (/\/(?:new|delete|toggle|bulk|generate)(?:\/|$)/.test(path)) link.hidden = true;
  });

  document.querySelectorAll('.admin-main-panel form[method="post"]').forEach((form) => {
    const fields = form.querySelectorAll('input, select, textarea');
    fields.forEach((field) => { field.disabled = true; });
    form.querySelectorAll('button[type="submit"], input[type="submit"]').forEach((button) => {
      button.hidden = true;
    });
    if (!fields.length && !form.classList.contains('admin-sidebar-logout')) form.hidden = true;
  });

  document.querySelectorAll('.admin-main-panel button').forEach((button) => {
    if (/\b(add|upload|save|delete|edit|generate|create)\b/i.test(button.textContent || '')) {
      button.disabled = true;
      button.hidden = true;
    }
  });
})();
