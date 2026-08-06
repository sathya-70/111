# User Logon Incident Analysis and Hypothesis (cthompson)

Date: 2026-08-06  
Scope basis only: single user impacted, started around 08:40 today, no declared change.

## Scope Facts Used
- Symptom: user cthompson cannot log in.
- Impact: only cthompson.
- Start time: approximately 08:40 this morning.
- Known change: none.

## Ranked Hypotheses (Most Probable First)

### 1) Account lockout (bad password attempts, stale saved credentials, or repeated auth attempts)
Why this fits scope facts:
- A lockout commonly affects exactly one user.
- Sudden onset at a specific time is consistent with threshold-based lockout.
- "No change" is consistent because lockouts often occur without intentional change (for example, cached credentials or background retries).

Single fastest check:
- Check directory/sign-in security logs for a lockout event on cthompson at or just before 08:40.

### 2) Password expired or forced password change requirement
Why this fits scope facts:
- This is user-specific and often appears suddenly when the expiry threshold is reached.
- Timing "this morning" aligns with a newly effective expiry window.
- No environment change is required for this to happen.

Single fastest check:
- Query account password status (expired/must-change-at-next-logon) for cthompson in the identity source.

### 3) User account disabled or restricted (logon hours/workstation constraints)
Why this fits scope facts:
- These controls can affect one account only.
- A restriction becoming effective at a certain time can create a sudden failure.
- No broad service impact is expected.

Single fastest check:
- Inspect account flags and restrictions for cthompson (enabled/disabled, allowed logon hours, allowed workstations).

### 4) User-object authentication inconsistency (directory replication/sync issue for this identity)
Why this fits scope facts:
- A directory inconsistency can isolate impact to one user.
- It can appear time-bound without an obvious operator-initiated change.
- Fits single-user failure with no wider outage signal.

Single fastest check:
- Verify cthompson's current account state and recent update timestamps across authoritative identity sources/controllers.

### 5) User-specific sign-in factor issue (MFA/secondary auth method unavailable or out of sync)
Why this fits scope facts:
- MFA failures are frequently user-specific.
- Sudden failure can occur when a method becomes unavailable (device/app issue) without tenant-wide change.
- Symptom can be perceived simply as "cannot log in."

Single fastest check:
- Review cthompson's latest sign-in attempt result detail to confirm whether primary auth passed and MFA/second factor failed.

## Notes
- This list is intentionally hypothesis-driven from scope facts only.
- No single root cause is selected at this stage.
- Execute checks in order to confirm/eliminate quickly and reduce mean time to resolution.

## Event Evidence Assessment (Incident Window 2024-03-15 08:44-09:12)

### Hypothesis 1: Account lockout (bad password attempts, stale saved credentials, or repeated auth attempts)
Judgement: Supported.

Evidence:
- 08:44:01 Event 4776: credential validation failed with error 0xC000006A (wrong password).
- 08:44:03 Event 4625: bad password (interactive logon type 2).
- 08:44:28 Event 4625: bad password (interactive logon type 2).
- 08:44:55 Event 4625: bad password (interactive logon type 2).
- 08:44:56 Event 4740: account locked out.
- 08:45:10 Event 4625: failure reason Account locked out (unlock attempt type 7).

### Hypothesis 2: Password expired or forced password change requirement
Judgement: Contradicted.

Evidence:
- 08:44:01 Event 4776: wrong password code 0xC000006A, not an expiry/must-change signal.
- 08:45:44 Event 4771: pre-auth failed code 0x18 (wrong password).
- 08:46:01 Event 4771: pre-auth failed code 0x18 (wrong password).
- 08:46:33 Event 4771: pre-auth failed code 0x18 (wrong password).

### Hypothesis 3: Account disabled or restricted (logon hours/workstation constraints)
Judgement: Contradicted.

Evidence:
- 08:44:56 Event 4740 explicitly records account lockout.
- 08:45:10 Event 4625 states Account locked out.
- 08:44:01 Event 4776 and 08:44:03/08:44:28/08:44:55 Event 4625 entries show a bad-password sequence preceding lockout, not disabled/restriction indicators.

### Hypothesis 4: User-object authentication inconsistency (directory replication/sync issue)
Judgement: Neutral.

Evidence:
- 08:44:01 Event 4776 and 08:44:03/08:44:28/08:44:55 Event 4625 entries form a coherent local bad-password to lockout path.
- 08:45:44, 08:46:01, 08:46:33 Event 4771 entries from source IP 10.10.8.112 show additional wrong-password attempts from another source.
- These events neither directly confirm nor directly eliminate replication/sync inconsistency.

### Hypothesis 5: User-specific MFA/secondary factor issue
Judgement: Contradicted.

Evidence:
- 08:44:01 Event 4776 and 08:45:44/08:46:01/08:46:33 Event 4771 indicate primary credential failure (wrong password).
- 08:44:56 Event 4740 and 08:45:10 Event 4625 confirm lockout path.
- No provided event indicates an MFA challenge or second-factor-specific denial.

## Surviving Hypothesis

Account lockout caused by repeated bad password attempts, likely including a stale credential retry source.

Key supporting event chain:
- 08:44:01 Event 4776 wrong password.
- 08:44:03, 08:44:28, 08:44:55 Event 4625 bad password.
- 08:44:56 Event 4740 account locked out.
- 08:45:10 Event 4625 account locked out.
- 08:45:44, 08:46:01, 08:46:33 Event 4771 wrong password from 10.10.8.112.

## Detailed Resolution Steps

1. Confirm lockout status in AD and note last bad password metadata for cthompson.
2. Identify host 10.10.8.112 in DHCP/DNS/CMDB and map it to endpoint and session owner.
3. Stop retry sources before unlock/reset:
	- Remove saved credentials from Windows Credential Manager on DESKTOP-FB022 and 10.10.8.112.
	- Update or remove stored credentials in mapped drives, Outlook/Teams/OneDrive/VPN clients, and browser-integrated auth stores.
	- Review Scheduled Tasks and Services running with cthompson credentials; update password or disable temporarily.
4. If appropriate, reset password to a temporary strong value and then unlock account.
5. Have user sign in first on DESKTOP-FB022 only, then validate interactive logon success.
6. Monitor for recurrence (Events 4625, 4771, 4776, 4740) for at least 30-60 minutes.
7. If bad attempts continue from 10.10.8.112, isolate and triage that endpoint for stale creds, misconfigured service, or suspicious activity.
8. Complete closure notes with exact stale credential source and preventive controls applied.
