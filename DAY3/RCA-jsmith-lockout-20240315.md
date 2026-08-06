# Root Cause Analysis — Account Lockout Incident

## Document Header

| Field              | Detail                                      |
|--------------------|---------------------------------------------|
| **Incident ID**    | INC-[REDACTED]                              |
| **Date**           | 2024-03-15                                  |
| **Time of Impact** | 08:06:01 (lockout triggered)                |
| **Time Resolved**  | 08:23:44 (successful logon confirmed)       |
| **Duration**       | ~18 minutes (lockout to resolution)         |
| **Affected User**  | jsmith                                      |
| **Affected Device**| DESKTOP-FB001                               |
| **Resolved By**    | FINBRIDGE\helpdesk-admin                    |
| **Author**         | [DWP Analyst Name]                          |
| **Review Date**    | [Date]                                      |
| **Classification** | OFFICIAL                                    |

---

## 1. Incident Summary

User jsmith was locked out of their workstation (DESKTOP-FB001) at 08:06:01 on 2024-03-15 after two consecutive failed interactive logon attempts. The account lockout policy threshold was triggered. The user was unable to unlock the machine at 08:07:45. A helpdesk administrator re-enabled the account at 08:22:10. The user successfully logged in at 08:23:44. Total impact duration: approximately 18 minutes of lost access.

---

## 2. Timeline of Events

| Time     | Event ID | Type          | Detail                                                            |
|----------|----------|---------------|-------------------------------------------------------------------|
| 08:02:14 | 4625     | Audit Failure | jsmith — failed interactive logon (type 2). Bad password/username.|
| 08:04:22 | 4625     | Audit Failure | jsmith — second failed interactive logon (type 2). Same reason.  |
| 08:06:01 | 4740     | Audit Failure | jsmith account locked out. Triggered from DESKTOP-FB001.          |
| 08:07:45 | 4625     | Audit Failure | jsmith — failed unlock attempt (type 7). Reason: account locked.  |
| 08:22:10 | 4722     | Audit Success | jsmith account enabled by FINBRIDGE\helpdesk-admin.               |
| 08:23:44 | 4624     | Audit Success | jsmith — successful interactive logon (type 2).                   |

---

## 3. Impact Assessment

| Category              | Detail                                                       |
|-----------------------|--------------------------------------------------------------|
| **User impact**       | Single user (jsmith) unable to access workstation ~18 mins   |
| **Business impact**   | Lost productivity; helpdesk resource consumed                 |
| **Data impact**       | None — no unauthorised access occurred                        |
| **Security impact**   | None confirmed — lockout policy functioned as designed        |
| **Recurrence risk**   | Medium — root cause (see below) is not self-resolving         |

---

## 4. Root Cause Summary

The immediate cause was two failed interactive logon attempts at DESKTOP-FB001 which exceeded the account lockout threshold. The underlying cause is most likely that jsmith's password had recently been changed (or reset) and the user was unaware of, or had forgotten, the new credential. No other source machines appear in the log, ruling out background processes or remote sessions as the lockout trigger.

The event log shows a `4722` (account enabled) rather than `4767` (account unlocked), which may indicate the helpdesk action involved enabling the account rather than a targeted unlock — suggesting the account may also have been in a disabled state, or the helpdesk tooling used a reset/enable workflow. **This should be verified against helpdesk ticket INC-[REDACTED] and the admin tool used.**

---

## 5. Five Whys Analysis

### Why 1 — Why was jsmith locked out?

**Because the account lockout policy threshold was reached after repeated failed password attempts.**

Evidence: Event 4740 at 08:06:01 confirms lockout was triggered from DESKTOP-FB001 following two recorded 4625 failures (08:02:14 and 08:04:22).

---

### Why 2 — Why did jsmith repeatedly enter the wrong password?

**Because jsmith did not know the correct current password for the account.**

