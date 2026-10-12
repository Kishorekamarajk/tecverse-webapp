(() => {
    "use strict";

    const successModal = document.getElementById("inquiry-success-modal");
    if (successModal && window.bootstrap?.Modal) {
        successModal.addEventListener("shown.bs.modal", () => {
            successModal.querySelector(".modal-body button").focus();
        });
        successModal.addEventListener("hidden.bs.modal", () => {
            document.querySelector("[data-inquiry-form] button[type=submit]")?.focus();
        });
        window.bootstrap.Modal.getOrCreateInstance(successModal).show();
    }

    document.querySelectorAll("[data-inquiry-form]").forEach((form, index) => {
        const country = form.querySelector("[name=country]");
        const phone = form.querySelector("[name=phone]");
        if (!country || !phone) return;
        const controls = [...form.querySelectorAll("input, select, textarea")];
        const feedback = new Map();
        phone.autocomplete = "tel";
        phone.inputMode = "tel";
        let previousCode = "";

        function updateCountry() {
            const code = country.selectedOptions[0]?.dataset.dialCode || "";
            phone.placeholder = "Phone number";
            const current = phone.value.trim();
            if (!current) {
                phone.value = code ? code + " " : "";
            } else if (previousCode && current.startsWith(previousCode)) {
                const nationalNumber = current.slice(previousCode.length).trimStart();
                phone.value = code + " " + nationalNumber;
            }
            previousCode = code;
        }

        controls.forEach((control, fieldIndex) => {
            const error = document.createElement("small");
            error.id = "contact-error-" + index + "-" + fieldIndex;
            error.className = "error d-block";
            error.setAttribute("aria-live", "polite");
            let errorAnchor = control;
            if (control === phone) {
                errorAnchor = control.closest(".compact-phone-input")?.parentElement.querySelector(".phone-hint")
                    || control.closest(".compact-phone-input")
                    || control;
            } else if (control.name === "captchaAnswer") {
                errorAnchor = control.closest(".compact-captcha")?.querySelector(":scope > span") || control;
            }
            errorAnchor.insertAdjacentElement("afterend", error);
            control.setAttribute("aria-describedby",
                [control.getAttribute("aria-describedby"), error.id].filter(Boolean).join(" "));
            feedback.set(control, error);
        });

        function validate(control) {
            control.setCustomValidity("");
            const rawValue = control.value.trim();
            // An automatically inserted prefix alone is not a supplied number.
            const value = control === phone && rawValue === previousCode ? "" : rawValue;
            if (control.required && !value) {
                control.setCustomValidity("Please complete this field.");
            } else if (control.maxLength > 0 && value.length > control.maxLength) {
                control.setCustomValidity("Maximum " + control.maxLength + " characters allowed.");
            } else if (control === phone && value) {
                const digits = value.replace(/\D/g, "");
                const nationalDigits = value.startsWith("+91") ? digits.slice(2) : digits;
                if (country.value !== "IN" || !/^\+?[0-9 ()-]+$/.test(value)
                    || nationalDigits.length !== 10 || !/^[6-9]/.test(nationalDigits)) {
                    control.setCustomValidity("Enter a valid 10-digit Indian mobile number.");
                } else if (value.startsWith("+") && !value.startsWith(previousCode)) {
                    control.setCustomValidity("The phone prefix must match the selected country.");
                }
            }
            const valid = control.checkValidity();
            feedback.get(control).textContent = valid ? "" : control.validationMessage;
            control.setAttribute("aria-invalid", String(!valid));
            return valid;
        }

        // Native validation remains available if JavaScript is disabled.
        form.noValidate = true;
        controls.forEach(control => {
            control.addEventListener("blur", () => validate(control));
            control.addEventListener("input", () => {
                if (control.getAttribute("aria-invalid") === "true") validate(control);
            });
        });
        country.addEventListener("change", () => {
            updateCountry();
            validate(country);
            validate(phone);
        });
        form.addEventListener("submit", event => {
            controls.forEach(control => {
                if (control.type !== "file") control.value = control.value.trim();
            });
            const invalid = controls.filter(control => !validate(control));
            if (invalid.length) {
                event.preventDefault();
                invalid[0].focus();
            } else if (!phone.required && phone.value.trim() === previousCode) {
                phone.value = "";
            }
        });
        updateCountry();
    });
})();
