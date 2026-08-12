# Copilot Incident Triage — Legal Team
**Date:** 2026-08-12
**Raised by:** DWP Engineer
**Scope:** Microsoft 365 Copilot — Legal department

---

## Incident Summary Table

| # | Reported By | Description | Category | Priority |
|---|-------------|-------------|----------|----------|
| 1 | Paralegal | Cannot summarise a client NDA in SharePoint — "I don't have access to that content." | Access / Permissions | Medium |
| 2 | New Associate | Copilot in Outlook cannot find case emails needed for context | Onboarding / Licensing | Medium |
| 3 | Partner | Copilot surfaced and summarised a draft settlement from a matter she is not assigned to | **Security / Oversharing** | **Critical** |
| 4 | Legal Ops Manager | All 40 Legal team members lost Copilot access simultaneously | Service Outage | **High** |
| 5 | Contract Specialist | Copilot returns vague, generic answers about contract template clauses — does not read documents | Search / Indexing | Low–Medium |

---

## Incident Detail & Triage

---

### INC-01 — Paralegal: SharePoint NDA Access Denied

**Symptom:** Copilot returns "I don't have access to that content" when asked to summarise a NDA stored in SharePoint.

**Root Cause (likely):**
- The user has never opened or navigated to the folder directly; SharePoint permissions are not inherited from awareness of a file — the user must have explicit or inherited Read access.
- Copilot respects SharePoint permissions; it cannot surface content the signed-in user cannot access.

**Triage Steps:**
1. Ask the user to navigate directly to the SharePoint folder and confirm whether she can open the file manually.
2. If access is denied in SharePoint, raise an access request to the SharePoint site owner or document library owner.
3. If access is granted in SharePoint but Copilot still fails, allow 24–48 hours for the Microsoft Search index to sync permissions, then retry.
4. Confirm the file is not in a Personal (OneDrive) location of another user.

**Resolution Path:** SharePoint permissions request via IT Service Desk or site owner.
**Owner:** Site Owner / IT Support

---

### INC-02 — New Associate: Copilot in Outlook Cannot Find Case Emails

**Symptom:** Newly onboarded user (started this week) reports Copilot in Outlook has no context on case emails.

**Root Cause (likely):**
- Microsoft 365 Copilot licence may not yet be assigned or has not fully provisioned (licence propagation can take up to 24 hours).
- Microsoft Search indexing of the new mailbox may be incomplete — new mailboxes are indexed progressively.
- Emails may be stored in a shared mailbox or delegated folder the user does not have an active licence for.

**Triage Steps:**
1. Confirm a Copilot licence is assigned to the user account in Microsoft 365 Admin Centre (Users > Active Users > Licences).
2. Check provisioning status — if licence was assigned within the last 24 hours, advise the user to wait and retry.
3. Confirm the emails are in the user's own mailbox (not a shared mailbox) and that the mailbox has been active long enough to be indexed.
4. If emails are in a shared mailbox, note that Copilot in Outlook operates on the primary user's mailbox only.

**Resolution Path:** Licence check and mailbox indexing wait period.
**Owner:** IT Support / M365 Admin

---

### INC-03 — Partner: Copilot Surfaced Unauthorised Matter Content ⚠️ CRITICAL

**Symptom:** A partner received a Copilot-generated summary of a draft settlement document from a matter she is not assigned to and had not knowingly accessed.

**Classification:** **Potential data oversharing / permissions misconfiguration — treat as a security incident.**

**Root Cause (likely):**
- The SharePoint site or document library hosting the matter folder has overly permissive access (e.g., broad "Everyone in organisation" or "All Legal Team" sharing).
- Copilot surfaces any content the signed-in user technically has read access to, even if they were not the intended audience.
- The user may have inherited access through a group membership she is unaware of (e.g., a department-wide security group).

**Triage Steps:**
1. **Immediately** identify the document that was surfaced and the site/library it resides in.
2. Review SharePoint sharing settings and permission inheritance for the matter folder — check for broad group grants.
3. Check Microsoft Purview / SharePoint Admin Centre for the file's effective permissions.
4. Remove any unintended permissions without disrupting active matter users.
5. Log as a potential data incident per the firm's information security policy; escalate to Information Security / DPO if client confidential data was exposed.
6. Review whether other matters in the same library have similar oversharing.
7. Consider enabling Microsoft Purview sensitivity labels and access controls on matter libraries.

