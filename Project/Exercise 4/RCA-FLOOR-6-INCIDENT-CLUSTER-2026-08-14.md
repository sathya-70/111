# Root Cause Analysis: Floor 6 Incident Cluster
**Date:** 2026-08-14  
**Incident IDs:** Incident A (Critical), Incident B (High), Incident C (Medium)  
**Location:** Floor 6, Finbridge  
**Status:** Active - Containment and Mitigation In Progress

---

## Executive Summary

Three separate incidents occurred on Floor 6 following overlapping system changes:

1. **Incident A (CRITICAL)**: Possible unauthorized client matter exposure via Copilot/search after Friday document management rollout.
2. **Incident B (HIGH)**: Floor-wide login failures and severe slowness (12+ of 45 users) affecting business operations.
3. **Incident C (MEDIUM)**: Missing desktop shortcuts on affected endpoints impacting user workflow efficiency.

**Root cause is change collision:** Friday document management app deployment + Win11 migration + Intune policy convergence + first-business-day login surge created a compound fault environment.

---

## Incident A: Unauthorized Client Matter Exposure in Copilot/Search

### Findings

| Item | Detail |
|------|--------|
| **Fault Domain** | Permissions boundary in document management app → Copilot connector integration |
| **Trigger Event** | Friday 2026-08-13: Document management app rollout + post-migration indexing cycle |
| **Affected Scope** | Potentially all Floor 6 users with Copilot + new document management app access (unconfirmed) |
| **Evidence** | One paralegal reported visibility of client matter they believe not authorized to access |
| **Highest Probability Cause** | Permission inheritance regression or connector entitlement mismatch introduced during Friday rollout |

### Root Cause Analysis

#### Primary Hypothesis (70% confidence)
**Permission boundary mismatch between source repository ACL and Copilot connector retrieval scope**
- Friday rollout included repository permission model changes or app connector reconfiguration.
- Post-rollout sync/reindex did not fully reconcile source ACL changes with connector metadata.
- Result: Connector grants retrieval access based on outdated or incorrectly inherited permission state.

#### Secondary Hypothesis (20% confidence)
**Identity token cache/staleness causing outdated authorization decision at query time**
- User token cached authorization graph before Friday ACL changes took effect.
- Copilot query evaluated entitlement against stale cached state rather than current ACL.
- Force token refresh resolves single-session occurrence but indicates deeper sync issue.

#### Tertiary Hypothesis (10% confidence)
**Temporary over-permissioning from Friday rollout group or role changes**
- Friday deployment temporarily added users to a broader access group or role.
- Rollback script failed to remove membership cleanly.
- User now has inadvertent direct or inherited access to restricted matter.

### Impact Assessment
- **Confidentiality Risk**: HIGH - potential exposure of privileged client/legal information
- **Regulatory Risk**: HIGH - compliance implications if unauthorized access verified
- **Business Risk**: MEDIUM - single user report; true blast radius unknown
- **Reputational Risk**: HIGH - breach of client confidentiality trust

### Supporting Evidence Chain

1. **Temporal Correlation**: Issue occurs only after Friday rollout.
2. **Scope Alignment**: Reported by user in Floor 6, same cohort as app deployment.
3. **No Pre-Rollout Reports**: No similar incidents reported on Floor 6 before Friday.
4. **Post-Migration Timing**: Incident follows Win11 + Intune + document app changes within 72 hours.

---

## Incident B: Login Failures and Severe Slowness

### Findings

| Item | Detail |
|------|--------|
| **Fault Domain** | Identity/authentication, Intune provisioning, endpoint resource contention |
| **Trigger Events** | 1) Win11 migration; 2) Intune compliance/policy convergence; 3) Friday app deployment + first-logon install |
| **Affected Scope** | 12+ of 45 Floor 6 endpoints; likely concentrated in recent migration/enrollment batches |
| **Symptom Pattern** | Mixed: some users unable to sign in; others experience 5-15 minute login delays |
| **Peak Timing** | Monday 2026-08-14 morning (06:00-10:30) during normal business login surge |

### Root Cause Analysis

