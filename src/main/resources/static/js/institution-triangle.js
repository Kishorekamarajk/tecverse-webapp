(function () {
    'use strict';

    const DATA = {
        cdac: {
            title: 'C-DAC',
            domains: []
        },
        sameer: {
            title: 'SAMEER',
            domains: []
        },
        cmet: {
            title: 'C-MET',
            domains: []
        }
    };

    const institutionLabels = {
        cdac: 'C-DAC',
        sameer: 'SAMEER',
        cmet: 'C-MET'
    };

    const dynamicDomains = Array.isArray(window.TECVERSE_THEMATIC_DOMAINS)
        ? window.TECVERSE_THEMATIC_DOMAINS
        : [];
    const messages = window.TECVERSE_INSTITUTION_MESSAGES || {};
    const domainTitles = messages.domainTitles || {};
    const domainDescriptions = messages.domainDescriptions || {};

    function displayDomainTitle(title) {
        return domainTitles[title] || title;
    }

    function displayDomainDescription(title, description) {
        return domainDescriptions[title] || description;
    }

    dynamicDomains.forEach(item => {
        const key = String(item.institution || '').toLowerCase();
        if (!DATA[key]) {
            return;
        }

        DATA[key].title = institutionLabels[key];
        DATA[key].domains.push([
            item.title || 'Thematic Area',
            item.icon || 'stars',
            item.description || 'Details will be updated soon.'
        ]);
    });

    const nodes = document.querySelectorAll('.institution-node');
    const stage = document.querySelector('.institution-triangle-stage');
    const panel = document.getElementById('institution-domain-panel');
    const title = document.getElementById('institution-panel-title');
    const list = document.getElementById('institution-domain-list');
    const content = document.getElementById('institution-content');
    let lastActiveNode = null;
    const orbitMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    const orbitNodes = Array.from(nodes);
    const orbitOffsets = {
        cdac: -128,
        sameer: 138,
        cmet: -8
    };
    const orbitSpeed = 0.0045;
    let orbitFrame = null;

    if (!nodes.length || !stage || !panel || !title || !list || !content) {
        return;
    }

    const closeButton = panel.querySelector('[data-institution-panel-close]');

    function updateOrbit(timestamp = 0, scheduleNext = true) {
        const rect = stage.getBoundingClientRect();
        const compact = window.innerWidth < 768;
        const centerX = rect.width / 2;
        const centerY = rect.height / 2;
        const radiusX = Math.max(92, (rect.width / 2) - (compact ? 76 : 126));
        const radiusY = Math.max(118, (rect.height / 2) - (compact ? 92 : 130));
        const rotation = orbitMotion.matches ? 0 : timestamp * orbitSpeed;

        orbitNodes.forEach(node => {
            const angle = ((orbitOffsets[node.dataset.institution] || 0) + rotation) * Math.PI / 180;
            node.style.setProperty('--orbit-left', `${centerX + Math.cos(angle) * radiusX}px`);
            node.style.setProperty('--orbit-top', `${centerY + Math.sin(angle) * radiusY}px`);
        });

        orbitFrame = null;

        if (scheduleNext && !orbitMotion.matches) {
            orbitFrame = window.requestAnimationFrame(updateOrbit);
        }
    }

    function startOrbit() {
        if (orbitFrame === null && !orbitMotion.matches) {
            orbitFrame = window.requestAnimationFrame(updateOrbit);
        }
    }

    function stopOrbit() {
        if (orbitFrame !== null) {
            window.cancelAnimationFrame(orbitFrame);
            orbitFrame = null;
        }
    }

    function animatePanel() {
        panel.classList.remove('is-visible');
        void panel.offsetWidth;
        panel.classList.add('is-visible');
    }

    function renderDomain(institution, domain, selectedButton) {
        list.querySelectorAll('.institution-domain-chip')
            .forEach(button => button.classList.remove('is-selected'));

        if (selectedButton) {
            selectedButton.classList.add('is-selected');
        }

        content.innerHTML = `
            <div class="domain-content-main">
                <span class="domain-content-icon">
                    <i class="bi bi-${domain[1]}" aria-hidden="true"></i>
                </span>
                <div>
                    <span class="institution-panel-kicker">${institution.title} · ${messages.thematicDomain || 'THEMATIC DOMAIN'}</span>
                    <h4>${displayDomainTitle(domain[0])}</h4>
                    <p>${displayDomainDescription(domain[0], domain[2])}</p>
                </div>
            </div>
        `;

        content.style.animation = 'none';
        void content.offsetWidth;
        content.style.animation = '';
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

        if (lastActiveNode) {
            lastActiveNode.focus({ preventScroll: true });
        }
    }

    function renderInstitution(key, focusDomain = null) {
        const institution = DATA[key];
        if (!institution) return;

        panel.hidden = false;
        stage.classList.add('has-selection');
        panel.dataset.activeInstitution = key;
        document.body.classList.add('institution-modal-open');

        panel.classList.remove(
            'institution-domain-panel--right',
            'institution-domain-panel--top-left',
            'institution-domain-panel--top-right'
        );

        if (key === 'cdac') {
            panel.classList.add('institution-domain-panel--right');
        } else if (key === 'sameer') {
            panel.classList.add('institution-domain-panel--top-left');
        } else {
            panel.classList.add('institution-domain-panel--top-right');
        }

        title.textContent = institution.title;
        list.innerHTML = '';

        nodes.forEach(node => {
            const active = node.dataset.institution === key;
            node.classList.toggle('is-active', active);
            node.setAttribute('aria-pressed', active ? 'true' : 'false');
            node.setAttribute('aria-expanded', active ? 'true' : 'false');
        });

        if (!institution.domains.length) {
            content.innerHTML = `
                <div class="domain-content-placeholder">
                    <span class="domain-content-icon">
                        <i class="bi bi-database-add" aria-hidden="true"></i>
                    </span>
                    <div>
                        <strong>${messages.noCards || 'No thematic cards found'}</strong>
                        <p>${(messages.addCards || 'Add cards for {0} from the admin panel.').replace('{0}', institution.title)}</p>
                    </div>
                </div>
            `;
            animatePanel();
            panel.focus({ preventScroll: true });
            return;
        }

        institution.domains.forEach((domain, index) => {
            const button = document.createElement('button');

            button.type = 'button';
            button.className = 'institution-domain-chip';
            button.setAttribute('role', 'listitem');
            button.innerHTML =
                '<i class="bi bi-' + domain[1] + '" aria-hidden="true"></i>' +
                '<span>' + displayDomainTitle(domain[0]) + '</span>';

            button.addEventListener('click', () => {
                renderDomain(institution, domain, button);
            });

            list.appendChild(button);

            if (focusDomain === index) {
                renderDomain(institution, domain, button);
            }
        });

        renderDomain(institution, institution.domains[focusDomain ?? 0], list.children[focusDomain ?? 0]);
        animatePanel();
        panel.focus({ preventScroll: true });
    }

    nodes.forEach(node => {
        node.addEventListener('click', () => {
            lastActiveNode = node;
            renderInstitution(node.dataset.institution);
        });
    });

    updateOrbit(0, false);
    startOrbit();
    window.addEventListener('resize', () => updateOrbit(performance.now(), false));
    orbitMotion.addEventListener('change', () => {
        stopOrbit();
        updateOrbit(performance.now(), false);
        if (!orbitMotion.matches) {
            startOrbit();
        }
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
})();
