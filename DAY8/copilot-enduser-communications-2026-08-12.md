# Copilot Support — End-User Communications
**Date:** 2026-08-12  
**Audience:** Individual users raising Copilot support tickets  
**Tone:** Plain English, non-technical, reassuring  

---

## Ticket 1 — Finance Lead: Can't summarise the Q3 board pack

**Hi,**

Thanks for getting in touch. We understand it's frustrating when you can clearly see a file but Copilot won't engage with it.

The most likely reason is that the Q3 board pack has a **sensitivity label** applied to it — for example, it may be marked as a restricted or confidential document. These labels are there to protect sensitive content, and as a result Copilot is prevented from reading or summarising it, even for users who have access to open the file themselves.

**What to do next:**

1. Check the top of the document in SharePoint — if you see a coloured banner or label (e.g. "Confidential" or "Official-Sensitive"), that is the likely cause.
2. If you believe Copilot should be able to access this document for legitimate business reasons, please raise this with your IT team or data owner so they can review the label classification.
3. If the label is correct, consider copying only the non-sensitive sections into a new document for Copilot to work with.

We will follow up once we have confirmed the root cause with the IT team.

---

## Ticket 2 — New Hire: Copilot doesn't know about recent emails

**Hi, and welcome to the team!**

Thanks for raising this. The good news is that what you're experiencing is completely normal for a new account and should resolve on its own shortly.

When a new Microsoft 365 account is created, it takes **between 24 and 72 hours** for your emails, calendar, and other content to be indexed and made available to Copilot. Until that process completes, Copilot won't be able to reference your recent messages.

**What to do next:**

1. Please allow up to 3 working days from your account creation date and try again.
2. If Copilot is still not working after 3 days, please contact the IT helpdesk so we can check that your Copilot licence has been correctly assigned.
3. In the meantime, you can still use Copilot for general tasks such as drafting emails, summarising text you paste in, or asking general questions.

Sorry for any inconvenience — this should sort itself out very soon.

---

## Ticket 3 — HR Manager: "I don't have access to that content" error on salary spreadsheet

**Hi,**

Thank you for reporting this. We can see why this is confusing, but the message you received is actually Copilot working as intended.

The salary review spreadsheet almost certainly has a **restricted sensitivity label** applied to it. These labels are applied to protect highly sensitive HR and financial data, and they instruct Copilot not to read or process that content — even for users who have permission to open the file directly.

This is a deliberate data protection measure, not a fault.

**What to do next:**

1. If you need to use Copilot to help draft or analyse salary-related content, please speak to your IT team or data owner about whether a lower-sensitivity working copy could be created for that purpose.
2. Do not attempt to remove or change the sensitivity label yourself — this must go through the correct approval process.
3. If you believe the label has been applied incorrectly, please raise a request with your data governance or information management team.

We appreciate your understanding — these controls exist to keep sensitive data safe.

---

## Ticket 4 — Sales Rep: Copilot can't find a contract shared via a guest link

**Hi,**

Thanks for getting in touch. We can confirm what you're experiencing is a known limitation rather than a fault.

The contract was shared with you via a **guest link from another organisation**. Copilot can only search and reference content that lives within our own organisation's Microsoft 365 environment. It cannot reach across into another company's systems, even when you have been given a link to their files.

This is a security boundary that exists to protect both organisations' data.

**What to do next:**

1. Ask the client or external party to send you a copy of the contract as an **email attachment** or to upload it directly to a shared location within our own organisation's SharePoint or Teams.
2. Once the file is stored in our environment, Copilot will be able to find and reference it.
3. If you regularly work with contracts from external partners, speak to your IT team about setting up a secure shared workspace within our tenant.

We're sorry for the inconvenience — we hope to have a working copy accessible to you soon.

---

## Ticket 5 — Finance Team: Copilot stopped working for everyone this morning

**Hi,**

Thank you for flagging this promptly. We take any wide-scale issue seriously and are investigating as a priority.

A sudden stop in access for an entire team can have several causes, including a change to licences, a security policy update applied overnight, or — less likely — a service issue on Microsoft's side.

**What is happening right now:**

Our IT team is actively investigating. We are checking:
- The Microsoft 365 Service Health dashboard for any reported incidents
- Whether any licence or policy changes were made overnight that may have affected the Finance team

**What you should do:**

1. Please avoid trying workarounds (such as reinstalling apps or changing settings) while we investigate, as this can make it harder to diagnose the root cause.
2. If you have urgent tasks that rely on Copilot, please let your manager know so they can reprioritise or arrange alternatives in the short term.
3. We will send an update within **2 hours** with our findings and an expected resolution time.

We apologise for the disruption and are working to resolve this as quickly as possible.

---

## Ticket 6 — Manager: Copilot found a file I don't remember opening

**Hi,**

Thank you for raising this — it's a really useful thing to flag and we're glad you did.

This is **not a fault**. Copilot is designed to search across all content that you have permission to access in Microsoft 365, not just files you have personally opened. Because you had access to that folder (even if you had forgotten about it), Copilot was able to find and summarise the file — just as if you had searched for it yourself in SharePoint.

In short: Copilot found it because you had access to it, and it was relevant to your query.

**What to do next:**

1. If you're concerned about having access to content you no longer need, you can ask your IT team or the relevant SharePoint site owner to review and remove your permissions.
2. If you think the folder contains content you should never have had access to, please let your IT team know so they can investigate.
3. No action is required on Copilot itself — it behaved correctly.

We hope this gives you peace of mind. Please feel free to reach out if you have further questions.

---

## Ticket 7 — Analyst: Copilot gives generic answers and ignores internal content

**Hi,**

Thanks for reporting this. If Copilot is giving you generic responses rather than drawing on our internal SharePoint content, there are two likely explanations.

The first is that you may not have been given access to the SharePoint sites that contain the content you are expecting Copilot to use. Copilot can only reference content you have permission to see. The second is that some SharePoint content, particularly recently created or migrated sites, can take time to be fully indexed and available to Copilot.

**What to do next:**

1. Try opening a specific internal SharePoint document directly in your browser. If you can open it, then ask Copilot about that exact document and see if it responds. This will help us tell whether it's an access issue or an indexing one.
2. If you cannot open the SharePoint sites you expect to use, request access from the site owner or your IT team.
3. If you can open the files but Copilot still can't reference them, please let the IT helpdesk know and we will investigate further.
4. If you have recently joined a new team or project, check with your manager that your SharePoint permissions have been fully set up.

We want to make sure Copilot is as useful as possible for you — please keep us updated on what you find.

---

## Ticket 8 — Executive Assistant: Copilot can't see the director's shared mailbox calendar

**Hi,**

Thank you for getting in touch. This is a known limitation with how Copilot currently handles shared mailboxes and delegate access, and we are sorry it's causing difficulty.

Copilot in Outlook works primarily with your own mailbox and calendar. Access to a shared mailbox or a calendar you manage on behalf of someone else is only available to Copilot if that shared mailbox has its own **Copilot licence** assigned. Without this, Copilot cannot see or interact with the shared mailbox content, even if you have full delegate access.

**What to do next:**

1. Please let the IT helpdesk know the name of the shared mailbox you manage. We will check whether a Copilot licence is in place.
2. If a licence is not assigned, we can raise a request to have one added — this will need to go through the standard licence approval process.
3. In the meantime, you can continue to manage the shared calendar directly in Outlook as normal; only the Copilot features are affected.

We will follow up once we have checked the licence status for that mailbox.

---

*These communications are drafted for IT helpdesk use. Personalise the greeting and ticket reference before sending. Do not include internal diagnostic details or system names in user-facing messages.*
