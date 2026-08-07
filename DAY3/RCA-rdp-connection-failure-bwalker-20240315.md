# Root Cause Analysis — RDP Connection Failure and Account Lockout (bwalker)

## Document Header

| Field | Detail |
|-------|--------|
| Incident ID | INC-[REDACTED] |
| Date | 2024-03-15 |
| Service | Remote Desktop Protocol (RDP) |
| Affected User | FINBRIDGE\bwalker |
| Source Client | 10.10.5.44 |
| Impact Window | 14:01:02 to 14:22:09 |
| Duration | ~21 minutes |
| Analyst | DWP Desktop/Endpoint Engineer |
| Classification | OFFICIAL |

---

## 1. Incident Summary

A user was unable to establish an RDP session due to repeated authentication failures from the same client IP. The failed sign-ins triggered account lockout, which prevented access until the account state was corrected. A later attempt from the same client succeeded.

The issue was not caused by network transport failure, RDP listener outage, or host unavailability. The primary failure mode was invalid credentials followed by lockout enforcement.

---

## 2. Timeline of Events

| Time | Log | Event ID | Level | Key Detail |
|------|-----|----------|-------|------------|
| 14:01:02 | System (TermDD) | 56 | Error | Protocol stream error; client disconnected (10.10.5.44) |
| 14:01:02 | System (RdpCoreTS) | 140 | Warning | RDP connection failed: incorrect username or password |
| 14:01:04 | Security | 4625 | Audit Failure | Logon type 10 failure for FINBRIDGE\bwalker from 10.10.5.44 |
| 14:03:18 | Security | 4625 | Audit Failure | Second remote interactive auth failure |
| 14:05:33 | Security | 4625 | Audit Failure | Third remote interactive auth failure |
| 14:05:34 | Security | 4740 | Audit Failure | Account FINBRIDGE\bwalker locked out; caller 10.10.5.44 |
| 14:22:07 | System (RdpCoreTS) | 131 | Information | Server accepted new TCP connection from 10.10.5.44 |
| 14:22:09 | Security | 4624 | Audit Success | Successful remote interactive logon for FINBRIDGE\bwalker |

---

## 3. Technical Analysis

### 3.1 Event Correlation

1. RDP handshake and security negotiation reached authentication stage.
2. Authentication failed repeatedly with explicit bad credential indicators (Event 140 and Event 4625).
3. Account lockout policy triggered (Event 4740) immediately after repeated failures.
4. Later, transport and authentication both succeeded from the same endpoint (Events 131 and 4624).

This sequence confirms endpoint and RDP service availability while isolating failure to credential validity and account state.

### 3.2 About Event 56 (TermDD)

Event 56 appears at the start of the sequence and is commonly logged when the session is torn down after security/auth protocol failure. In this timeline it is a secondary symptom, not the primary root cause, because:

- RdpCoreTS Event 140 explicitly reports bad username/password.
- Security Event 4625 repeats with logon type 10 from the same source.
- A later successful logon from the same source shows no persistent protocol incompatibility.

---

## 4. Root Cause

### Primary Root Cause

Repeated invalid credentials for account FINBRIDGE\bwalker on RDP logon type 10 triggered account lockout policy.

### Contributing Factors

- Multiple retry attempts from the same client without credential correction.
- No immediate user-side recovery path before lockout threshold was reached.
- Lockout policy behaved as designed, but operationally increased downtime without rapid self-service recovery.

### Not Supported by Evidence

- RDP service outage.
- Firewall/network path outage.
- Persistent protocol/cipher mismatch.
- Host instability.

---

## 5. Impact Assessment

| Category | Detail |
|----------|--------|
| User impact | Single user unable to access remote session during impact window |
| Business impact | Short productivity interruption (~21 minutes) |
| Security impact | Protective control succeeded (lockout blocked repeated failed auth) |
| Data impact | No evidence of unauthorised access |
| Scope | Single account, single source IP observed |

---

## 6. Five Whys

1. Why did RDP fail initially?  
Because authentication failed for remote interactive logon.

2. Why did authentication fail?  
Because the submitted username/password pair was invalid.

3. Why did the user remain unable to connect?  
Because repeated failures triggered account lockout.

4. Why did lockout extend outage duration?  
Because access then required credential/account recovery before another successful attempt.

5. Why is this recurring risk present?  
Because failed-auth handling relies on manual recovery steps rather than immediate user self-service and guardrails.

---

## 7. Corrective and Preventive Actions

| Priority | Action | Owner |
|----------|--------|-------|
| High | Validate exact lockout threshold and observation window in account lockout policy; confirm policy intent for RDP use cases | IAM / Security |
| High | Confirm user recovery path (unlock/reset process) and ensure rapid service desk playbook for RDP lockouts | Service Desk |
| Medium | Enable/verify self-service password reset and user enrollment where policy permits | IAM |
| Medium | Add monitoring alert for Event 4625 bursts followed by 4740 for early intervention | SOC / Endpoint Ops |
| Low | Publish user guidance: credential format for domain logon and lockout avoidance steps | End User Support |

---

## 8. Validation Checks Completed

- Same source IP observed for failures and later success.
- Successful Event 4624 confirms eventual credential/account recovery.
- System and Security logs are internally consistent with auth-failure-to-lockout chain.

---

## 9. Closure Statement

Incident closed as credential-related RDP authentication failure culminating in policy-enforced account lockout. Service/path health remained functional; no infrastructure defect identified.

---

## 10. Sign-Off

| Role | Name | Date |
|------|------|------|
| Analyst | [Name] | [Date] |
| Service Desk Lead | [Name] | [Date] |
| IAM/Security Reviewer | [Name] | [Date] |
