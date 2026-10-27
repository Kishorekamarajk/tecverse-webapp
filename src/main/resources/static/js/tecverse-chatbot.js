(function initTecVerseAssistant() {
    "use strict";

    var TECVERSE_WHATSAPP_NUMBER = "919445128289"; // Tec-Verse WhatsApp number for support
    var TECVERSE_WHATSAPP_DEFAULT_MESSAGE = "Welcome to Tec-Verse 2026! How can we assist you?";
    var scriptSrc = document.currentScript && document.currentScript.src ? document.currentScript.src : "";
    var appBaseUrl = scriptSrc.replace(/\/js\/tecverse-chatbot\.js(?:\?.*)?$/, "");
    var chatbotFaqUrl = appBaseUrl + "/api/chatbot/faqs";
    var fallbackAnswer = "I'm sorry, I don't have that information yet. Please contact the Tec-Verse support team for assistance.";

    var quickQuestions = [
        "What is Tec-Verse?",
        "How to register?",
        "How to login?",
        "How to participate in the exhibition?",
        "What are the available categories?",
        "How can companies register?",
        "What are the event dates?",
        "How can I contact Tec-Verse?",
        "How can I become an exhibitor?"
    ];

    var tecverseFaqs = [
        {
            key: "what is tecverse",
            phrases: ["what is tecverse", "what is techverse", "about tecverse", "about techverse", "tell me about tecverse"],
            keywords: ["what", "tecverse"],
            answer: "Tec-Verse 2026 is a flagship technology event bringing together innovators, industry leaders, researchers, startups, institutions, academia, government organizations, industry experts, and policymakers to explore emerging technologies and digital solutions."
        },
        {
            key: "how to register",
            phrases: ["how to register", "how do i register", "how can i register", "registration process", "register for tecverse"],
            keywords: ["register"],
            answer: "Use the Register option in the site navigation to open the exhibitor registration form. Complete the company, contact, and exhibition details, then submit the application. After successful submission, the Tec-Verse team will review it and contact you."
        },
        {
            key: "how to login",
            phrases: ["how to login", "how do i login", "login", "sign in", "signin"],
            keywords: ["login"],
            answer: "I don't see login instructions in the current Tec-Verse portal content. Please contact the Tec-Verse support team for assistance."
        },
        {
            key: "participate exhibition",
            phrases: ["how to participate in the exhibition", "participate in exhibition", "join exhibition", "exhibition participation", "exhibit at tecverse"],
            keywords: ["participate", "exhibition"],
            answer: "Organizations can participate by registering as exhibitors. Exhibitors can showcase products, demonstrate solutions, meet decision-makers, build partnerships, and gain visibility among a focused technology audience."
        },
        {
            key: "available categories",
            phrases: ["what are the available categories", "available categories", "technology areas", "thematic areas", "industries"],
            keywords: ["categories"],
            answer: "Expected sectors include IT, electronics, AI, cybersecurity, smart infrastructure, manufacturing, education, healthcare, public services, and deep-tech startups. The portal also highlights participation options such as visitor registration, exhibition stalls, sponsorship, speaker participation, startup showcases, and institutional collaboration."
        },
        {
            key: "companies register",
            phrases: ["how can companies register", "company registration", "companies register", "register company"],
            keywords: ["company", "register"],
            answer: "Companies can use the exhibitor registration form and provide company details, contact information, and exhibition requirements. The form includes fields such as company name, industry, city, country, company size, contact person, stall package, technology area, power requirement, and products or services."
        },
        {
            key: "event dates",
            phrases: ["what are the event dates", "event dates", "when is tecverse", "when and where", "date"],
            keywords: ["date"],
            answer: "The home page badge lists Tec-Verse as 26-27 NOV 2026. Other date, entry, and schedule details should be confirmed from the official updates or support team."
        },
        {
            key: "contact",
            phrases: ["how can i contact tecverse", "contact tecverse", "contact support", "help desk", "support team"],
            keywords: ["contact"],
            answer: "Use the Contact Us page from the Tec-Verse navigation for participation, sponsorship, exhibition, and event support queries."
        },
        {
            key: "become exhibitor",
            phrases: ["how can i become an exhibitor", "become an exhibitor", "exhibitor registration", "book stall", "stall registration"],
            keywords: ["exhibitor"],
            answer: "Open the Register page to apply as an exhibitor. The application asks for company information, contact information, and exhibition details. After submission, the Tec-Verse team will review your application and contact you."
        },
        {
            key: "sponsor",
            phrases: ["become sponsor", "sponsorship", "sponsor tecverse", "how to sponsor"],
            keywords: ["sponsor"],
            answer: "Use the Become Sponsor option in the navigation to send a sponsorship enquiry. The Tec-Verse team will follow up with the relevant details."
        },
        {
            key: "venue",
            phrases: ["venue", "where is tecverse", "location", "chennai trade centre"],
            keywords: ["venue"],
            answer: "The portal lists Chennai Trade Centre in Nandambakkam as the venue section location. Please confirm final venue and access details through official Tec-Verse updates or the support team."
        }
    ];

    function ready(callback) {
        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", callback);
        } else {
            callback();
        }
    }

    function normalize(text) {
        return String(text || "")
            .toLowerCase()
            .replace(/[^a-z0-9\s]/g, " ")
            .replace(/\s+/g, " ")
            .trim();
    }

    function uniqueWords(text) {
        var ignoredWords = {
            a: true,
            an: true,
            and: true,
            are: true,
            can: true,
            for: true,
            how: true,
            is: true,
            me: true,
            of: true,
            on: true,
            the: true,
            to: true,
            what: true,
            when: true,
            where: true,
            who: true,
            why: true,
            with: true,
            you: true
        };

        return normalize(text)
            .split(" ")
            .filter(function (word, index, words) {
                return word.length > 2 && !ignoredWords[word] && words.indexOf(word) === index;
            });
    }

    function createFaqEntry(row) {
        var question = String(row && row.question ? row.question : "").trim();
        var answer = String(row && row.answer ? row.answer : "").trim();

        if (!question || !answer) {
            return null;
        }

        return {
            key: normalize(question),
            phrases: [question],
            keywords: uniqueWords(question + " " + (row.category || "")),
            answer: answer
        };
    }

    function loadFaqsFromWorkbook() {
        if (!window.fetch) {
            return Promise.resolve([]);
        }

        return fetch(chatbotFaqUrl, {
            headers: {
                Accept: "application/json"
            }
        })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error("Chatbot FAQ request failed");
                }
                return response.json();
            })
            .then(function (body) {
                var rows = Array.isArray(body) ? body : body && Array.isArray(body.data) ? body.data : [];
                var loadedFaqs = rows.map(createFaqEntry).filter(Boolean);

                if (loadedFaqs.length) {
                    tecverseFaqs = loadedFaqs;
                }

                return loadedFaqs.map(function (faq) {
                    return faq.phrases[0];
                });
            })
            .catch(function () {
                return [];
            });
    }

    function formatTime() {
        return new Intl.DateTimeFormat([], {
            hour: "numeric",
            minute: "2-digit"
        }).format(new Date());
    }

    function createElement(tagName, className, text) {
        var element = document.createElement(tagName);
        if (className) {
            element.className = className;
        }
        if (text) {
            element.textContent = text;
        }
        return element;
    }

    function findAnswer(question) {
        var normalizedQuestion = normalize(question);
        var words = normalizedQuestion.split(" ").filter(Boolean);
        var bestMatch = null;
        var bestScore = 0;

        tecverseFaqs.forEach(function (faq) {
            var score = 0;

            faq.phrases.forEach(function (phrase) {
                if (normalizedQuestion.indexOf(normalize(phrase)) !== -1) {
                    score += 8;
                }
            });

            faq.keywords.forEach(function (keyword) {
                if (words.indexOf(normalize(keyword)) !== -1) {
                    score += 3;
                }
            });

            words.forEach(function (word) {
                if (word.length > 2 && faq.keywords.indexOf(word) !== -1) {
                    score += 1;
                }
            });

            if (normalizedQuestion.indexOf(faq.key) !== -1) {
                score += 5;
            }

            if (score > bestScore) {
                bestScore = score;
                bestMatch = faq;
            }
        });

        return bestScore >= 3 && bestMatch ? bestMatch.answer : fallbackAnswer;
    }

    ready(function () {
        var chatbot = document.querySelector("[data-tecverse-chatbot]");
        var openButton = document.querySelector("[data-tecverse-chatbot-open]");
        var closeButton = document.querySelector("[data-tecverse-chatbot-close]");
        var messages = document.querySelector("[data-tecverse-chatbot-messages]");
        var quickQuestionsWrap = document.querySelector("[data-tecverse-quick-questions]");
        var form = document.querySelector("[data-tecverse-chatbot-form]");
        var input = document.querySelector("[data-tecverse-chatbot-input]");
        var whatsAppLink = document.querySelector("[data-tecverse-whatsapp-link]");
        var typingTimer = null;

        if (!chatbot || !openButton || !closeButton || !messages || !quickQuestionsWrap || !form || !input) {
            return;
        }

        if (whatsAppLink) {
            whatsAppLink.href = "https://wa.me/" + TECVERSE_WHATSAPP_NUMBER
                + "?text=" + encodeURIComponent(TECVERSE_WHATSAPP_DEFAULT_MESSAGE);
        }

        function scrollToLatest() {
            messages.scrollTop = messages.scrollHeight;
        }

        function addMessage(text, sender) {
            var message = createElement("div", "tecverse-chatbot__message d-flex flex-column " + (sender === "user" ? "align-self-end align-items-end" : "align-self-start align-items-start") + " tecverse-chatbot__message--" + sender);
            var bubble = createElement("div", "tecverse-chatbot__bubble", text);
            var time = createElement("time", "tecverse-chatbot__time", formatTime());

            time.setAttribute("datetime", new Date().toISOString());
            message.appendChild(bubble);
            message.appendChild(time);
            messages.appendChild(message);
            scrollToLatest();

            return message;
        }

        function showTypingIndicator() {
            var message = createElement("div", "tecverse-chatbot__message tecverse-chatbot__message--assistant d-flex flex-column align-self-start align-items-start");
            var bubble = createElement("div", "tecverse-chatbot__bubble");
            var typing = createElement("span", "tecverse-chatbot__typing d-inline-flex align-items-center gap-1");

            typing.setAttribute("aria-label", "Tec-Verse Assistant is typing");
            typing.appendChild(createElement("span", "rounded-circle"));
            typing.appendChild(createElement("span", "rounded-circle"));
            typing.appendChild(createElement("span", "rounded-circle"));
            bubble.appendChild(typing);
            message.appendChild(bubble);
            messages.appendChild(message);
            scrollToLatest();

            return message;
        }

        function respondTo(question) {
            var typingIndicator = showTypingIndicator();

            window.clearTimeout(typingTimer);
            typingTimer = window.setTimeout(function () {
                typingIndicator.remove();
                addMessage(findAnswer(question), "assistant");
            }, 520);
        }

        function handleQuestion(question) {
            var trimmedQuestion = String(question || "").trim();
            if (!trimmedQuestion) {
                input.focus();
                return;
            }

            addMessage(trimmedQuestion, "user");
            input.value = "";
            respondTo(trimmedQuestion);
        }

        function openChatbot() {
            chatbot.classList.add("is-open");
            chatbot.setAttribute("aria-hidden", "false");
            openButton.setAttribute("aria-expanded", "true");
            window.setTimeout(function () {
                input.focus();
                scrollToLatest();
            }, 180);
        }

        function closeChatbot() {
            chatbot.classList.remove("is-open");
            chatbot.setAttribute("aria-hidden", "true");
            openButton.setAttribute("aria-expanded", "false");
            openButton.focus();
        }

        function renderQuickQuestions(questions) {
            quickQuestionsWrap.innerHTML = "";
            questions.slice(0, 9).forEach(function (question) {
                var button = createElement("button", "tecverse-chatbot__quick-button btn rounded-pill", question);
                button.type = "button";
                button.addEventListener("click", function () {
                    handleQuestion(question);
                });
                quickQuestionsWrap.appendChild(button);
            });
        }

        loadFaqsFromWorkbook().then(function (loadedQuestions) {
            renderQuickQuestions(loadedQuestions.length ? loadedQuestions : quickQuestions);
        });

        addMessage("Welcome to Tec-Verse support. You can type your question below or tap a quick question to get instant help.", "assistant");

        openButton.addEventListener("click", function () {
            if (chatbot.classList.contains("is-open")) {
                closeChatbot();
                return;
            }

            openChatbot();
        });
        closeButton.addEventListener("click", closeChatbot);

        form.addEventListener("submit", function (event) {
            event.preventDefault();
            handleQuestion(input.value);
        });

        document.addEventListener("keydown", function (event) {
            if (event.key === "Escape" && chatbot.classList.contains("is-open")) {
                closeChatbot();
            }
        });
    });
})();
