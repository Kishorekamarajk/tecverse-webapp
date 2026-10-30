document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.business-chat').forEach(chat => {
    chat.scrollTop = chat.scrollHeight;
  });
});
