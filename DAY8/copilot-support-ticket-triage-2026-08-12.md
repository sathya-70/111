# Copilot Support Ticket Triage
**Date:** 2026-08-12  
**Engineer:** DWP Desktop/Endpoint  

---

## Ticket 1
**Reported:** Finance lead — Copilot won't summarise the Q3 board pack in SharePoint. "It's right there, I can see it myself."

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction — board packs are commonly labelled OFFICIAL-SENSITIVE or higher, which blocks Copilot grounding. 2. Permissions/access boundary — Copilot checks effective permissions via Graph, not the browser session; broken permission inheritance could cause a mismatch. 3. Data indexing lag — file may not yet be indexed for semantic search. 4. Genuine Copilot fault. |
| **Fastest check** | Open the file in SharePoint and check the sensitivity label in the document header or information bar. |
| **Is this actually a Copilot bug?** | No — "I can see it myself" is classic permission-vs-Copilot-access mismatch; sensitivity labels or broken inheritance are far more likely. |

---

## Ticket 2
**Reported:** New hire (started yesterday) — Copilot in Outlook seems to know nothing about recent emails.

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Data indexing lag — mailbox content for a brand-new account typically takes 24–72 hours to be indexed by Microsoft 365 semantic index. 2. License/client prerequisite issue — Copilot license may not have been assigned or activated yet. 3. Genuine Copilot fault. |
| **Fastest check** | Confirm in M365 admin centre that a Copilot licence is assigned and that the user's mailbox provisioning is complete (Exchange Online). |
| **Is this actually a Copilot bug?** | No — new account + indexing lag is the overwhelmingly likely explanation; this is expected behaviour for day-one accounts. |

---

## Ticket 3
**Reported:** HR manager — asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got "I don't have access to that content."

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction — salary review files almost certainly carry a label (e.g., OFFICIAL-SENSITIVE / HR CONFIDENTIAL) that prevents Copilot grounding. 2. Permissions/access boundary — the HR manager may have access granted via a group or role the Graph API call does not resolve correctly. 3. Genuine Copilot fault. |
| **Fastest check** | Check the sensitivity label on the spreadsheet; if labelled at a tier that restricts Copilot, this is working as designed. |
| **Is this actually a Copilot bug?** | No — the error message "I don't have access to that content" is consistent with a label or permission enforcement boundary, not a Copilot defect. |

---

## Ticket 4
**Reported:** Sales rep — Copilot in Teams can't find a client contract shared via a guest link from another org.

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Guest/external sharing limitation — Copilot does not index or ground content shared via external guest links or cross-tenant access; this is a known architectural boundary. 2. Permissions/access boundary — the file lives in the external org's tenant and is not part of the user's M365 index. 3. Genuine Copilot fault. |
| **Fastest check** | Confirm whether the contract lives in the external org's SharePoint/OneDrive. If yes, Copilot cannot access cross-tenant content via a guest link by design. |
| **Is this actually a Copilot bug?** | No — Copilot only grounds on content within the user's own tenant index. Cross-tenant guest links are a known limitation, not a bug. |

---

## Ticket 5
**Reported:** IT admin — Copilot suddenly stopped working for the whole Finance team this morning, was fine yesterday.

| Field | Assessment |
|---|---|
| **Likely cause** | 1. License/client prerequisite issue — a licence assignment change, group membership update, or policy rollout overnight could have revoked access. 2. Permissions/access boundary — a Conditional Access policy or tenant-level Copilot policy may have been updated. 3. Genuine Copilot fault — service-wide or tenant-scoped outage (check M365 Service Health first). |
| **Fastest check** | Check M365 admin centre → Service Health for any active Copilot incidents, then check licence assignment and Conditional Access changes from the past 24 hours in Entra audit logs. |
| **Is this actually a Copilot bug?** | Unclear — a sudden team-wide failure *could* indicate a service incident, but an overnight policy or licence change is equally likely and should be ruled out first. |

---

## Ticket 6
**Reported:** Manager — Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to.

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — Copilot respects existing permissions and will surface any file the user has read access to, even if they have never personally navigated to it. This is expected behaviour, not a fault. |
| **Fastest check** | Confirm in SharePoint/OneDrive that the user's account has (or inherits) read access to the folder in question. |
| **Is this actually a Copilot bug?** | No — Copilot is working correctly. It surfaces content based on permissions, not browsing history. This is a permissions awareness and data governance concern, not a Copilot defect. |

---

## Ticket 7
**Reported:** Analyst — Copilot gives generic answers, doesn't seem to use any internal SharePoint content at all.

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Data indexing lag — SharePoint sites may not be fully crawled/indexed, especially if recently created or migrated. 2. Permissions/access boundary — analyst may not have been granted access to the relevant SharePoint sites, so Copilot correctly returns nothing. 3. License/client prerequisite issue — SharePoint Advanced Management or required Graph connectors may not be enabled. 4. Genuine Copilot fault. |
| **Fastest check** | Have the analyst open a specific SharePoint document directly and confirm they can access it; then test asking Copilot about that exact document to isolate whether it's an access or indexing issue. |
| **Is this actually a Copilot bug?** | No — generic answers with no grounding almost always indicate the user lacks permissions to the content or the content is not yet indexed; both are non-Copilot causes. |

---

## Ticket 8
**Reported:** Executive assistant — Copilot in Outlook can't see a shared mailbox's calendar that she manages on behalf of her director.

| Field | Assessment |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — Copilot in Outlook grounds on the signed-in user's own mailbox and calendar. Delegate or "send on behalf" access to a shared mailbox is not always surfaced via the Graph API calls Copilot uses. 2. License/client prerequisite issue — the shared mailbox may not have a Copilot licence (shared mailboxes typically require one for Copilot to act on their content). 3. Genuine Copilot fault. |
| **Fastest check** | Check whether the shared mailbox has a Copilot licence assigned in M365 admin centre; shared mailboxes require explicit licensing for Copilot features. |
| **Is this actually a Copilot bug?** | No — delegate/shared mailbox access is a known Copilot prerequisite gap; the shared mailbox must be licensed and permissions must be surfaced via Graph for Copilot to see it. |

---

## Summary Table

| # | Most Likely Cause | Fastest Check | Copilot Bug? |
|---|---|---|---|
| 1 | Sensitivity label restriction | Check sensitivity label on the document | No |
| 2 | Data indexing lag | Confirm licence assigned + mailbox provisioned | No |
| 3 | Sensitivity label restriction | Check sensitivity label on the spreadsheet | No |
| 4 | Guest/external sharing limitation | Confirm file is in external tenant | No |
| 5 | Licence/policy change | M365 Service Health + Entra audit logs | Unclear |
| 6 | Expected permissions behaviour | Verify user's SharePoint access rights | No |
| 7 | Data indexing lag / permissions | Test access to a specific doc, then ask Copilot | No |
| 8 | Permissions/access boundary (shared mailbox licensing) | Check Copilot licence on shared mailbox | No |

---

*Note: All findings are draft assessments for triage purposes. Verify against live environment and Microsoft documentation before closing tickets. Do not include PII, credentials, or tenant-specific data in this record.*
