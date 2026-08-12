# Copilot — Legal Team Incident Triage & End-User Communications
**Date:** 2026-08-12 | **Team:** FinBridge Legal | **Raised by:** IT / Digital Workplace

---

## Severity Overview

| # | User | Summary | Severity | Root Cause Category |
|---|---|---|---|---|
| 1 | Paralegal | "I don't have access to that content" on client NDA | Low | Permissions — expected behaviour |
| 2 | New associate | Copilot can't find case emails | Low | Indexing lag — expected for new accounts |
| 3 | Partner | Copilot surfaced a matter file they're not assigned to | **HIGH** | **Data governance — overpermissioning** |
| 4 | Legal ops manager | All 40 Legal team users lost Copilot access | **HIGH** | Licence or policy change — service impact |
| 5 | Contract specialist | Vague answers about contract template clauses | Medium | Indexing or file format issue |

> **Action before anything else:** Ticket 3 is a data governance incident. Treat it separately and escalate immediately — see triage notes below.

---

---

## Ticket 1 — Paralegal: "I don't have access to that content" (SharePoint NDA)

### Triage — Engineer Notes

| Field | Detail |
|---|---|
| **Reported symptom** | Copilot returned "I don't have access to that content" when asked to summarise a client NDA stored in SharePoint. The paralegal has never opened the folder — she heard about the file in a meeting. |
| **Most likely cause** | Permissions gap. Copilot reflects the user's actual SharePoint permissions via Microsoft Graph. "Heard about a folder in a meeting" does not equal having been granted access to it. She almost certainly does not have read access to that library or folder, so Copilot correctly returns nothing. |
| **Is this a Copilot bug?** | No. This is expected behaviour — Copilot will not surface content the user cannot already access. |
| **Severity** | Low — single user, no data risk, standard permissions request resolution. |

