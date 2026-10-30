document.addEventListener('DOMContentLoaded', () => {
  const search = document.querySelector('[data-stall-search]');
  if (!search) return;

  const threads = Array.from(document.querySelectorAll('.stall-thread-link'));
  search.addEventListener('input', () => {
    const query = search.value.trim().toLocaleLowerCase();
    threads.forEach(thread => {
      thread.hidden = query !== '' && !thread.dataset.search.toLocaleLowerCase().includes(query);
    });
  });
});
