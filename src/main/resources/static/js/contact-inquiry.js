(() => {
    "use strict";

    const successModal = document.getElementById("inquiry-success-modal");
    if (successModal && window.bootstrap?.Modal) {
        successModal.addEventListener("shown.bs.modal", () => successModal.querySelector(".modal-body button").focus());
        successModal.addEventListener("hidden.bs.modal", () => document.querySelector("[data-inquiry-form] button[type=submit]")?.focus());
        window.bootstrap.Modal.getOrCreateInstance(successModal).show();
    }

    document.querySelectorAll("[data-inquiry-form]").forEach((form, index) => {
        const country = form.querySelector("[name=country]");
        const phone = form.querySelector("[name=phone]");
        const email = form.querySelector("[name=email]");
        if (!country || !phone || !email) return;

        const sendPhoneButton = form.querySelector("[data-contact-otp-send]");
        const sendEmailButton = form.querySelector("[data-contact-email-otp-send]");
        const submitButton = form.querySelector("[data-contact-submit]");
        const captchaRefreshButton = form.querySelector("[data-contact-captcha-refresh]");
        const captchaQuestion = form.querySelector("[data-contact-captcha-question]");
        const captchaStatus = form.querySelector("[data-contact-captcha-status]");
        const dialog = form.querySelector("[data-contact-otp-dialog]");
        const dialogTitle = dialog.querySelector("#contact-otp-title");
        const dialogKicker = dialog.querySelector("[data-contact-otp-kicker]");
        const dialogRecipient = dialog.querySelector("[data-contact-otp-recipient]");
        const dialogCode = dialog.querySelector("[data-contact-dialog-code]");
        const dialogStatus = dialog.querySelector("[data-contact-dialog-status]");
        const dialogVerify = dialog.querySelector("[data-contact-dialog-verify]");
        const dialogResend = dialog.querySelector("[data-contact-dialog-resend]");
        const feedback = new Map();
        const controls = [...form.querySelectorAll("input:not([type=hidden]):not([data-contact-dialog-code]), select, textarea")];
        let previousCode = "";
        let verifiedPhone = submitButton.dataset.contactVerified === "true" ? normalizePhone() : "";
        let verifiedEmail = submitButton.dataset.contactEmailVerified === "true" ? normalizeEmail() : "";
        let requestedPhone = "";
        let requestedEmail = "";
        let activeChannel = "";
        let resendTimer = null;

        phone.autocomplete = "tel";
        phone.inputMode = "tel";

        function normalizePhone() { return phone.value.trim().replace(/[\s()-]/g, ""); }
        function normalizeEmail() { return email.value.trim().toLowerCase(); }
        function updateSubmitState() {
            submitButton.disabled = !(verifiedPhone && verifiedPhone === normalizePhone()
                && verifiedEmail && verifiedEmail === normalizeEmail());
        }
        function setFieldStatus(channel, message, isError = false) {
            const status = form.querySelector(channel === "email" ? "[data-contact-email-otp-status]" : "[data-contact-otp-status]");
            if (!status) return;
            status.textContent = message;
            status.style.color = isError ? "#b42318" : "#177451";
        }
        function setDialogStatus(message, isError = false) {
            dialogStatus.textContent = message;
            dialogStatus.style.color = isError ? "#b42318" : "#177451";
        }
        function recipient(channel) { return channel === "email" ? normalizeEmail() : normalizePhone(); }

        if (verifiedEmail) {
            sendEmailButton.textContent = "Verified";
            setFieldStatus("email", "Email address verified.");
        }
        if (verifiedPhone) {
            sendPhoneButton.textContent = "Verified";
            setFieldStatus("phone", "Mobile number verified.");
        }
        updateSubmitState();

        captchaRefreshButton?.addEventListener("click", async () => {
            captchaRefreshButton.disabled = true;
            captchaStatus.textContent = "";
            try {
                const contextPath = (document.body.dataset.contextPath || "").replace(/\/$/, "");
                const response = await fetch(contextPath + "/inquiry/captcha", {
                    credentials: "same-origin", cache: "no-store", headers: { "Accept": "application/json" }
                });
                const result = await response.json().catch(() => ({}));
                if (!response.ok || !result.question) throw new Error(result.message || "Could not refresh the security question. Please try again.");
                captchaQuestion.textContent = result.question;
                const answer = form.querySelector('[name="captchaAnswer"]');
                answer.value = "";
                answer.setCustomValidity("");
                answer.removeAttribute("aria-invalid");
                feedback.get(answer).textContent = "";
                answer.focus();
            } catch (error) {
                captchaStatus.textContent = error.message;
            } finally {
                captchaRefreshButton.disabled = false;
            }
        });

        function updateCountry() {
            const code = country.selectedOptions[0]?.dataset.dialCode || "";
            phone.placeholder = "Phone number";
            const current = phone.value.trim();
            if (!current) phone.value = code ? code + " " : "";
            else if (previousCode && current.startsWith(previousCode)) phone.value = code + " " + current.slice(previousCode.length).trimStart();
            previousCode = code;
        }

        controls.forEach((control, fieldIndex) => {
            const error = document.createElement("small");
            error.id = `contact-error-${index}-${fieldIndex}`;
            error.className = "error d-block";
            error.setAttribute("aria-live", "polite");
            let anchor = control;
            if (control === phone || control === email) anchor = control.closest(".compact-phone-input") || control;
            else if (control.name === "captchaAnswer") anchor = control.closest(".compact-captcha")?.querySelector(":scope > span") || control;
            anchor.insertAdjacentElement("afterend", error);
            control.setAttribute("aria-describedby", [control.getAttribute("aria-describedby"), error.id].filter(Boolean).join(" "));
            feedback.set(control, error);
        });

        function validate(control) {
            control.setCustomValidity("");
            const raw = control.value.trim();
            const value = control === phone && raw === previousCode ? "" : raw;
            if (control.required && !value) control.setCustomValidity("Please complete this field.");
            else if (control.maxLength > 0 && value.length > control.maxLength) control.setCustomValidity(`Maximum ${control.maxLength} characters allowed.`);
            else if (control === phone && value) {
                const digits = value.replace(/\D/g, "");
                const national = value.startsWith("+91") ? digits.slice(2) : digits;
                if (country.value !== "IN" || !/^\+?[0-9 ()-]+$/.test(value) || national.length !== 10 || !/^[6-9]/.test(national)) {
                    control.setCustomValidity("Enter a valid 10-digit Indian mobile number.");
                } else if (value.startsWith("+") && !value.startsWith(previousCode)) control.setCustomValidity("The phone prefix must match the selected country.");
            }
            const valid = control.checkValidity();
            feedback.get(control).textContent = valid ? "" : control.validationMessage;
            control.setAttribute("aria-invalid", String(!valid));
            return valid;
        }

        async function postOtp(path, payload) {
            const contextPath = (document.body.dataset.contextPath || "/").replace(/\/$/, "");
            const response = await fetch(contextPath + path, {
                method: "POST", credentials: "same-origin",
                headers: { "Content-Type": "application/json", "Accept": "application/json" },
                body: JSON.stringify(payload)
            });
            const result = await response.json().catch(() => ({}));
            if (!response.ok || result.success === false) throw new Error(result.message || "Unable to complete verification. Please try again.");
            return result;
        }

        function openDialog(channel) {
            activeChannel = channel;
            dialogKicker.textContent = channel === "email" ? "EMAIL VERIFICATION" : "MOBILE VERIFICATION";
            dialogTitle.textContent = channel === "email" ? "Verify your email" : "Verify your mobile number";
            dialogRecipient.textContent = recipient(channel);
            dialogCode.value = "";
            setDialogStatus("Enter the 6-digit code we sent you.");
            if (!dialog.open) dialog.showModal();
            dialogCode.focus();
        }

        async function sendOtp(channel, resend = false) {
            const isEmail = channel === "email";
            const field = isEmail ? email : phone;
            const button = isEmail ? sendEmailButton : sendPhoneButton;
            if (isEmail) {
                if (!field.value.trim() || !field.checkValidity()) { validate(field); field.focus(); return; }
            } else {
                if (!validate(field)) { field.focus(); return; }
                if (country.value !== "IN") { setFieldStatus(channel, "Mobile OTP verification is currently available for Indian numbers.", true); return; }
            }

            const requested = isEmail ? requestedEmail : requestedPhone;
            if (!resend && requested && requested === recipient(channel)) { openDialog(channel); return; }
            button.disabled = true;
            if (resend) dialogResend.disabled = true;
            setFieldStatus(channel, isEmail ? "Sending verification code…" : "Sending OTP…");
            try {
                const path = isEmail ? "/contact/send-email-otp" : "/contact/send-mobile-otp";
                const payload = isEmail
                    ? { email: email.value.trim(), name: form.querySelector("[name=name]")?.value.trim() || "" }
                    : { phone: phone.value, country: country.value };
                await postOtp(path, payload);
                if (isEmail) requestedEmail = normalizeEmail(); else requestedPhone = normalizePhone();
                button.textContent = "Enter code";
                button.disabled = false;
                openDialog(channel);
                dialogResend.disabled = true;
                let seconds = 60;
                dialogResend.textContent = "Resend (60s)";
                clearInterval(resendTimer);
                resendTimer = setInterval(() => {
                    seconds -= 1;
                    if (seconds <= 0) {
                        clearInterval(resendTimer);
                        dialogResend.disabled = false;
                        dialogResend.textContent = "Resend code";
                    } else dialogResend.textContent = `Resend (${seconds}s)`;
                }, 1000);
                setFieldStatus(channel, isEmail ? "Verification code sent to your email." : "OTP sent to your mobile.");
            } catch (error) {
                setFieldStatus(channel, error.message, true);
                button.disabled = false;
                if (resend) dialogResend.disabled = false;
            }
        }

        sendEmailButton.addEventListener("click", () => sendOtp("email"));
        sendPhoneButton.addEventListener("click", () => sendOtp("phone"));
        dialogResend.addEventListener("click", () => sendOtp(activeChannel, true));
        dialogVerify.addEventListener("click", async () => {
            const otp = dialogCode.value.trim();
            if (!/^\d{6}$/.test(otp)) { setDialogStatus("Enter the 6-digit code.", true); dialogCode.focus(); return; }
            dialogVerify.disabled = true;
            setDialogStatus("Verifying…");
            try {
                const isEmail = activeChannel === "email";
                const path = isEmail ? "/contact/verify-email-otp" : "/contact/verify-mobile-otp";
                const payload = isEmail ? { email: email.value.trim(), otp } : { phone: phone.value, country: country.value, otp };
                await postOtp(path, payload);
                if (isEmail) {
                    verifiedEmail = normalizeEmail();
                    sendEmailButton.textContent = "Verified";
                    setFieldStatus("email", "Email address verified.");
                } else {
                    verifiedPhone = normalizePhone();
                    sendPhoneButton.textContent = "Verified";
                    setFieldStatus("phone", "Mobile number verified.");
                }
                updateSubmitState();
                setDialogStatus("Verified successfully.");
                clearInterval(resendTimer);
                dialog.close();
            } catch (error) {
                setDialogStatus(error.message, true);
            } finally { dialogVerify.disabled = false; }
        });
        dialog.querySelector("[data-contact-otp-close]").addEventListener("click", () => dialog.close());
        dialog.addEventListener("click", event => { if (event.target === dialog) dialog.close(); });

        phone.addEventListener("input", () => {
            const current = normalizePhone();
            if ((verifiedPhone && current !== verifiedPhone) || (requestedPhone && current !== requestedPhone)) {
                verifiedPhone = ""; requestedPhone = ""; sendPhoneButton.textContent = "Send OTP";
                setFieldStatus("phone", ""); if (activeChannel === "phone") dialog.close(); updateSubmitState();
            }
        });
        email.addEventListener("input", () => {
            const current = normalizeEmail();
            if ((verifiedEmail && current !== verifiedEmail) || (requestedEmail && current !== requestedEmail)) {
                verifiedEmail = ""; requestedEmail = ""; sendEmailButton.textContent = "Send OTP";
                setFieldStatus("email", ""); if (activeChannel === "email") dialog.close(); updateSubmitState();
            }
        });
        country.addEventListener("change", () => {
            verifiedPhone = ""; requestedPhone = ""; sendPhoneButton.textContent = "Send OTP";
            setFieldStatus("phone", ""); if (activeChannel === "phone") dialog.close(); updateSubmitState();
            updateCountry(); validate(country); validate(phone);
        });

        form.noValidate = true;
        controls.forEach(control => {
            control.addEventListener("blur", () => validate(control));
            control.addEventListener("input", () => { if (control.getAttribute("aria-invalid") === "true") validate(control); });
        });
        form.addEventListener("submit", event => {
            controls.forEach(control => { if (control.type !== "file") control.value = control.value.trim(); });
            const invalid = controls.filter(control => !validate(control));
            if (invalid.length) { event.preventDefault(); invalid[0].focus(); }
            else if (!verifiedEmail || verifiedEmail !== normalizeEmail()) {
                event.preventDefault(); setFieldStatus("email", "Verify your email address before sending your enquiry.", true); sendEmailButton.focus();
            } else if (!verifiedPhone || verifiedPhone !== normalizePhone()) {
                event.preventDefault(); setFieldStatus("phone", "Verify your mobile number before sending your enquiry.", true); sendPhoneButton.focus();
            }
        });
        updateCountry();
    });
})();
