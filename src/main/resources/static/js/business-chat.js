(() => {
  function initializeBusinessChats() {
    document.querySelectorAll('.business-chat').forEach(chat => {
      chat.scrollTop = chat.scrollHeight;
      if (document.body.dataset.businessRole !== 'sponsor') return;

      chat.addEventListener('wheel', event => {
        const atTop = chat.scrollTop <= 0;
        const atBottom = chat.scrollTop + chat.clientHeight >= chat.scrollHeight - 1;
        const scrollingUpAtTop = event.deltaY < 0 && atTop;
        const scrollingDownAtBottom = event.deltaY > 0 && atBottom;

        if (!scrollingUpAtTop && !scrollingDownAtBottom) return;

        event.preventDefault();
        const pageScroller = document.scrollingElement || document.documentElement;
        pageScroller.scrollTop += event.deltaY;
      }, { passive: false });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeBusinessChats, { once: true });
  } else {
    initializeBusinessChats();
  }
})();
