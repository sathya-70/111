# M365 Copilot Readiness — Tiered Priority Ranking
## Finance Department | Pre-Rollout Gate Analysis

**Date:** 2026-08-12
**Linked checklist:** m365-copilot-readiness-checklist-finance-2026-08-12.md
**Prepared by:** DWP Endpoint Team

---

## Why Permissions and Oversharing is a MUST — Not Just Another Check

Licensing and client version are technically simpler to verify, but they carry no data risk if skipped — the worst outcome is Copilot does not work. Unaudited permissions in a Finance environment carry a categorically different consequence: Copilot will silently surface documents the user has never actively chosen to open, including payroll files, board packs, M&A documents, and client financial data that may have been accessible since 2019 but never actively discovered.

Standard document access requires a user to know a file exists and navigate to it. Copilot removes that friction entirely — it proactively retrieves, summarises, and cites content across everything the user can reach. An employee who technically has read access to a board pack they were never meant to see will have that content returned in a Copilot summary without any deliberate action on their part.

In a Finance department with inherited, unaudited permissions and data that includes material non-public information, that is not a configuration gap — it is a data governance and regulatory risk. That is why Section 4 is a hard gate, not a high-priority recommendation.

---

## Tier 1 — MUST Complete Before Rollout (Blocking)

These items either prevent Copilot from functioning at all, or carry data, compliance, or identity risk that cannot be accepted at point of enablement.

### Licensing (Section 1)
- [ ] All users confirmed on active M365 E5 licences.
- [ ] Copilot add-on licences procured and staged — **not assigned** until Tier 1 is fully complete.
- [ ] No block policies preventing Copilot enablement at tenant or group level.

*Reason: Without correct licences Copilot will not enable. Staged but unassigned licences are the correct state at this point.*

### Microsoft 365 Apps Client Version (Section 2)
- [ ] All Finance devices confirmed on build 16626 (version 2307) or later.
- [ ] All devices confirmed on Current Channel or Monthly Enterprise Channel.
- [ ] Out-of-date devices remediated before licence assignment.

*Reason: Copilot features are simply unavailable on older builds. Assigning licences before devices are updated creates a broken user experience and a support queue from day one.*

### Identity and MFA (Section 3 — core items)
- [ ] All Finance accounts confirmed in Entra ID (cloud or hybrid-synced).
- [ ] MFA enforced via Conditional Access for all 200 users — no legacy per-user MFA.
- [ ] No MFA exclusions exist for any Finance account.
- [ ] Basic authentication disabled for all Finance accounts.

*Reason: MFA is a prerequisite for Copilot access. An account without enforced MFA accessing Copilot — which can retrieve sensitive financial content — is an unacceptable identity risk in a regulated environment.*

### Permissions and Oversharing Audit — Full Section 4 ⚠️
- [ ] Full permissions matrix exported and reviewed for all Finance site collections.
- [ ] All broken inheritance instances identified and documented.
- [ ] All unjustified direct user grants removed or reassigned.
- [ ] "Everyone" and "Everyone except external users" confirmed absent from all Finance sites.
- [ ] All anonymous and organisation-wide sharing links on sensitive content revoked.
- [ ] External sharing set to "Only people in your organisation" on all Finance sites.
- [ ] Restricted SharePoint Search enabled as a rollout safety net.
- [ ] Written sign-off obtained from Finance data owner and Information Security.

*Reason: See justification above. This is the highest data-risk item in the entire rollout for this specific department and context. It is listed last in this tier not because it is least important, but because it is the most time-consuming and must be completed in full — partial completion is not sufficient.*

---

## Tier 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

These items do not technically block Copilot from functioning, but skipping them creates meaningful compliance, data quality, or support risk that will be harder to remediate after users are active.

### Sensitivity Labelling (Section 5 — core items)
- [ ] Sensitivity labels confirmed published and active for all Finance users.
- [ ] Default labels applied at library level for Finance document libraries holding sensitive data.
- [ ] DLP policies referencing sensitivity labels confirmed active for Finance.

*Reason: Copilot will generate and reference content regardless of whether it is labelled. Unlabelled outputs from Copilot in a Finance context may not be caught by DLP controls. Getting labels in place before users are active is significantly easier than retrospectively labelling Copilot-generated content.*

### Identity — Remaining Items (Section 3)
- [ ] UPN and primary SMTP address match confirmed for all Finance accounts.
- [ ] Conditional Access policies validated against Copilot service endpoints.

*Reason: UPN mismatches cause silent identity resolution failures that are difficult to diagnose post-rollout. CA endpoint gaps may block Copilot intermittently rather than consistently, creating confusing user experience.*

### Pre-launch Communication (Section 6 — selected items)
- [ ] Finance managers briefed on what Copilot will and will not do.
- [ ] All-user pre-launch communication issued.
- [ ] "What not to ask Copilot" guidance issued to Finance users covering PII, client data, and MNPI.

*Reason: Users who do not understand Copilot's scope are more likely to input sensitive data into prompts, share Copilot-generated summaries inappropriately, or raise avoidable support tickets. The MNPI guidance is particularly important pre-rollout given M&A activity in this department.*

---

## Tier 3 — CAN Complete During or After Rollout (Lower Risk)

These items improve the experience and governance posture but do not materially affect the safety or functionality of the initial rollout.

### Sensitivity Labelling — Supplementary (Section 5)
- [ ] Content Explorer scan to identify unlabelled files — can be run in parallel with early rollout and remediated progressively.
- [ ] Auto-labelling policies for Finance data patterns — valuable but can be tuned post-launch using real data.
- [ ] User guidance on not downgrading labels on Copilot outputs — include in post-launch enablement session.

### End-User Enablement — Delivery (Section 6)
- [ ] 30-minute enablement sessions per Finance team — can begin at or shortly after licence assignment.
- [ ] Named Copilot champion identified and briefed.
- [ ] Feedback channel established (Teams channel or shared mailbox).
- [ ] 30-day post-enablement review scheduled.

*Reason: These are adoption and continuous improvement activities. Delaying licence assignment until all training is delivered is unnecessary and will slow the rollout. Enablement can run alongside early access.*

---

## Summary Table

| Checklist Area | Tier | Rationale |
|---|---|---|
| Licensing verification | MUST | Functional prerequisite |
| Client version remediation | MUST | Functional prerequisite |
| MFA and identity (core) | MUST | Identity security prerequisite |
| Permissions and oversharing audit | **MUST — highest data risk** | Unaudited access becomes instantly explorable by Copilot |
| Sensitivity labels (core) | SHOULD | DLP gap risk if skipped |
| Identity (UPN/CA endpoints) | SHOULD | Silent failure risk post-rollout |
| Pre-launch comms and MNPI guidance | SHOULD | User risk behaviour without it |
| Content Explorer scan | CAN | Progressive remediation acceptable |
| Auto-labelling tuning | CAN | Better done with real usage data |
| Enablement sessions | CAN | Adoption activity, not a safety gate |
| 30-day review | CAN | Post-rollout governance activity |
