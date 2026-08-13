# Structured Triage Summary

## Summary (one line)
User cannot connect to VDI today from home Wi-Fi, despite it working on Friday.

## Impact (who/how many/ business urgency)
- Who is impacted: Single end user (to confirm)
- How many affected: One user/device reported (to confirm)
- Business urgency: User currently unable to access VDI for work tasks (to confirm business-critical activities blocked)

## known facts
- Issue statement: "can't get on the VDI thing today"
- Error/symptom: "keeps saying cannot connect"
- Last known good: "worked friday"
- Location/network context: "im at home on wifi"

## Missing information to gather
- Exact error message text and where it appears (VDI client, browser, gateway, or MFA step)
- Username, department, and callback details (to confirm)
- Exact time first observed today and whether issue is continuous or intermittent
- Whether any colleagues are affected (to confirm)
- Device type and OS currently in use
- Whether home internet is stable and other internet services are working
- Whether VPN is required for this VDI path and current VPN status
- Whether MFA prompt is received and completed successfully
- Whether reconnecting after reboot changes behavior
- Whether issue occurs on alternate network (for example mobile hotspot) (to confirm)
- Whether any recent password change, account lockout, or policy update occurred

## likely catagory
- Remote access / VDI connectivity failure from home network (to confirm)

## Suggest first diagnostic step
- Capture the exact "cannot connect" error message and connection stage, then run a quick isolation check: verify internet stability and test VDI connection once after a reboot from the same home Wi-Fi (to confirm result).