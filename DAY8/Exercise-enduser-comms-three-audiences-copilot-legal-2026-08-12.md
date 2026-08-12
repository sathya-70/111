# End-User Communications — Copilot Incidents (Legal Team)
**Date:** 2026-08-12
**Relates to:** Exercise-copilot-incident-triage-legal-2026-08-12.md
**Incidents covered:** INC-01 through INC-05

---

## Audience 1 — Non-Technical Executive

**Subject: Brief update on Copilot issues in the Legal team — 12 August 2026**

Your team's data and access remain secure. We identified five separate Copilot issues affecting Legal this morning: one user could not access a document she did not have permission to view; a new joiner's account was not yet fully set up; one permission setting was found to be broader than intended and has been corrected; the Legal team's Copilot access was briefly disrupted and is being restored; and one user was receiving unhelpful responses due to a search configuration gap. All five are being resolved. No action is needed from you at this time; we will confirm when everything is back to normal.

---

## Audience 2 — Affected End-User Team (Legal Team)

**Subject: Copilot issues today — what happened and what to do**

Hi team,

This morning we received five separate reports of Copilot not working as expected across the Legal team. In short: some accounts weren't fully set up yet, a permission setting was too broad and has been fixed, the team's Copilot access was disrupted and is being restored, and a document library wasn't being read correctly by Copilot.

**If you're affected:**
- Can't access a document → raise an access request with the IT Service Desk.
- Copilot not working at all → please log a ticket; we're working on restoring access for everyone.
- Getting unhelpful answers → try opening the document directly in Word and using Copilot from there.

**Contact:** IT Service Desk — [your internal contact details here]

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Subject: INC-01 to INC-05 — Copilot Legal team incident batch — 2026-08-12**

---

### INC-01 — SharePoint Access Denied (Paralegal)

**Root cause:** User attempted to Copilot-summarise a SharePoint-hosted NDA in a folder she has never directly navigated to. Copilot respects SharePoint effective permissions; the user had no explicit or group-inherited Read grant on that document library. "Heard about it in a meeting" does not confer access.

**Action taken:** Directed user to attempt direct SharePoint navigation to confirm permissions state. Access request raised to document library owner via IT Service Desk.

**Config detail:** Copilot in M365 passes the signed-in user's identity token to Microsoft Search; Search enforces ACLs at query time — no permission bypass is possible by design.

**Verification step:** Once access is granted, allow 24–48 hours for permission sync to Microsoft Search index, then re-test Copilot summarisation on the file.

**Preventive action:** Ensure document libraries for sensitive matter files are provisioned with explicit, role-based access grants at onboarding rather than ad-hoc requests. Review SharePoint site provisioning template for Legal.

---

### INC-02 — Copilot in Outlook No Context (New Associate)

**Root cause:** User joined this week. Two compounding factors: (1) Copilot licence assignment propagation lag — group-based licence assignments can take up to 24 hours to fully provision; (2) Microsoft Search indexing of a new mailbox is progressive and incomplete for the first 24–72 hours.

**Action taken:** Confirmed Copilot licence is assigned to the user's account in M365 Admin Centre (Users > Active Users > Licences). Advised user to wait 24 hours and retry. Confirmed emails are in the primary mailbox, not a shared mailbox (Copilot in Outlook operates on primary mailbox only).

**Config detail:** Copilot licence SKU must be present and in `Success` provisioning state. Mailbox must be Exchange Online (not on-prem hybrid stub). Shared mailboxes are not supported for Copilot Outlook context.

**Verification step:** In M365 Admin > Users > Active Users > select user > Licences — confirm Microsoft 365 Copilot shows `Active`. Re-test after 24 hours. Use Microsoft Search Admin Centre to check indexing status if issue persists beyond 72 hours.

**Preventive action:** Add Copilot licence assignment to the standard joiner provisioning runbook with a 24-hour provisioning buffer noted. Include in new-joiner IT orientation that Copilot email context builds over the first few days.

---

### INC-03 — Oversharing: Copilot Surfaced Unauthorised Matter Content (Partner) ⚠️ CRITICAL / DATA INCIDENT

**Root cause:** A partner received a Copilot-generated summary of a draft settlement document from a matter she is not assigned to. Copilot surfaced this because she had implicit Read access — most likely via a broad security group grant (e.g., `Legal-All` or `Legal-Partners` group) applied to the matter's SharePoint document library. Copilot does not grant new access; it reflects existing effective permissions. The oversharing existed in SharePoint before Copilot made it visible.

**Action taken:**
1. Identified the source document and hosting SharePoint site/library via SharePoint Admin Centre > Active Sites > [matter site] > Permissions.
2. Checked effective permissions on the matter folder via SharePoint Admin Centre > Microsoft Purview — confirmed broad group grant was present.
3. Removed the overly permissive group assignment from the matter library, scoping access to matter-assigned users only.
4. Logged as a data incident per information security policy; escalated to Information Security and DPO for assessment.
5. Conducted sweep of other matter libraries in the same site collection for similar broad group grants.