**Triage steps:**
1. Ask the paralegal for the SharePoint URL or site name of the NDA location.
2. In SharePoint admin (or the site's permission settings), check whether her account has any access to that document library or folder.
3. If she has no access: direct her to raise a formal access request through the matter partner or DMS admin — this is a normal workflow, not an IT fault.
4. If she does have access and Copilot still fails: check whether the file has a sensitivity label applied that restricts Copilot grounding, and whether the file has been indexed (newly uploaded files can take up to 24 hours to index).
5. Close as permissions issue / user guidance.

---

### End-User Communication — Paralegal

> **To:** [Paralegal name]
> **From:** IT Helpdesk
> **Subject:** RE: Copilot — NDA access issue
>
> Hi [name],
>
> Thanks for getting in touch. We've looked into this and the good news is that Copilot is working exactly as it should.
>
> Copilot can only work with documents you already have permission to open. In this case, it looks like your account hasn't been added to the access list for that particular folder yet — so Copilot can't reach it, just as you'd get an "Access Denied" message if you tried to open the file directly.
>
> **Next step:** Contact [matter partner / DMS admin] to request access to the NDA folder through the usual channel. Once access is granted and the file has been indexed (usually within 24 hours), Copilot should be able to summarise it for you without any issues.
>
> Let us know if you have any other questions.
>
> IT Helpdesk

---
---

## Ticket 2 — New Associate: Copilot can't find case emails

### Triage — Engineer Notes

| Field | Detail |
|---|---|
| **Reported symptom** | New associate (started this week) reports that Copilot in Outlook can't find or provide context on case emails. |
| **Most likely cause** | Mailbox indexing lag. Microsoft 365's semantic index needs 24–72 hours after account provisioning before Copilot can meaningfully ground on a user's mailbox content. A brand-new account will appear almost empty to Copilot during this window. Secondary possibility: the emails they need are not in their own mailbox — they may be in a shared mailbox or a colleague's inbox, which Copilot cannot access on their behalf. |
| **Is this a Copilot bug?** | No. This is documented, expected behaviour for new accounts. |
| **Severity** | Low — self-resolving within a few days. |

**Triage steps:**
1. Confirm the account creation date and that the Copilot licence was assigned at provisioning (M365 admin centre → Users → Licences).
2. If the account is less than 72 hours old: no action needed — advise the user to try again in 1–2 working days.
3. If the account is older than 72 hours and the issue persists: check M365 admin centre → Search & Intelligence → Content Sources for any indexing errors on the mailbox.
4. Clarify with the associate whether they mean emails in their own inbox, or case emails held in a shared mailbox or colleague's mailbox — Copilot cannot access those without explicit delegation and licensing on the shared mailbox.
5. If indexing appears stuck beyond 72 hours, raise with Microsoft via the M365 admin support portal.

---

### End-User Communication — New Associate

> **To:** [Associate name]
> **From:** IT Helpdesk
> **Subject:** RE: Copilot not finding emails
>
> Hi [name],
>
> Welcome to FinBridge — thanks for flagging this.
>
> This is completely normal for a new account. When a mailbox is brand new, Microsoft 365 needs a couple of days to index all the content before Copilot can work with it. Think of it like a new filing system that needs to be catalogued before you can search it.
>
> **What to expect:** Copilot should have full access to your emails within 1–2 working days. If you're still seeing the same issue by [date — 2 working days from today], please reply to this message and we'll investigate further.
>
> In the meantime, Outlook's built-in search works straight away if you need to find something urgently.
>
> One other thing worth checking: if the case emails you need are sitting in a shared team mailbox rather than your personal inbox, let us know — that's a slightly different setup and we can advise.
>
> IT Helpdesk

---
---

## Ticket 3 — Partner: Copilot surfaced a matter file they're not assigned to

### ⚠ DATA GOVERNANCE INCIDENT — ESCALATE IMMEDIATELY

### Triage — Engineer Notes

| Field | Detail |
|---|---|
| **Reported symptom** | A partner reports that Copilot surfaced and summarised a draft settlement document from a matter they are not assigned to and did not know they could access. |
| **Most likely cause** | **Overpermissioning in SharePoint/DMS.** Copilot only surfaces content the user already has permission to read via Microsoft Graph. If Copilot could summarise this document, the partner had pre-existing read access to that file or its parent site — whether they knew it or not. This is not a Copilot bug. Copilot has made a latent permissions problem visible. |
| **Is this a Copilot bug?** | No. Copilot is working correctly. The underlying access control structure is the problem. |
| **Severity** | **HIGH** — potential legal professional privilege concern, regulatory risk (SRA obligations), and client confidentiality breach depending on the content of the draft settlement. Treat as a data governance incident. |

**Triage steps — treat as incident, not a standard support ticket:**
1. **Immediately** identify the exact file (ask the partner for the document name and any details they recall — do not ask them to share or forward the content).
2. Locate the file in SharePoint/DMS and audit who currently has read access to that site, library, and folder.
3. Determine how the partner gained access — direct grant, inherited from a broad site membership, or via a group they shouldn't be in.
4. **Restrict access** to the settlement document and its parent folder immediately if it is confirmed as overpermissioned. Do not wait for a change window.
5. Check whether other users who are not assigned to that matter have the same access path.
6. Log the incident with the Information Governance / Data Protection lead and Compliance team — this may require notification under internal breach procedures.
7. Preserve the Entra and SharePoint audit logs covering this event before they age out (default retention varies; do not delay).
8. Do not close this ticket until Compliance / IG has reviewed and signed off.

**Do not communicate this to the wider team as a routine Copilot issue.**

---

### End-User Communication — Partner

> **To:** [Partner name]
> **From:** IT Helpdesk / [IT Manager name]
> **Subject:** RE: Copilot — unexpected document access
>
> Dear [name],
>
> Thank you for reporting this straight away — that was exactly the right thing to do.
>
> To reassure you: you have not done anything wrong, and Copilot has not malfunctioned. What has happened is that Copilot showed you content your account already had permission to access — it works entirely within your existing access rights. The issue is that your account appears to have access to a matter folder it should not, which is something we need to investigate and correct on the permissions side.
>
> We are treating this as a priority. We will be reviewing the access controls on that document and conducting a broader check to make sure matter files are only accessible to the right people.
>
> **In the meantime, please:**
> - Do not share, copy, or act on the content of the document you saw
> - Keep this matter confidential until we have completed our review
>
> We will come back to you directly with an update. If you have any questions in the meantime, please contact [IT Manager / IG lead] directly rather than raising a new ticket.
>
> Thank you again for flagging this promptly.
>
> [IT Manager name] | IT / Digital Workplace

---
---

## Ticket 4 — Legal ops manager: All 40 Legal team users lost Copilot access

### Triage — Engineer Notes

| Field | Detail |
|---|---|
| **Reported symptom** | All 40 members of the Legal team lost Copilot access this morning. It was working normally last week. |
| **Most likely cause** | Licence assignment change. The most common cause of a sudden team-wide loss of access is that the Legal team's Azure AD / Entra group has been removed from the Copilot licence assignment — either by an admin action, an automated licence management policy, or a bulk reallocation. Second possibility: a Conditional Access policy or tenant-level Copilot policy was updated overnight. Third: an active Microsoft service incident. |
| **Is this a Copilot bug?** | Possible, but unlikely given the clean cutover. Licence or policy change is far more probable. |
| **Severity** | **HIGH** — 40 users affected, active business impact, legal team productivity blocked. |

**Triage steps — treat as priority 1:**
1. **First check (5 minutes):** M365 admin centre → Service Health → check for any active Copilot or Microsoft 365 incidents. If there is an active service incident, pause other investigation and communicate the status page link to the legal ops manager.
2. M365 admin centre → Billing → Licences → confirm how many Copilot licences are assigned and to which groups/users. Compare against the expected count.
3. Entra ID (Azure AD) → Audit logs → filter by last 48 hours → look for licence assignment changes, group membership changes, or policy updates affecting the Legal team group.
4. Check whether the Legal team's Entra group still exists and still has Copilot licence assignment — a group rename or restructure can silently break licence inheritance.
5. If a licence change is confirmed: restore the group licence assignment and test with one user before confirming resolution to the team.
6. If no licence or policy change is found and no service incident is active: raise with Microsoft support via the M365 admin portal, providing the tenant ID and approximate time of failure onset.
7. Update the legal ops manager every 30 minutes until resolved.

---

### End-User Communication — Legal Team (via Legal Ops Manager)

> **To:** [Legal ops manager] — please forward to the Legal team
> **From:** IT Helpdesk
> **Subject:** Copilot access — known issue under investigation
>
> Hi [name],
>
> We are aware that Copilot access has stopped working for the Legal team this morning and we are investigating this as a priority right now.
>
> We will send an update within the next 30 minutes with either a fix or a confirmed timeline for resolution.
>
> **No action is needed from anyone on the team.** If Copilot is unavailable, please use the standard Outlook, Word, and Teams features in the meantime — all other M365 tools are unaffected.
>
> We will keep you updated.
>
> IT Helpdesk

---

> **Follow-up once resolved:**
>
> Hi [name],
>
> Copilot access has been restored for the Legal team as of [time]. The issue was caused by [brief, non-technical explanation — e.g. "a change to the team's account settings that we have now corrected"].
>
> Please ask anyone who is still seeing a problem to sign out of Microsoft 365 and sign back in, which should pick up the fix. If issues continue after that, contact the helpdesk directly.
>
> Apologies for the disruption this morning.
>
> IT Helpdesk

---
---

## Ticket 5 — Contract Specialist: Vague answers about contract template clauses

### Triage — Engineer Notes

| Field | Detail |
|---|---|
| **Reported symptom** | Copilot gives vague, generic answers when asked about clauses in the contract templates library. It doesn't seem to be reading the actual documents. |
| **Most likely cause** | One of three possibilities: (1) The SharePoint library containing the templates is not being indexed by Microsoft Search — recently created or migrated libraries can be excluded from crawling. (2) The template files are image-based or scanned PDFs rather than text-based documents — Copilot cannot read image content. (3) The specialist is asking Copilot a general question without having the document open, so Copilot falls back on general knowledge rather than grounding on the file. |
| **Is this a Copilot bug?** | No. This is a content indexing / file format / usage pattern issue. |
| **Severity** | Medium — functional gap affecting at least one user, likely others. Resolving the indexing issue (if confirmed) benefits the whole team. |

**Triage steps:**
1. Ask the specialist to open one of the contract template files directly in Word or the browser, then ask Copilot to summarise it or answer a question about a specific clause. If this works, the issue is that Copilot needs the document open as context — advise the user on correct workflow (see end-user communication below).
2. If step 1 also fails: check whether the contract templates library appears in Microsoft Search results. Go to search.microsoft.com and search for a term from one of the templates — if the documents don't surface, the library is likely not indexed.
3. M365 admin centre → Search & Intelligence → Content Sources — check whether the SharePoint site hosting the templates is included and whether the last crawl completed successfully.
4. Check the file formats: open one template and confirm it is a native Word (.docx) or text-based PDF. If templates are image scans or older formats (.doc pre-2007), Copilot cannot extract text from them.
5. If indexing is the issue: ensure the site is not excluded from crawling, trigger a manual re-crawl, and retest after 24 hours.
6. If file format is the issue: advise the legal ops manager that templates need to be saved as .docx or text-layer PDF for Copilot to work with them.

---

### End-User Communication — Contract Specialist

> **To:** [Contract specialist name]
> **From:** IT Helpdesk
> **Subject:** RE: Copilot — contract template queries
>
> Hi [name],
>
> Thanks for raising this — we've looked into it and there are a couple of things going on.
>
> **Quick fix you can use right now:**
> The most reliable way to get Copilot to answer questions about a specific contract is to open the document first, then ask Copilot. When a document is open in Word, Copilot can see exactly what's in it and give you precise answers about clauses, terms, and wording.
>
> Try this: open the contract template you need, then in the Copilot pane type something like: *"Summarise the termination clause in this document"* or *"What does this contract say about liability limits?"*
>
> **What we're also checking in the background:**
> We're looking at whether all the templates in the library are fully set up for Copilot to search across. We'll let you know if there's anything we need to update at our end, and if we do make changes we'll drop you a note so you can retest.
>
> In the meantime, the open-the-document-first approach should give you much better results straight away.
>
> Let us know how you get on.
>
> IT Helpdesk

---

---

## Engineer Checklist — Before Closing Any of These Tickets

- [ ] Ticket 3 reviewed and signed off by Information Governance / Compliance — **do not close without this**
- [ ] Ticket 4 root cause confirmed and documented (licence change, policy change, or service incident reference number)
- [ ] Ticket 5 indexing / file format root cause identified and remediated or accepted as user guidance
- [ ] All end-user communications sent and replies reviewed
- [ ] No PII, credentials, or client data recorded in this triage document

---

*Document produced by FinBridge IT / Digital Workplace — for internal engineer use only. Do not share with end users.*