Evidence: Both failures at 08:02 and 08:04 share failure reason "Unknown username or bad password" from the same machine, same logon type — consistent with a human entering a credential they believe is correct rather than a script or background process. The immediate successful logon at 08:23:44 after helpdesk action confirms the user was able to authenticate once the account state was corrected, suggesting a credential knowledge gap rather than a forgotten password per se.

---

### Why 3 — Why did jsmith not know the correct password?

**Most likely because the password had recently been changed or reset without the user retaining the new credential.**

Possible sub-causes:
- A forced password expiry reset was completed but the new password was not retained
- An admin-initiated password reset was performed without adequate communication to the user
- The user changed the password on another device/session and did not update their memory of it
- Caps Lock or keyboard layout caused consistent mis-entry of a known password

**This requires confirmation from the helpdesk ticket — the exact trigger for the credential mismatch is not determinable from event log data alone.**

---

### Why 4 — Why did the password change not result in the user retaining the credential?

**Because there is no confirmed process ensuring users acknowledge and retain new credentials after a reset, and Self-Service Password Reset (SSPR) may not have been available or used.**

Indicators:
- The user required helpdesk intervention at 08:22:10 rather than self-recovering — suggesting SSPR either does not exist, is not enrolled for jsmith, or the user is unaware of it
- A 16-minute helpdesk wait (08:06 lockout to 08:22 resolution) represents a process gap where SSPR could have resolved the issue within minutes without human intervention

---

### Why 5 — Why is SSPR not preventing helpdesk-dependent lockout resolution?

**Because SSPR adoption and enrolment is not confirmed as a standard for all users, or the process for enforcing enrolment is not in place.**

This is the systemic root cause. If SSPR were consistently enrolled and promoted, the user could have self-recovered before the lockout escalated to a helpdesk call. The dependency on `FINBRIDGE\helpdesk-admin` for a routine lockout recovery is a process and tooling gap.

---

## 6. Contributing Factors

| Factor                         | Detail                                                                 |
|--------------------------------|------------------------------------------------------------------------|
| Low lockout threshold          | Account locked after only 2 failures — threshold may be too aggressive for usability without SSPR in place |
| No SSPR self-recovery          | User required helpdesk; 16-minute wait                                 |
| No lockout pre-warning         | Windows does not warn users how many attempts remain before lockout     |
| Possible poor reset comms      | If password was admin-reset, user may not have been clearly notified    |

---

## 7. Recommendations

| Priority | Action                                                                                      | Owner            |
|----------|---------------------------------------------------------------------------------------------|------------------|
| High     | Confirm whether SSPR is deployed and enrolled for jsmith — if not, enrol immediately        | Identity/IAM team|
| High     | Review helpdesk ticket to confirm exact cause of credential mismatch (expiry vs. reset)     | Service Desk Lead|
| Medium   | Audit SSPR enrolment completeness across all users — report on % enrolled                   | IAM / Reporting  |
| Medium   | Review account lockout threshold — consider raising from 2 to 5 with SSPR as compensating control | Security team |
| Medium   | Review 4722 vs. 4767 usage in helpdesk tooling — ensure correct event is logged for unlocks | IAM / Tooling    |
| Low      | Add user awareness communication on SSPR availability and how to use it                     | Comms / Training |

---

## 8. Lessons Learned

- Account lockout policy is functioning correctly — this is not a security failure, it is a usability and process gap
- SSPR is the primary preventive control for lockout-driven helpdesk demand; its absence or non-enrolment is the systemic issue
- Event log analysis alone cannot determine the credential change history — always correlate with helpdesk tickets and identity management audit logs for a complete picture
- The 4722 vs. 4767 discrepancy should be clarified to ensure audit trails accurately reflect admin actions

---

## 9. Sign-Off

| Role               | Name          | Date       |
|--------------------|---------------|------------|
| Analyst            | [Name]        | [Date]     |
| Service Desk Lead  | [Name]        | [Date]     |
| IAM / Security     | [Name]        | [Date]     |

---

*This document is OFFICIAL. Do not include real user PII, credentials, or internal hostnames if shared outside the organisation.*
