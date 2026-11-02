(function () {
    'use strict';

    const labels = {
        cdac: 'C-DAC',
        sameer: 'SAMEER',
        cmet: 'C-MET'
    };
    const websites = {
        cdac: { href: 'https://www.cdac.in/', label: 'www.cdac.in' },
        sameer: { href: 'https://sameer.gov.in/', label: 'sameer.gov.in' },
        cmet: { href: 'https://cmet.gov.in/', label: 'cmet.gov.in' }
    };
    const domains = { cdac: [], sameer: [], cmet: [] };
    const messages = window.TECVERSE_INSTITUTION_MESSAGES || {};
    const domainTitles = messages.domainTitles || {};
    const domainDescriptions = messages.domainDescriptions || {};
    const items = Array.isArray(window.TECVERSE_THEMATIC_DOMAINS)
        ? window.TECVERSE_THEMATIC_DOMAINS
        : [];

    items.forEach(item => {
        const key = String(item.institution || '').toLowerCase();
        if (!Object.prototype.hasOwnProperty.call(domains, key)) {
            return;
        }

        domains[key].push({
            title: String(item.title || 'Thematic Area'),
            icon: String(item.icon || 'stars'),
            description: String(item.description || 'Details will be updated soon.')
        });
    });

    const nodes = Array.from(document.querySelectorAll('.institution-node'));
    const stage = document.querySelector('.institution-triangle-stage');
    const panel = document.getElementById('institution-domain-panel');
    const title = document.getElementById('institution-panel-title');
    const websiteLink = document.getElementById('institution-official-website');
    const list = document.getElementById('institution-domain-list');
    const content = document.getElementById('institution-content');
    const closeButton = panel && panel.querySelector('[data-institution-panel-close]');
    const orbitMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    const orbitOffsets = { cdac: -128, sameer: 138, cmet: -8 };
    const orbitSpeed = 0.0045;
    let orbitFrame = null;
    let previouslyActiveNode = null;

    if (!nodes.length || !stage || !panel || !title || !list || !content) {
        return;
    }

    function updateOrbit(timestamp = 0, scheduleNext = true) {
        const rect = stage.getBoundingClientRect();
        const compact = window.innerWidth < 768;
        const centerX = rect.width / 2;
        const centerY = rect.height / 2;
        const radiusX = Math.max(92, rect.width / 2 - (compact ? 76 : 126));
        const radiusY = Math.max(118, rect.height / 2 - (compact ? 92 : 130));
        const rotation = orbitMotion.matches ? 0 : timestamp * orbitSpeed;

        nodes.forEach(node => {
            const offset = orbitOffsets[node.dataset.institution] || 0;
            const angle = (offset + rotation) * Math.PI / 180;
            node.style.setProperty('--orbit-left', `${centerX + Math.cos(angle) * radiusX}px`);
            node.style.setProperty('--orbit-top', `${centerY + Math.sin(angle) * radiusY}px`);
        });

        orbitFrame = null;
        if (scheduleNext && !orbitMotion.matches) {
            orbitFrame = window.requestAnimationFrame(updateOrbit);
        }
    }

    function renderDomain(domain, selectedButton) {
        list.querySelectorAll('.institution-domain-chip').forEach(button => {
            button.classList.toggle('is-selected', button === selectedButton);
        });

        const main = document.createElement('div');
        main.className = 'domain-content-main';
        const icon = document.createElement('span');
        icon.className = 'domain-content-icon';
        const iconElement = document.createElement('i');
        iconElement.className = `bi bi-${domain.icon}`;
        iconElement.setAttribute('aria-hidden', 'true');
        icon.appendChild(iconElement);

        const details = document.createElement('div');
        const kicker = document.createElement('span');
        kicker.className = 'institution-panel-kicker';
        kicker.textContent = `${title.textContent} · ${messages.thematicDomain || 'THEMATIC DOMAIN'}`;
        const heading = document.createElement('h4');
        heading.textContent = domainTitles[domain.title] || domain.title;
        const description = document.createElement('p');
        description.textContent = domainDescriptions[domain.title] || domain.description;
        details.append(kicker, heading, description);
        main.append(icon, details);
        content.replaceChildren(main);
    }

    function openInstitution(key, node) {
        if (!Object.prototype.hasOwnProperty.call(domains, key)) {
            return;
        }

        previouslyActiveNode = node;
        title.textContent = labels[key];
        websiteLink.href = websites[key].href;
        websiteLink.lastChild.textContent = ` ${websites[key].label}`;
        websiteLink.setAttribute('aria-label', `Visit the official ${labels[key]} website`);
        list.replaceChildren();
        content.replaceChildren();
        panel.hidden = false;
        panel.classList.add('is-visible');
        panel.dataset.activeInstitution = key;
        stage.classList.add('has-selection');
        document.body.classList.add('institution-modal-open');

        nodes.forEach(institutionNode => {
            const active = institutionNode === node;
            institutionNode.classList.toggle('is-active', active);
            institutionNode.setAttribute('aria-pressed', String(active));
            institutionNode.setAttribute('aria-expanded', String(active));
        });

        if (!domains[key].length) {
            const placeholder = document.createElement('div');
            placeholder.className = 'domain-content-placeholder';
            const icon = document.createElement('span');
            icon.className = 'domain-content-icon';
            const iconElement = document.createElement('i');
            iconElement.className = 'bi bi-database-add';
            iconElement.setAttribute('aria-hidden', 'true');
            icon.appendChild(iconElement);
            const text = document.createElement('div');
            const heading = document.createElement('strong');
            heading.textContent = messages.noCards || 'No thematic cards found';
            const description = document.createElement('p');
            description.textContent = (messages.addCards || 'Add cards for {0} from the admin panel.')
                .replace('{0}', labels[key]);
            text.append(heading, description);
            placeholder.append(icon, text);
            content.appendChild(placeholder);
        } else {
            domains[key].forEach((domain, index) => {
                const button = document.createElement('button');
                button.type = 'button';
                button.className = 'institution-domain-chip';
                button.setAttribute('role', 'listitem');
                const icon = document.createElement('i');
                icon.className = `bi bi-${domain.icon}`;
                icon.setAttribute('aria-hidden', 'true');
                const text = document.createElement('span');
                text.textContent = domainTitles[domain.title] || domain.title;
                button.append(icon, text);
                button.addEventListener('click', () => renderDomain(domain, button));
                list.appendChild(button);
                if (index === 0) {
                    renderDomain(domain, button);
                }
            });
        }

        panel.focus({ preventScroll: true });
    }

    function closePanel() {
        panel.classList.remove('is-visible');
        panel.hidden = true;
        stage.classList.remove('has-selection');
        document.body.classList.remove('institution-modal-open');
        nodes.forEach(node => {
            node.classList.remove('is-active');
            node.setAttribute('aria-pressed', 'false');
            node.setAttribute('aria-expanded', 'false');
        });
        if (previouslyActiveNode) {
            previouslyActiveNode.focus({ preventScroll: true });
        }
    }

    nodes.forEach(node => {
        node.addEventListener('click', () => openInstitution(node.dataset.institution, node));
    });

    if (closeButton) {
        closeButton.addEventListener('click', closePanel);
    }
    panel.addEventListener('click', event => {
        if (event.target === panel) {
            closePanel();
        }
    });
    document.addEventListener('keydown', event => {
        if (event.key === 'Escape' && !panel.hidden) {
            closePanel();
        }
    });

    updateOrbit(0, false);
    if (!orbitMotion.matches) {
        orbitFrame = window.requestAnimationFrame(updateOrbit);
    }
    window.addEventListener('resize', () => updateOrbit(performance.now(), false));
    orbitMotion.addEventListener('change', () => {
        if (orbitFrame !== null) {
            window.cancelAnimationFrame(orbitFrame);
            orbitFrame = null;
        }
        updateOrbit(performance.now(), false);
        if (!orbitMotion.matches) {
            orbitFrame = window.requestAnimationFrame(updateOrbit);
        }
    });
})();
