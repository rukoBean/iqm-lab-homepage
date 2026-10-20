(() => {
  const nav = document.querySelector('.nav');
  if (!nav) return;

  const toggle = nav.querySelector('.nav-toggle');
  const links = nav.querySelector('.navlinks');
  if (!toggle || !links) return;

  const mobile = window.matchMedia('(max-width: 980px)');

  function setOpen(open) {
    nav.classList.toggle('nav--open', open);
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? toggle.dataset.closeLabel : toggle.dataset.openLabel);
  }

  toggle.addEventListener('click', () => {
    setOpen(toggle.getAttribute('aria-expanded') !== 'true');
  });

  nav.addEventListener('keydown', event => {
    if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
      setOpen(false);
      toggle.focus();
    }
  });

  links.addEventListener('click', event => {
    if (mobile.matches && event.target.closest('a')) setOpen(false);
  });

  function syncViewport() {
    const focused = document.activeElement;
    toggle.hidden = !mobile.matches;
    setOpen(false);
    if (mobile.matches && links.contains(focused)) toggle.focus();
    if (!mobile.matches && focused === toggle) nav.querySelector('.brand').focus();
  }

  mobile.addEventListener('change', syncViewport);

  nav.classList.add('nav--collapsible');
  syncViewport();
})();
