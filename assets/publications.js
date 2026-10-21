(() => {
  const page = document.querySelector('.publications-page');
  if (!page) return;

  const drawer = page.querySelector('.publication-years-drawer');
  const trigger = page.querySelector('.publication-filter-trigger');
  if (typeof drawer.showModal !== 'function') return;

  trigger.addEventListener('click', () => {
    drawer.showModal();
    trigger.setAttribute('aria-expanded', 'true');
    document.body.classList.add('publication-drawer-open');
  });

  drawer.querySelector('.publication-drawer-close').addEventListener('click', () => drawer.close());
  drawer.addEventListener('click', (event) => {
    if (event.target !== drawer) return;
    const bounds = drawer.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right ||
        event.clientY < bounds.top || event.clientY > bounds.bottom) {
      drawer.close();
    }
  });
  drawer.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => drawer.close());
  });
  drawer.addEventListener('close', () => {
    trigger.setAttribute('aria-expanded', 'false');
    document.body.classList.remove('publication-drawer-open');
  });

  window.matchMedia('(max-width: 760px)').addEventListener('change', (event) => {
    if (!event.matches && drawer.open) drawer.close();
  });
  page.classList.add('publications-enhanced');
})();
