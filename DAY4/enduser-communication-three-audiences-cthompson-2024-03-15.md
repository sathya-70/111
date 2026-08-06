# End-User Communication Pack (Same Facts, Three Audiences)

Date of incident: 2024-03-15
Incident scope: one user (cthompson) only
Service impact: user could not log in
Root cause: repeated wrong-password retries from the user PC and a second source caused account lockout
Resolution confirmed: 09:09 AM local

## Audience 1 - Non-Technical Executive
Your access and data are safe. On 15 March, one user could not log in after repeated wrong-password retries from their PC and another device locked the account. Helpdesk stopped the retries and re-enabled access, and successful sign-in was confirmed at 09:09 with no wider impact. Action: none unless this repeats; then contact Service Desk.

## Audience 2 - Affected End-User Team (10 people, non-technical)
Your access and data are safe. On 15 March, one user could not log in because an old password was being retried from their PC and another device, which locked the account. Helpdesk stopped the retries and re-enabled access, and sign-in worked again at 09:09 with no wider impact. If you see this, sign out, try once more, then contact Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: 2024-03-15 single-user lockout, FINBRIDGE\\cthompson.

Root cause:
- Repeated bad-password attempts triggered AD lockout.
- Evidence chain: 4776 (0xC000006A) at 08:44:01, 4625 at 08:44:03/08:44:28/08:44:55, 4740 at 08:44:56, then 4625 (locked out, type 7) at 08:45:10.
- Continued wrong-password retries from second source: 4771 (0x18) at 08:45:44/08:46:01/08:46:33 from 10.10.8.112.

Exact action taken:
- Helpdesk admin cleared lockout state via account enable action (4722 at 09:08:14).
- Retry sources were stopped/contained (stale credential path addressed).
- User validation performed on DESKTOP-FB022.

Config detail:
- Primary workstation/caller: DESKTOP-FB022.
- Secondary retry source IP: 10.10.8.112.
- Single-user blast radius only; no wider outage.

Verification step:
- 4624 success at 09:09:01 for FINBRIDGE\\cthompson on DESKTOP-FB022.
- No immediate recurrence reported post-resolution window.

Preventive action needed:
- Use stale-credential triage checklist on every lockout: Credential Manager, mapped drives, Outlook/Teams/OneDrive/VPN clients, browser auth stores, scheduled tasks, services.
- Correlate lockout caller workstation with Kerberos source IPs early.
- Add monitoring for repeated 4771/4776 patterns leading toward 4740.
