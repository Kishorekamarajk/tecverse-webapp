document.addEventListener("click", (event) => {
    const openButton = event.target.closest("[data-session-dialog-open]");
    if (openButton) {
        const dialog = document.getElementById(openButton.getAttribute("aria-controls"));
        if (dialog instanceof HTMLDialogElement && !dialog.open) dialog.showModal();
        return;
    }

    const closeButton = event.target.closest("[data-session-dialog-close]");
    if (closeButton) {
        closeButton.closest("dialog")?.close();
    }
});

document.querySelectorAll("[data-session-dialog]").forEach((dialog) => {
    dialog.addEventListener("click", (event) => {
        if (event.target === dialog) dialog.close();
    });
});
