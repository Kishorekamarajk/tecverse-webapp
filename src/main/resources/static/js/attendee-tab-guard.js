(() => {
  const dialog = document.getElementById('attendeeTabGuard');
  if (!dialog) return;

  const script = [...document.scripts].find(item => {
    try {
      return new URL(item.src, window.location.href).pathname.endsWith('/js/attendee-tab-guard.js');
    } catch {
      return false;
    }
  });
  const scriptPath = script ? new URL(script.src, window.location.href).pathname : '';
  const contextPath = scriptPath.endsWith('/js/attendee-tab-guard.js')
    ? scriptPath.slice(0, -'/js/attendee-tab-guard.js'.length)
    : '';
  const lockKey = `tecverse-attendee-tab:${contextPath || '/'}`;
  const tabId = window.crypto?.randomUUID?.() || `${Date.now()}-${Math.random()}`;
  const leaseDuration = 10_000;
  const heartbeatInterval = 2_000;
  const closeButton = dialog.querySelector('[data-tab-guard-close]');
  let ownsLock = false;
  let heartbeat;
  let retryTimer;

  function readLock() {
    try {
      const value = window.localStorage.getItem(lockKey);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error('Unable to verify the attendee tab lock.', error);
      dialog.dataset.storageError = 'true';
      showBlockedDialog('Tec-Verse could not verify whether another attendee tab is active. Close this tab and continue in the existing Tec-Verse tab.');
      return null;
    }
  }

  function writeLock() {
    try {
      const lock = { owner: tabId, updatedAt: Date.now() };
      window.localStorage.setItem(lockKey, JSON.stringify(lock));
      const confirmed = readLock();
      ownsLock = confirmed?.owner === tabId;
      return ownsLock;
    } catch (error) {
      console.error('Unable to claim the attendee tab lock.', error);
      dialog.dataset.storageError = 'true';
      showBlockedDialog('Tec-Verse could not verify whether another attendee tab is active. Close this tab and continue in the existing Tec-Verse tab.');
      return false;
    }
  }

  function showBlockedDialog(message) {
    if (dialog.open) return;
    const paragraph = dialog.querySelector('[data-tab-guard-message]');
    if (paragraph && message) paragraph.textContent = message;
    dialog.showModal();
  }

  dialog.addEventListener('cancel', event => event.preventDefault());
  closeButton?.addEventListener('click', () => {
    window.close();
    window.setTimeout(() => {
      if (window.closed) return;
      const paragraph = dialog.querySelector('[data-tab-guard-message]');
      if (paragraph) paragraph.textContent = 'Your browser did not allow Tec-Verse to close this tab. Please close it manually and continue in the other tab.';
    }, 100);
  });

  function claimLock() {
    const current = readLock();
    if (dialog.open) return false;
    if (current && current.owner !== tabId && Date.now() - current.updatedAt < leaseDuration) {
      showBlockedDialog();
      return false;
    }
    if (!writeLock()) {
      showBlockedDialog();
      return false;
    }
    return true;
  }

  function startHeartbeat() {
    window.clearInterval(heartbeat);
    heartbeat = window.setInterval(blockIfLockLost, heartbeatInterval);
  }

  function retryClaim() {
    if (ownsLock || dialog.dataset.storageError === 'true') return;
    const current = readLock();
    if (dialog.dataset.storageError === 'true') return;
    if (!current || Date.now() - current.updatedAt >= leaseDuration) {
      if (claimLock()) {
        window.clearInterval(retryTimer);
        dialog.close();
        startHeartbeat();
      }
    }
  }

  function blockIfLockLost() {
    const current = readLock();
    if (dialog.dataset.storageError === 'true') {
      window.clearInterval(heartbeat);
      return;
    }
    if (current?.owner !== tabId) {
      ownsLock = false;
      window.clearInterval(heartbeat);
      showBlockedDialog();
      retryTimer = window.setInterval(retryClaim, heartbeatInterval);
      return;
    }
    writeLock();
  }

  if (!claimLock()) {
    if (dialog.dataset.storageError !== 'true') {
      retryTimer = window.setInterval(retryClaim, heartbeatInterval);
    }
    return;
  }

  startHeartbeat();
  window.addEventListener('storage', event => {
    if (event.key !== lockKey || !ownsLock || !event.newValue) return;
    try {
      if (JSON.parse(event.newValue).owner !== tabId) {
        ownsLock = false;
        window.clearInterval(heartbeat);
        showBlockedDialog();
      }
    } catch (error) {
      console.error('Unable to verify the attendee tab lock update.', error);
      dialog.dataset.storageError = 'true';
      window.clearInterval(heartbeat);
      showBlockedDialog();
    }
  });

  window.addEventListener('pagehide', () => {
    window.clearInterval(heartbeat);
    window.clearInterval(retryTimer);
    if (!ownsLock) return;
    try {
      const current = readLock();
      if (current?.owner === tabId) window.localStorage.removeItem(lockKey);
    } catch (error) {
      console.error('Unable to release the attendee tab lock.', error);
    }
  });

  window.addEventListener('pageshow', event => {
    if (!event.persisted || ownsLock) return;
    if (claimLock()) startHeartbeat();
    else retryTimer = window.setInterval(retryClaim, heartbeatInterval);
  });
})();
