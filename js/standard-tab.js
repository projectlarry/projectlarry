(function () {
  function markStandardTabs() {
    document.querySelectorAll(".tab").forEach(function (tab) {
      const text = (tab.textContent || "").trim().toLowerCase();

      if (/^7\s*frame\b/.test(text)) {
        tab.classList.add("standard-7-frame");
      }
    });
  }

  markStandardTabs();

  const observer = new MutationObserver(markStandardTabs);
  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
})();
