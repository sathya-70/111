# Known-Error Record - cthompson Account Lockout (2024-03-15)

Symptom : User FINBRIDGE\cthompson is unable to log in. Interactive authentication to the endpoint fails.

Cause : The account was locked out after repeated bad-password authentication attempts. Continued incorrect credential retries from DESKTOP-FB022 and source IP 10.10.8.112 sustained the failure pattern.

Scope : Single-user impact only (FINBRIDGE\cthompson). No broad outage was reported.

Workaround : Apply helpdesk administrative action to clear lockout state (account enable event 4722 was recorded at 09:08:14). Validate access by signing in interactively on DESKTOP-FB022 (successful 4624 recorded at 09:09:01).

Permanent fix: Remove or contain stale credential retry sources and use a standard stale-credential triage checklist across Credential Manager, mapped drives, email/collab clients, VPN clients, browser auth stores, scheduled tasks, and services. Add rapid source-correlation and monitoring for repeated 4771/4776 patterns before 4740 lockout.

How to spot it: Look for 4776 with error 0xC000006A (wrong password), repeated 4625 bad-password events, followed by 4740 account lockout and 4625 with "Account locked out". Additional 4771 with failure code 0x18 from another source (for this incident: 10.10.8.112) is a key signal of ongoing retry behavior.