#### Primary Hypothesis (75% confidence)
**First-logon provisioning workload collision caused by deployment of new app during Win11 migration cycle**
- Win11 endpoints enrolled to Intune in recent weeks are still in heavy provisioning state.
- Friday app deployment assigned to Floor 6 cohort created additional first-run install + post-install tasks.
- Monday morning peak login load triggered simultaneous execution of: auth flow + policy eval + group policy application + app install + profile initialization.
- Result: Auth and shell initialization delays exceeded user timeout expectations; some sessions failed to complete before timeout.

#### Secondary Hypothesis (20% confidence)
**Conditional Access or compliance policy mismatch causing intermittent sign-in challenges or blocks**
- Intune compliance posture still converging for migrated devices.
- CA policy evaluation loops or challenges during peak load increased sign-in duration.
- Mixed failure/slowness pattern suggests intermittent policy/compliance block state.

#### Tertiary Hypothesis (5% confidence)
**Endpoint resource constraints (disk space, startup bloat, AV scan overlap)**
- Unlikely as primary cause given synchronized floor-wide onset.
- Possible contributing factor to slowness on individual devices.

### Impact Assessment
- **Business Impact**: HIGH - direct user productivity disruption for 12+ users across operations
- **Service Impact**: HIGH - 27% of Floor 6 user base affected
- **Operational Risk**: MEDIUM - sustained impact creates escalation and service desk pressure
- **Recovery Outlook**: HIGH - typically reversible via policy/app pause or device reboot + sync

### Supporting Evidence Chain

1. **Change Correlation**: Issue onset directly after three overlapping changes.
2. **Cohort Alignment**: Impact concentrated on users in recent Win11 migration and new app assignment rings.
3. **Time-of-Day Pattern**: Peak impact during morning login surge; some users report improvement after mid-morning.
4. **Workload Indicator**: Device provisioning logs show simultaneous policy/app/profile activity during login window.

---

## Incident C: Missing Desktop Shortcuts

### Findings

| Item | Detail |
|------|--------|
| **Fault Domain** | Shortcut create/remove logic in app installer or Intune remediation script |
| **Trigger Event** | Friday app deployment or Win11 migration; profile re-initialization after login failures |
| **Affected Scope** | Confirmed on at least 1 endpoint; likely additional endpoints in same deployment ring |
| **Evidence** | Expected shortcuts (e.g., Outlook, Teams, Edge) missing from desktop |

### Root Cause Analysis

#### Primary Hypothesis (60% confidence)
**Shortcut removal/replacement logic conflict in new app installer or post-install script**
- Friday app package includes script to deploy custom shortcuts.
- Script path logic or installer transform contains error (e.g., removal of all .lnk files before redeployment).
- Result: Shortcuts removed but not successfully re-created or re-created to wrong location.

#### Secondary Hypothesis (30% confidence)
**Profile re-initialization or temporary profile after login failure**
- Login failure (Incident B) triggered temporary profile creation or profile reset.
- User profile desktop items lost during profile state repair.
- Issue resolves only after manual shortcut restoration or profile cleanup.

#### Tertiary Hypothesis (10% confidence)
**Group Policy or Intune Shell Layout configuration conflict**
- GPO or Intune baseline intentionally removed custom desktop shortcuts as part of Win11 hardening.
- No compensating re-deployment of expected baseline shortcuts.

### Impact Assessment
- **Business Impact**: LOW-MEDIUM - usability issue, not access blocker
- **User Impact**: MEDIUM - workflow friction if missing shortcuts are frequently used
- **Operational Risk**: LOW - localized issue; straightforward remediation path exists

### Supporting Evidence Chain

1. **Deployment Timing**: Issue follows Friday app and Win11 migration changes.
2. **Localized Pattern**: Single user report suggests installer edge case or profile-specific condition.
3. **Scope Fit**: Affected device in Floor 6 app deployment ring.

---

## Causal Chain: How Three Incidents Occurred Simultaneously

