# Root Cause Analysis (RCA)

## Incident
- Title: Single-user login failure - FINBRIDGE\\cthompson
- Date: 2024-03-15
- Detection window: 08:44 to 09:12 (Security log extract)
- User-reported symptom: cthompson unable to log in
- Scope: single user only, no broad outage
- Service impact: user could not authenticate interactively to endpoint
- Resolution confirmed: 09:09 AM

## Executive Summary
At approximately 08:44, FINBRIDGE\\cthompson experienced repeated authentication failures due to incorrect credentials, resulting in account lockout (Event 4740). The evidence sequence shows multiple wrong-password attempts from DESKTOP-FB022, followed by continued wrong-password Kerberos pre-auth attempts from a second source IP (10.10.8.112), indicating a likely stale credential retry source. The remediation removed/contained retry sources and restored account access. Successful interactive logon was confirmed at 09:09:01 on DESKTOP-FB022 with no further issues reported.

## Supporting Evidence

### Pre-resolution failure and lockout evidence
- 08:44:01 - Event 4776 (Audit Failure)
  - Domain credential validation failed for FINBRIDGE\\cthompson
  - Error 0xC000006A (wrong password)
  - Source workstation: DESKTOP-FB022
- 08:44:03 - Event 4625 (Audit Failure)
  - Unknown user name or bad password
  - Logon type 2 (Interactive)
  - Source: DESKTOP-FB022
- 08:44:28 - Event 4625 (Audit Failure)
  - Unknown user name or bad password
  - Logon type 2 (Interactive)
  - Source: DESKTOP-FB022
- 08:44:55 - Event 4625 (Audit Failure)
  - Unknown user name or bad password
  - Logon type 2 (Interactive)
  - Source: DESKTOP-FB022
- 08:44:56 - Event 4740 (Audit Failure)
  - User account locked out
  - Account: FINBRIDGE\\cthompson
  - Caller computer: DESKTOP-FB022
- 08:45:10 - Event 4625 (Audit Failure)
  - Failure reason: Account locked out
  - Logon type 7 (Unlock attempt)
  - Source: DESKTOP-FB022
- 08:45:44 - Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112
- 08:46:01 - Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112
- 08:46:33 - Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112

### Post-resolution recovery evidence
- 09:08:14 - Event 4722 (Audit Success)
  - User account enabled
  - Account: FINBRIDGE\\cthompson
  - Action by: FINBRIDGE\\helpdesk-admin
- 09:09:01 - Event 4624 (Audit Success)
  - Successful account logon
  - Account: FINBRIDGE\\cthompson
  - Logon type 2 (Interactive)
  - Source: DESKTOP-FB022

## Timeline (End-to-End)
- ~08:40: User first reports inability to log in.
- 08:44:01: First captured wrong-password validation failure (4776).
- 08:44:03 to 08:44:55: Repeated interactive bad-password failures (4625).
- 08:44:56: Account transitions to locked state (4740).
- 08:45:10: Locked-out login attempt recorded (4625, type 7).
- 08:45:44 to 08:46:33: Additional wrong-password Kerberos pre-auth attempts from 10.10.8.112 (4771), indicating continued retries from a second source.
- 09:08:14: Account enabled by helpdesk-admin (4722) as part of applied remediation.
- 09:09:01: Successful interactive login on DESKTOP-FB022 (4624).
- 09:09 onward: User verified as logged in; no issues reported.

## Root Cause Statement
Primary cause: Account lockout triggered by repeated bad-password authentication attempts for FINBRIDGE\\cthompson.
Contributing factor: Ongoing incorrect credential retries likely originated from a stale credential source, including at least one additional source IP (10.10.8.112), which increased lockout risk and sustained failures.

## 5 Whys Analysis
1. Why could the user not log in?
   - The account was locked, blocking interactive authentication.
2. Why was the account locked?
   - The lockout threshold was reached after multiple bad-password attempts.
3. Why were there multiple bad-password attempts?
   - Incorrect credentials were retried repeatedly from endpoint context(s), including DESKTOP-FB022 and source IP 10.10.8.112.
4. Why were incorrect credentials retried automatically/continuously?
   - A stale stored credential or credential-dependent process likely continued using an old password.
5. Why did stale credentials persist long enough to cause impact?
   - Preventive control gaps: no consistent post-password-change hygiene/checklist to update credential stores, tasks, and service identities across all active devices/sessions.

## Resolution Actions Applied
- Lockout condition addressed through helpdesk administrative action (account enable event recorded at 09:08:14).
- User validation performed with successful interactive login at 09:09:01 on DESKTOP-FB022.
- Incident status set to resolved after user confirmation and no immediate recurrence reported.

## Preventive Actions
1. Implement a standard stale-credential triage checklist for all lockout incidents.
   - Include Credential Manager, mapped drives, email/collab clients, VPN clients, browser auth stores, scheduled tasks, and services.
2. Add rapid source-correlation step in first-line response.
   - Correlate lockout events with caller workstation and Kerberos source IPs to isolate retry sources quickly.
3. Add a post-password-change user guidance pack.
   - Require sign-out/in and credential refresh across all enrolled devices to reduce stale retries.
4. Create monitoring alert for repeated 4771/4776 + imminent 4740 pattern for a single user.
   - Trigger early intervention before hard lockout where possible.
5. Improve closure quality.
   - Record exact retry source and remediation artifact in incident closure notes for trend analysis.

## Verification and Closure Criteria
- Successful interactive login captured (4624) for FINBRIDGE\\cthompson at 09:09:01.
- User confirmed restored access to host.
- No immediate recurring failures reported after resolution window.

## Residual Risk
If any unmanaged device, legacy app, scheduled task, or service still retains outdated credentials, lockout may recur. Continued short-term monitoring of 4625/4771/4776/4740 events for this account is recommended.

## Lessons Learned
- Single-user incidents with rapid 4776/4625 sequences followed by 4740 are highly indicative of credential retry-driven lockout.
- Presence of a secondary source IP during the same window is a strong indicator to broaden endpoint/process checks beyond the primary workstation.
