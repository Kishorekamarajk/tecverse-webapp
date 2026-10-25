(() => {
    const addError = (field, message) => {
        let error = field.parentElement.querySelector(".admin-client-error");
        if (!error) {
            error = document.createElement("div");
            error.className = "invalid-feedback d-block admin-client-error";
            field.insertAdjacentElement("afterend", error);
        }
        error.textContent = message;
        field.classList.toggle("is-invalid", Boolean(message));
    };

    document.addEventListener("submit", (event) => {
        const form = event.target.closest("form[data-confirm]");
        if (form && !window.confirm(form.dataset.confirm)) event.preventDefault();
    });

    document.querySelectorAll("form[data-admin-validation]").forEach((form) => {
        const controls = Array.from(form.querySelectorAll("input, select, textarea"));
        const validate = (field) => {
            if (field.disabled || field.type === "submit" || field.type === "button" || field.type === "checkbox") return true;
            field.setCustomValidity("");
            let message = "";
            const value = field.value.trim();

            if (field.required && !value) message = "This field is required.";
            if (!message && value && field.maxLength > 0 && value.length > field.maxLength) {
                message = `Maximum ${field.maxLength} characters allowed.`;
            }
            if (!message && field.type === "number" && value && Number(value) < Number(field.min || 0)) {
                message = `Value must be at least ${field.min || 0}.`;
            }
            if (!message && field.dataset.after && value) {
                const startField = form.querySelector(field.dataset.after);
                if (startField?.value && value <= startField.value) message = "End time must be later than start time.";
            }
            if (!message && field.type === "file" && field.files?.length) {
                const file = field.files[0];
                const accepts = (field.accept || "").split(",").map((item) => item.trim().toLowerCase()).filter(Boolean);
                const extension = file.name.includes(".") ? `.${file.name.split(".").pop().toLowerCase()}` : "";
                const maxBytes = Number(field.dataset.maxFileBytes || 3 * 1024 * 1024);
                const maxMb = maxBytes / (1024 * 1024);
                if (file.size > maxBytes) message = `File must be ${maxMb} MB or smaller.`;
                else if (accepts.length && !accepts.some((type) => type.startsWith(".") ? type === extension : type.endsWith("/*") ? file.type.startsWith(type.slice(0, -1)) : type === file.type)) {
                    message = "Choose a file in one of the allowed formats.";
                }
            }

            if (!message && field.type === "file" && field.dataset.fileOrPath) {
                const pathField = form.querySelector(field.dataset.fileOrPath);
                if (!field.files?.length && !pathField?.value.trim()) {
                    message = "Choose a file or provide an existing URL/path.";
                }
            }

            if (!message && !field.validity.valid) message = field.validationMessage || "Enter a valid value.";

            field.setCustomValidity(message);
            addError(field, message);
            return !message;
        };

        controls.forEach((field) => {
            const validateWithDependents = () => {
                validate(field);
                controls.forEach((dependent) => {
                    const dependsOn = dependent.dataset.after === `#${field.id}`
                        || dependent.dataset.fileOrPath === `#${field.id}`;
                    if (dependsOn) validate(dependent);
                });
            };
            field.addEventListener("input", validateWithDependents);
            field.addEventListener("change", validateWithDependents);
        });

        form.addEventListener("submit", (event) => {
            const invalid = controls.find((field) => !validate(field));
            if (invalid) {
                event.preventDefault();
                invalid.reportValidity();
                invalid.focus();
            }
        });
    });
})();