**Resolution Path:** Emergency permissions review + security incident log.
**Owner:** Information Security / SharePoint Admin — **escalate immediately**

---

### INC-04 — Legal Ops Manager: All 40 Legal Team Members Lost Copilot Access

**Symptom:** Entire Legal team (40 users) lost Copilot access simultaneously this morning; working fine last week.

**Root Cause (likely):**
- A Copilot licence assignment was removed from a security group or directly from a licence plan.
- A group-based licence assignment policy was modified or the group membership changed.
- A tenant-level admin policy change disabled Copilot for a specific department.
- Licence subscription expiry or billing issue (less likely if other tenants are unaffected).

**Triage Steps:**
1. Check Microsoft 365 Admin Centre > Billing > Licences — confirm Copilot licences are still active and the count matches expectation.
2. Check if a group-based licence assignment was recently modified (Admin Centre > Groups or Azure AD / Entra ID > Groups > Licence assignments).
3. Review the M365 Message Centre and Service Health Dashboard for any Copilot service incidents.
4. Check the Entra ID audit log for any licence or group membership changes made in the last 24 hours.
5. If a group assignment was accidentally removed, reassign the licence to the group; allow up to 1 hour for propagation.
6. Confirm whether the Legal Ops Manager themselves has access (to determine if it is truly all 40 or a subset).

**Resolution Path:** Restore group-based licence assignment or investigate tenant policy change.
**Owner:** M365 Admin / IT Operations

---

### INC-05 — Contract Specialist: Vague Answers About Contract Template Clauses

**Symptom:** Copilot returns generic answers about clauses in a contract templates library and does not appear to read the actual documents.

**Root Cause (likely):**
- The SharePoint library hosting the contract templates has not been fully indexed by Microsoft Search (new library, recently moved, or index lag).
- The documents may be in a format not fully supported for Copilot semantic search (e.g., heavily image-based PDFs, password-protected files, legacy `.doc` format).
- The user is prompting in a context where Copilot cannot see the documents (e.g., prompting in Teams chat rather than within the document or using Copilot in Word on the file directly).
- The library may be excluded from Microsoft Search crawl.

**Triage Steps:**
1. Ask the user to open a specific contract template in Word/SharePoint and use Copilot *within* that document (via the Copilot pane in Word or the SharePoint document view).
2. Confirm the files are in `.docx` or `.pdf` (text-based) format, not scanned images or protected PDFs.
3. Check Microsoft Search Admin Centre — confirm the SharePoint site is included in the search scope.
4. If the library is new or was recently migrated, allow 24–72 hours for full indexing and retry.
5. Advise the user to use specific prompts that reference file names or paste a short excerpt to give Copilot grounding context.

**Resolution Path:** Indexing wait / format check / direct document-level Copilot usage.
**Owner:** IT Support / M365 Admin

---

## Priority Summary & Next Actions

| Priority | Incident | Immediate Action |
|----------|----------|-----------------|
| Critical | INC-03 — Oversharing (Partner) | Escalate to Information Security now; review & remediate SharePoint permissions |
| High | INC-04 — Full team outage (Legal Ops) | Check M365 licence assignments and Entra ID audit log immediately |
| Medium | INC-01 — NDA access denied (Paralegal) | Raise SharePoint access request |
| Medium | INC-02 — Outlook Copilot (New Associate) | Verify licence assignment; await indexing |
| Low–Medium | INC-05 — Vague answers (Contract Specialist) | Open file directly in Word; check index and file format |

---

## Notes for Engineer

- INC-03 must be treated as a **data incident** until permissions are confirmed clean — do not close as a standard support ticket.
- INC-04 suggests a change was made in the admin plane; check the **Entra ID audit log** (last 24 hours) as first step.
- For INC-01 and INC-05, remind users that Copilot strictly respects M365 permissions — it cannot access content the user cannot access directly.
- Copilot does not grant new access; it surfaces content the user already has permission to view. Oversharing in SharePoint will always be reflected in Copilot output (INC-03).

---

*Document classification: INTERNAL — sanitised, no PII or live case data included.*
