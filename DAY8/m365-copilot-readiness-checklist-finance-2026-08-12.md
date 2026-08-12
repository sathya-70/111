# Microsoft 365 Copilot Readiness Checklist — Finance Department

**Date:** 2026-08-12
**Department:** Finance (~200 users)
**Prepared by:** DWP Endpoint Team
**Licence basis:** M365 E5 | Copilot add-on not yet assigned

> **Risk note:** This department holds payroll, board packs, M&A documents, and client financial data. SharePoint permissions were inherited from a 2019 migration and have never been audited. **Section 4 (Permissions & Oversharing) must be completed and signed off before Copilot licences are assigned.** Copilot reasons over all content the user has access to — unaudited permissions mean Copilot can surface documents the user should never have seen.

---

## Section 1 — Licensing Prerequisites

- [ ] Confirm all ~200 Finance users hold an active **Microsoft 365 E5** licence in the admin centre.
- [ ] Confirm no users are on legacy E3 or mixed licence states left over from previous migrations.
- [ ] Procure and stage **Microsoft 365 Copilot add-on licences** (one per user) — do not assign until Section 4 is complete.
- [ ] Confirm tenant is on a supported **commercial cloud** (GCC, GCC High, and DoD have separate availability timelines).
- [ ] Verify the tenant has **no Copilot block policies** applied at the group or tenant level that would prevent enablement.

---

## Section 2 — Microsoft 365 Apps Client Version

- [ ] All Finance devices must run **Microsoft 365 Apps version 2307 (build 16626) or later** — Copilot features are not available on earlier builds.
- [ ] Confirm devices are on **Current Channel** or **Monthly Enterprise Channel** — Semi-Annual Enterprise Channel does not receive Copilot features.
- [ ] Run a device compliance report (Intune or M365 Apps admin centre) filtered to the Finance group to identify any devices below the minimum build.
- [ ] Remediate out-of-date devices before licence assignment — update via Intune or SCCM and validate build version post-update.
- [ ] Confirm **Click-to-Run** is in use; MSI-based Office installations are not supported for Copilot.

---

## Section 3 — Identity and MFA Readiness

