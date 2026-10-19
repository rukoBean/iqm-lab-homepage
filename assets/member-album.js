(() => {
  const album = document.querySelector('[data-member-album]');
  if (!album) return;

  const viewport = album.querySelector('.album-scroll');
  if (!viewport) return;

  const track = album.querySelector('.album-track');
  const photos = Array.from(track.children);
  if (photos.length < 2) return;

  const toggle = album.querySelector('.album-toggle');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let cycleWidth = 0;
  let position = 0;
  let paused = false;
  let hovered = false;
  let touching = false;
  let resumeAfter = 0;
  let lastTime = 0;
  let frame = 0;

  function rebuild() {
    cancelAnimationFrame(frame);
    lastTime = 0;
    const progress = cycleWidth ? viewport.scrollLeft % cycleWidth / cycleWidth : 0;
    track.querySelectorAll('[data-album-clone]').forEach(photo => photo.remove());
    cycleWidth = 0;
    toggle.hidden = true;
    if (reducedMotion.matches) return;

    const contentWidth = track.getBoundingClientRect().width;
    if (contentWidth <= viewport.clientWidth + 1) {
      position = 0;
      viewport.scrollLeft = 0;
      return;
    }

    toggle.hidden = false;
    const gap = parseFloat(getComputedStyle(track).columnGap) || 0;
    cycleWidth = contentWidth + gap;
    // Only overflowing albums need a second set for a seamless loop.
    photos.forEach(photo => {
      const clone = photo.cloneNode(true);
      clone.dataset.albumClone = '';
      clone.setAttribute('aria-hidden', 'true');
      clone.inert = true;
      track.appendChild(clone);
    });
    position = progress * cycleWidth;
    viewport.scrollLeft = position;
    frame = requestAnimationFrame(animate);
  }

  function animate(time) {
    const elapsed = lastTime ? Math.min(time - lastTime, 64) : 0;
    lastTime = time;
    if (cycleWidth && !paused && !hovered && !touching &&
        !album.contains(document.activeElement) && time >= resumeAfter) {
      // 28 px/s, with a seamless wrap after the original photos.
      position = (position + elapsed * 0.028) % cycleWidth;
      viewport.scrollLeft = position;
    } else {
      position = viewport.scrollLeft;
    }
    frame = requestAnimationFrame(animate);
  }

  toggle.addEventListener('click', () => {
    paused = !paused;
    toggle.textContent = paused ? toggle.dataset.playLabel : toggle.dataset.pauseLabel;
  });
  album.addEventListener('pointerenter', event => {
    if (event.pointerType === 'mouse') hovered = true;
  });
  album.addEventListener('pointerleave', () => { hovered = false; });
  viewport.addEventListener('pointerdown', () => { touching = true; });
  const endTouch = () => {
    if (!touching) return;
    touching = false;
    resumeAfter = performance.now() + 3000;
  };
  window.addEventListener('pointerup', endTouch);
  window.addEventListener('pointercancel', endTouch);
  viewport.addEventListener('wheel', () => {
    resumeAfter = performance.now() + 3000;
  }, { passive: true });
  reducedMotion.addEventListener('change', rebuild);
  new ResizeObserver(rebuild).observe(viewport);
  rebuild();
})();
