export function animateIn(el, className = 'motion-in') {
  if (!el) return;
  el.classList.remove(className);
  void el.offsetWidth;
  el.classList.add(className);
}

export function stagger(container, selector = ':scope > *', delay = 35) {
  if (!container) return;

  const items = container.querySelectorAll(selector);

  items.forEach((el, i) => {
    el.style.animationDelay = `${i * delay}ms`;
    el.classList.add('motion-in');
  });
}

export function transitionChildren(container, selector = ':scope > *') {
  if (!container) return;

  const items = container.querySelectorAll(selector);

  items.forEach((el, i) => {
    el.style.animationDelay = `${i * 25}ms`;
  });
}