```
Friday 2026-08-13
│
├─> Document Management App Rollout
│   ├─> Permission model changes
│   ├─> Copilot connector reconfiguration
│   └─> Post-rollout indexing/sync
│       └─> Potential ACL/entitlement mismatch (INCIDENT A root cause)
│
├─> Win11 Migration Continues (ongoing)
│   ├─> Devices enrolled to Intune in heavy provisioning state
│   ├─> Compliance posture convergence in progress
│   └─> Policy + baseline application ongoing
│
└─> App Assigned to Floor 6 Cohort
    ├─> First-run install queued for Monday morning login
    └─> Post-install tasks scheduled for logon execution

Monday 2026-08-14 06:00-10:30 (Peak Login Window)
│
└─> Workload Collision
    ├─> Auth flow: identity checks, MFA, token generation
    ├─> Compliance eval: device state check, CA policy check
    ├─> Intune provisioning: policy application, group policy recompile
    ├─> App install: new app first-run install + post-install tasks
    ├─> Profile init: profile load, shell startup, Explorer initialization
    └─> Combined load exceeds login timeout / system resources
        ├─> Some sessions fail before completion (INCIDENT B failures)
        ├─> Others complete but exceed user expectations (INCIDENT B slowness)
        └─> Failed logins may trigger temporary profile (INCIDENT C side effect)

Separate (Friday evening/weekend):
└─> Copilot Query Exposure
    └─> User asks Copilot about matter they believe no access to
        └─> Connector retrieval succeeds despite source ACL should deny
            └─> Triggers INCIDENT A alert
```

---

## Temporal Summary

| Time | Event |
|------|-------|
| Fri 2026-08-13 afternoon | Document management app + Copilot connector deployed |
| Fri 2026-08-13 evening | Post-rollout indexing and sync operations begin |
| Fri 2026-08-13 - Sun 2026-08-15 | (Weekend; minimal activity) |
| Mon 2026-08-14 06:00 | Business day begins; users attempt sign-in |
| Mon 2026-08-14 06:15-10:30 | Peak login failures and slowness observed |
| Mon 2026-08-14 (exact time unknown) | Paralegal reports Copilot access to restricted client matter |
| Mon 2026-08-14 08:00 | Incidents escalated to IT Ops; triage begins |

---

## Cross-Incident Dependencies

### Incident A does NOT directly cause Incidents B or C
- A is permissions/retrieval scope issue; B/C are provisioning/shell issues.
- Separate fault domains; concurrent occurrence is coincidental timing.

### Incident B may contribute to Incident C
- Failed login or temporary profile could trigger profile re-initialization.
- Shortcut loss during profile reset creates appearance of linked issue.
- Resolution: Fix Incident B login flow, then verify Incident C resolves independently.

### Incident C is unlikely to cause A or B
- Shortcut issue is client-side only; no impact on identity or connectors.

---

## Summary of Root Causes by Incident

| Incident | Root Cause (Best Hypothesis) | Confidence |
|----------|------------------------------|------------|
| A | ACL/entitlement mismatch in document app → Copilot connector post-rollout sync | 70% |
| B | First-logon workload collision: Win11 + Intune + app provisioning simultaneous load at peak login time | 75% |
| C | Shortcut removal/replacement script error in app installer OR profile re-init after login failure | 60% |

---

## Recommendations for Remediation Priority

1. **Incident A first**: Containment (restrict Copilot retrieval) + evidence collection (ACL/entitlement audit) before any user-facing communication or access restoration.
2. **Incident B second**: Policy/app pause + endpoint reboot/sync to stabilize access, then gradual re-enablement.
3. **Incident C third**: Shortcut baseline remediation via Intune after logins stabilize; low risk of side effects.

---

## Lessons Learned (Preliminary)

1. **Change coordination failure**: Three major changes (app rollout + OS migration + compliance policy) not sequenced or gated independently.
2. **First-logon provisioning underestimated**: Win11 migration still in active provisioning; deploying new app during this window creates predictable collision.
3. **Post-deployment validation missing**: Friday rollout not validated for entitlement correctness before Weekend business downtime.
4. **Missing early-warning monitoring**: No alerting on high login failure rates or slow sign-in duration to catch issue at outbreak.

---

## Approval and Sign-Off

- **RCA Prepared By**: DWP Engineer (Cold Incident)
- **Date Prepared**: 2026-08-14
- **Status**: DRAFT - Pending validation against collected logs and SME review
- **Next Steps**: Execute remediation runbook; validate hypotheses against actual event logs; update RCA as facts confirm/revise

