# FinBridge Win11 Migration — End-User Feedback Theme Analysis

**Date:** 2026-08-12
**Source:** 50 post-migration comments from FinBridge staff
**Analyst:** DWP Endpoint Team

---

## Theme Clusters

---

### Account Lockout & AVD Sign-in Failure
**Count:** 7 (IDs: 1, 11, 16, 21, 29, 37, 45)
**Severity:** Blocker

Representative quotes:
- *"Cannot log in to AVD at all since this morning. Tried 3 times. Urgent."*
- *"Account locked again, this is the third time this week."*

---

### Floor 3 Printer Not Mapping
**Count:** 6 (IDs: 3, 13, 19, 26, 35, 43)
**Severity:** Blocker

Representative quotes:
- *"Printer on floor 3 still broken, whole team can't print client docs."*
- *"Printer on floor 3 – team has given up and is walking to floor 2 to print."*

---

### VPN Instability
**Count:** 4 (IDs: 5, 24, 39, 47)
**Severity:** Blocker

Representative quotes:
- *"VPN keeps dropping every 10 minutes, very frustrating for calls."*
- *"VPN dropped 4 times in one hour today, unacceptable for client work."*

---

### OneDrive Files Missing or Not Syncing
**Count:** 4 (IDs: 14, 23, 34, 42)
**Severity:** Blocker

Representative quotes:
- *"My OneDrive files are missing! This is urgent, need them for a meeting."*
- *"Missing files in OneDrive – checked three times, still not there."*

---

### Shared Drive (S:) Inaccessible
**Count:** 3 (IDs: 7, 18, 31)
**Severity:** Blocker

Representative quotes:
- *"Can't access shared drive S: – says permission denied."*
- *"Cannot access S drive, blocking me from finishing month-end reports."*

---

### Slow Login Performance
**Count:** 3 (IDs: 9, 32, 49)
**Severity:** Friction

Representative quotes:
- *"Login is so slow now, takes 5 minutes some mornings."*
- *"Login speed has been consistently slow all week, not just today."*

---

### Desktop & Taskbar Personalisation Not Migrated
**Count:** 6 (IDs: 2, 6, 17, 22, 27, 48)
**Severity:** Friction

Representative quotes:
- *"Where did my desktop shortcuts go? Had to recreate them manually."*
- *"Some of my pinned taskbar apps disappeared after the update."*

---

### UI & App Navigation Changes
**Count:** 8 (IDs: 8, 12, 15, 25, 30, 36, 41, 44)
**Severity:** Minor

Representative quotes:
- *"New start menu layout is confusing, hard to find my apps."*
- *"Start menu search doesn't find some apps I use daily."*

---

### Positive Migration Experience
**Count:** 9 (IDs: 4, 10, 20, 28, 33, 38, 40, 46, 50)
**Severity:** Positive

Representative quotes:
- *"Love how fast the new laptop is! Much better than before."*
- *"Really smooth transition overall, thank you to the IT team."*

---

## Summary

| Theme | Count | Severity |
|---|---|---|
| Account Lockout & AVD Sign-in Failure | 7 | Blocker |
| Floor 3 Printer Not Mapping | 6 | Blocker |
| VPN Instability | 4 | Blocker |
| OneDrive Files Missing or Not Syncing | 4 | Blocker |
| Shared Drive (S:) Inaccessible | 3 | Blocker |
| Slow Login Performance | 3 | Friction |
| Desktop & Taskbar Personalisation Not Migrated | 6 | Friction |
| UI & App Navigation Changes | 8 | Minor |
| Positive Migration Experience | 9 | Positive |
| **Total** | **50** | |

---

## Top 3 Priorities — Act Today

Ranking method: Blocker severity gates the top positions before volume is applied. A single Blocker outranks any volume of Minor/Friction comments. Within the same severity tier, volume and business impact break the tie.

---

### Rank 1 — Account Lockout & AVD Sign-in Failure
**Count:** 7 | **Severity:** Blocker

**Why it ranks here:** Highest volume among all Blockers and the pattern is worsening — multiple users report being locked out repeatedly across several days, meaning it is not a one-off. Complete inability to sign in means zero productivity; no other issue produces a harder stop.

**Manager summary:** Seven staff cannot reliably access AVD due to repeated account lockouts, with some users hitting the issue three times in one week — this needs an identity/authentication investigation today before the affected user count grows.

---

### Rank 2 — Floor 3 Printer Not Mapping
**Count:** 6 | **Severity:** Blocker

**Why it ranks here:** Second-highest Blocker volume and the impact is team-wide, not individual — the entire floor is affected. Comments span multiple days and reference client meetings at risk, meaning the business exposure compounds the longer it remains open.

**Manager summary:** The floor 3 printer has failed to map on login since migration, the whole team is physically walking to floor 2 to print, and at least one client meeting deadline has been cited — a print server or GPO mapping fix is needed urgently.

---

### Rank 3 — OneDrive Files Missing or Not Syncing
**Count:** 4 | **Severity:** Blocker

**Why it ranks here:** Tied on volume with VPN instability (4 each), but OneDrive ranks higher because missing files carry a data-loss risk perception and comments reference hard deadlines (Q1 report, end-of-day delivery). VPN drops are disruptive; perceived data loss is a compliance and trust issue.

**Manager summary:** Four users report OneDrive files missing or showing sync errors post-migration, with at least one citing a same-day reporting deadline — this needs triage now to confirm whether data is genuinely missing or a sync/profile path issue before it escalates to a data integrity incident.
