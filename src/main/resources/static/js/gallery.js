(() => {
    const tabs = document.querySelectorAll("[data-gallery-tab]");
    const panels = document.querySelectorAll("[data-gallery-year]");

    const setYear = (year) => {
        tabs.forEach((tab) => tab.classList.toggle("is-active", tab.dataset.galleryTab === year));
        panels.forEach((panel) => panel.classList.toggle("is-active", panel.dataset.galleryYear === year));
    };

    tabs.forEach((tab) => {
        tab.addEventListener("click", () => setYear(tab.dataset.galleryTab));
    });
})();

(() => {
    const carousels = document.querySelectorAll("[data-gallery-carousel]");
    if (!carousels.length) return;

    const slots = { "0": "center", "1": "right-1", "2": "right-2", "3": "right-3", "-1": "left-1", "-2": "left-2", "-3": "left-3" };
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    carousels.forEach((carousel) => {
        const slides = Array.from(carousel.querySelectorAll(".gallery-carousel__slide"));
        const previous = carousel.querySelector("[data-gallery-prev]");
        const next = carousel.querySelector("[data-gallery-next]");
        if (!slides.length || !previous || !next) return;

        let active = 0;
        let timer;

        const render = () => {
            slides.forEach((slide, index) => {
                let offset = index - active;
                if (offset > slides.length / 2) offset -= slides.length;
                if (offset < -slides.length / 2) offset += slides.length;
                slide.dataset.slot = slots[offset] || "hidden";
                slide.setAttribute("aria-hidden", offset === 0 ? "false" : "true");
                slide.tabIndex = offset === 0 ? 0 : -1;
            });
        };

        const move = (direction) => {
            active = (active + direction + slides.length) % slides.length;
            render();
        };
        const stop = () => window.clearInterval(timer);
        const start = () => {
            stop();
            if (!reduceMotion && slides.length > 1 && !document.hidden) {
                timer = window.setInterval(() => move(1), 4200);
            }
        };
        const restart = () => { stop(); start(); };

        previous.addEventListener("click", () => { move(-1); restart(); });
        next.addEventListener("click", () => { move(1); restart(); });
        carousel.addEventListener("mouseenter", stop);
        carousel.addEventListener("mouseleave", start);
        carousel.addEventListener("focusin", stop);
        carousel.addEventListener("focusout", (event) => { if (!carousel.contains(event.relatedTarget)) start(); });
        document.addEventListener("visibilitychange", () => document.hidden ? stop() : start());

        render();
        start();
    });
})();

(() => {
    const imagesGrid = document.querySelector("[data-gallery-images]");
    const videosGrid = document.querySelector("[data-gallery-videos]");

    if (!imagesGrid || !videosGrid) return;

    const states = {
        images: document.querySelector("[data-gallery-images-state]"),
        videos: document.querySelector("[data-gallery-videos-state]")
    };

    const escapeHtml = (value) => String(value || "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");

    const apiRoot = document.querySelector("[data-gallery-api-url]");
    const apiUrl = apiRoot ? apiRoot.getAttribute("data-gallery-api-url") : "/api/gallery";
    const contextPath = apiUrl.replace(/\/api\/gallery.*$/, "");
    const mediaUrl = (url) => {
        const value = String(url || "");
        if (/^(https?:)?\/\//i.test(value) || /^(data|blob):/i.test(value)) return value;
        if (value.startsWith("/")) return contextPath + value;
        return value;
    };

    const isExternalVideo = (url) => /^https?:\/\//i.test(url || "") && !/\.(mp4|webm|ogg|mov)(\?|#|$)/i.test(url || "");

    const setState = (key, message, tone = "muted") => {
        const state = states[key];
        if (!state) return;
        state.textContent = message;
        state.dataset.tone = tone;
        state.hidden = !message;
    };

    const renderImages = (items) => {
        imagesGrid.innerHTML = "";
        if (!items.length) {
            setState("images", "No gallery images are published yet.");
            return;
        }

        setState("images", "");
        imagesGrid.innerHTML = items.map((item, index) => `
            <a href="${escapeHtml(mediaUrl(item.imageUrl))}" class="gallery-photo-card" data-reveal="fade-up" data-reveal-delay="${(index % 4) * 60}">
                <img src="${escapeHtml(mediaUrl(item.imageUrl))}" alt="${escapeHtml(item.title)}" loading="lazy">
                <span class="gallery-photo-card__overlay"><span>${escapeHtml(item.category || item.title)}</span></span>
            </a>
        `).join("");
    };

    const renderVideos = (items) => {
        videosGrid.innerHTML = "";
        if (!items.length) {
            setState("videos", "No gallery videos are published yet.");
            return;
        }

        setState("videos", "");
        videosGrid.innerHTML = items.map((item, index) => {
            const title = escapeHtml(item.title);
            const description = escapeHtml(item.description);
            const videoUrl = escapeHtml(mediaUrl(item.videoUrl));
            const thumbnailUrl = escapeHtml(mediaUrl(item.thumbnailUrl || ""));
            const delay = (index % 3) * 100;

            if (isExternalVideo(item.videoUrl)) {
                return `
                    <a href="${videoUrl}" target="_blank" rel="noopener" class="gallery-video-card" data-reveal="fade-up" data-reveal-delay="${delay}">
                        <span class="gallery-video-card__thumb">
                            ${thumbnailUrl ? `<img src="${thumbnailUrl}" alt="${title}" loading="lazy">` : ""}
                            <span class="gallery-video-card__play"><span><i class="bi bi-play-fill"></i></span></span>
                        </span>
                        <div class="gallery-video-card__body">
                            <h3>${title}</h3>
                            <p>${description}</p>
                        </div>
                    </a>
                `;
            }

            return `
                <div class="gallery-video-card" data-reveal="fade-up" data-reveal-delay="${delay}">
                    <video controls preload="metadata" src="${videoUrl}" ${thumbnailUrl ? `poster="${thumbnailUrl}"` : ""}></video>
                    <div class="gallery-video-card__body">
                        <h3>${title}</h3>
                        <p>${description}</p>
                    </div>
                </div>
            `;
        }).join("");
    };

    const revealRenderedItems = () => {
        document.querySelectorAll(".gallery-page [data-reveal]").forEach((element) => {
            element.classList.add("reveal-visible");
        });
    };

    fetch(apiUrl, { headers: { Accept: "application/json" } })
        .then((response) => {
            if (!response.ok) throw new Error("Gallery API failed.");
            return response.json();
        })
        .then((payload) => {
            const data = payload.data || {};
            renderImages(Array.isArray(data.images) ? data.images : []);
            renderVideos(Array.isArray(data.videos) ? data.videos : []);
            revealRenderedItems();
        })
        .catch(() => {
            setState("images", "Gallery images could not be loaded. Please refresh and try again.", "danger");
            setState("videos", "Gallery videos could not be loaded. Please refresh and try again.", "danger");
        });
})();