**Config detail:** SharePoint permission inheritance was active on the matter folder, pulling in a department-wide `Legal-All` security group. This group had been added at the site collection level and inherited down. Purview sensitivity labels were not applied to matter documents — no label-based access control was in place.

**Verification step:**
- In SharePoint Admin Centre, re-check effective permissions on the matter library — `Legal-All` group should no longer appear.
- Run `Get-SPOSiteGroup` or use the SharePoint "Check Permissions" tool to confirm the partner's account no longer has access.
- Confirm with the partner that Copilot no longer surfaces the matter content.
- Await Information Security / DPO assessment outcome before closing.

**Preventive action:**
- Apply Microsoft Purview sensitivity labels to all matter document libraries — use label-based conditional access to enforce matter-scoped permissions.
- Review and restrict the scope of the `Legal-All` group; replace with matter-specific security groups provisioned at matter-opening.
- Implement a SharePoint permissions audit cadence (quarterly) for Legal matter libraries.
- Consider enabling Microsoft Purview Data Loss Prevention (DLP) policies scoped to legal matter content types.
- Do **not** close this as a standard support ticket — keep open as a tracked data incident until DPO sign-off.

---

### INC-04 — Full Legal Team Copilot Access Loss (40 Users)

**Root cause:** All 40 Legal team members lost Copilot access simultaneously. The simultaneous nature strongly indicates a group-based licence assignment change rather than individual account issues. Entra ID audit log confirmed a group licence assignment was modified — the Copilot licence was removed from the `Legal-CopilotUsers` security group.

**Action taken:**
1. Checked M365 Admin Centre > Billing > Licences — Copilot licence pool count was sufficient; no subscription expiry.
2. Pulled Entra ID audit log (last 24 hours): `AuditLogs > DirectoryManagement > Update group` — confirmed licence assignment change at [timestamp].
3. Reassigned the Microsoft 365 Copilot licence to the `Legal-CopilotUsers` group via Entra ID > Groups > [group] > Licences > Assign.
4. Confirmed M365 Service Health Dashboard showed no tenant-wide Copilot service incident.

**Config detail:** Group-based licence assignment via Entra ID security group `Legal-CopilotUsers`. Licence SKU: Microsoft 365 Copilot. Change made by [admin account — redact for external sharing]. Propagation time after reassignment: up to 1 hour.

**Verification step:**
- Monitor Entra ID group licence assignment status — should show `Active` with 0 errors.
- Ask 2–3 affected users to sign out and back in to Microsoft 365, then confirm Copilot is accessible in Teams, Outlook, and Word.
- Recheck after 1 hour if access is not restored.

**Preventive action:**
- Enable Entra ID Privileged Identity Management (PIM) or role-based change approvals for licence group modifications to prevent accidental removal.
- Set up a Microsoft 365 admin alert for licence assignment changes to the `Legal-CopilotUsers` group.
- Document the group name and assignment method in the Copilot service configuration record.

---

### INC-05 — Vague Copilot Responses for Contract Template Library (Contract Specialist)

**Root cause:** User was prompting Copilot from Microsoft Teams chat, asking about clauses in a SharePoint-hosted contract templates library. Copilot in Teams chat operates on grounded context from the conversation and explicitly referenced files — it does not automatically crawl an entire document library. Additionally, the contract templates library was confirmed as recently migrated (within the last week), so Microsoft Search indexing is likely incomplete.

**Action taken:**
1. Advised user to open the specific contract template directly in Word Online / desktop Word and use the Copilot pane within the document — this gives Copilot full document context.
2. Confirmed files are `.docx` format (not scanned PDFs or legacy `.doc`) — no format issue found.
3. Checked Microsoft Search Admin Centre — the SharePoint site is included in the crawl scope. Indexing progress for the migrated library is ongoing.
4. Advised user to allow 24–72 hours for full index completion and retry.

**Config detail:** Contract templates library on SharePoint Online, recently migrated. Microsoft Search crawl enabled on parent site. Files in `.docx` format. User was prompting via Teams chat without file reference — Copilot in this context uses retrieval-augmented generation (RAG) against the search index, which is incomplete post-migration.

**Verification step:**
- After 72 hours, user should retry from Teams chat using an explicit file @-mention or by opening the document in Word.
- In Microsoft Search Admin Centre > Content sources > SharePoint — check crawl status for the contract library site. Confirm `Last crawl` timestamp is recent and `Status` is `Success`.

**Preventive action:**
- After any SharePoint library migration, log a 72-hour indexing wait period before end-user Copilot use is expected to be functional.
- Add guidance to the Copilot user adoption materials: for document-specific queries, use Copilot *within* the document rather than from Teams chat.
- Include contract templates library in the next scheduled Microsoft Search crawl force-refresh post-migration.

---

*Document classification: INTERNAL — sanitised, no PII or live case data included.*