- [ ] Confirm all Finance user accounts are **cloud-only or hybrid-synced** to Entra ID (Azure AD) — on-premises-only accounts are not supported.
- [ ] Confirm **Multi-Factor Authentication (MFA)** is enforced for all 200 users via Conditional Access — not just enabled via legacy per-user MFA.
- [ ] Confirm **no MFA exclusions** exist for Finance accounts (service accounts, break-glass accounts, or named user exceptions).
- [ ] Validate that **Conditional Access policies** do not block the Copilot service endpoints (check against Microsoft's published IP/URL list for M365 Copilot).
- [ ] Confirm user **UPNs match primary SMTP addresses** — mismatches can cause Copilot identity resolution failures.
- [ ] Check for any Finance accounts still using **basic authentication** — must be disabled before enablement.

---

## Section 4 — SharePoint and OneDrive Permissions and Oversharing ⚠️ HIGHEST PRIORITY

> This section is mandatory before any Copilot licence is assigned. Copilot does not create new access — it reveals existing access at scale. Unaudited permissions from 2019 mean users (and Copilot acting on their behalf) may be able to read payroll files, M&A documents, or board packs they were never formally granted access to. Complete every item below and obtain sign-off from the data owner and Information Security before proceeding.

### 4a — Permissions Audit

- [ ] Run the **SharePoint Admin Centre — Access Reviews** report across all Finance-owned site collections to identify who has access to what.
- [ ] Export the full permissions matrix for Finance SharePoint sites using **Microsoft Entra Access Reviews** or a third-party tool (e.g. Orchestry, ShareGate) — filter for all unique permissions, broken inheritance, and direct user grants.
- [ ] Identify all sites and libraries where **permissions inheritance was broken** during or after the 2019 migration and document the current state.
- [ ] Identify all **directly granted permissions** (users added directly to a library or folder rather than via a group) — these are the most likely source of unintended access.
- [ ] Remove or reassign any direct user grants that cannot be justified by a current business need.
- [ ] Confirm that **no Finance site has "Everyone" or "Everyone except external users"** as a member, visitor, or sharing recipient.

### 4b — Oversharing Checks

- [ ] Run **SharePoint Online — Sharing Reports** in the Purview compliance portal to identify files shared via anonymous link, organisation-wide link, or external sharing.
- [ ] Revoke all **anonymous (Anyone) sharing links** on Finance sites — these are incompatible with a high-sensitivity environment regardless of Copilot.
- [ ] Review and revoke all **organisation-wide sharing links** on documents classified as payroll, board, M&A, or client financial data.
- [ ] Review **OneDrive sharing** for all Finance users — confirm no sensitive documents are shared broadly from personal OneDrive.
- [ ] Enforce **site-level external sharing as "Only people in your organisation"** for all Finance site collections.
- [ ] Enable **SharePoint Advanced Management — Restricted SharePoint Search** if not already active — this limits Copilot's search scope to curated sites only, providing an additional safety layer during the rollout period.
- [ ] Check **default sharing link settings** are set to "Specific people" (not "Anyone" or "People in your organisation") for Finance sites.

### 4c — Sign-off Gate

- [ ] Permissions audit findings reviewed and accepted by **Finance data owner**.
- [ ] Permissions audit findings reviewed and accepted by **Information Security**.
- [ ] Written confirmation obtained that residual access risks are accepted or remediated before Copilot licences are assigned.

---

## Section 5 — Sensitivity Labelling

- [ ] Confirm **Microsoft Purview sensitivity labels** are published and applied to Finance users.
- [ ] Confirm that Finance document libraries holding payroll, board, M&A, and client data have a **default label** applied at the library level — unlabelled documents in these locations are a gap.
- [ ] Run a **Content Explorer** scan (Purview) to identify unlabelled or incorrectly labelled files in Finance SharePoint sites before Copilot is enabled.
- [ ] Confirm **auto-labelling policies** are configured for known Finance data patterns (e.g. payroll file naming conventions, M&A folder structures).
- [ ] Confirm that **Copilot will inherit and respect label-based access controls** — validate that DLP policies referencing sensitivity labels are active for Finance.
- [ ] Confirm users understand they must **not remove or downgrade labels** on documents generated or summarised by Copilot.

---

## Section 6 — End-User Communications and Enablement

- [ ] Brief Finance managers on what Copilot will and will not do — specifically that it does not grant new access but will make existing access much easier to act on.
- [ ] Issue a **pre-launch communication** to all 200 Finance users explaining Copilot is being introduced, what to expect, and how to raise concerns about unexpected document access.
- [ ] Deliver a **30-minute enablement session** per team covering practical use cases relevant to Finance: drafting, summarising, data analysis in Excel, and meeting notes in Teams.
- [ ] Publish a **"what not to ask Copilot"** guidance note for Finance users — specifically covering PII, client data, and material non-public information (MNPI) in the context of M&A.
- [ ] Establish a **feedback channel** (e.g. shared mailbox or Teams channel) for users to report unexpected behaviour, such as Copilot surfacing documents they believe they should not have access to.
- [ ] Confirm a named **Copilot champion** in Finance who can support peer adoption and escalate issues to IT.
- [ ] Schedule a **30-day post-enablement review** to assess adoption, surface new issues, and confirm no unintended data access has been reported.

---

## Readiness Sign-Off

| Section | Owner | Status | Date |
|---|---|---|---|
| 1 — Licensing | IT Licensing | | |
| 2 — Client version | Endpoint Team | | |
| 3 — Identity / MFA | Identity Team | | |
| 4 — Permissions & Oversharing | InfoSec + Finance Data Owner | | |
| 5 — Sensitivity Labelling | Purview / Compliance Team | | |
| 6 — End-user Enablement | Change Manager | | |
| **Final approval to assign Copilot licences** | IT Lead + InfoSec | | |

> **Do not assign Copilot licences until all rows above are marked complete and Section 4 sign-off is obtained in writing.**
