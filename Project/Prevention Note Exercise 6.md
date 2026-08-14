# Prevention Note: Exercise 6
## Floor 6 Incident Cluster Prevention Control

**Incidents addressed:** Unauthorized Copilot/search exposure risk, slow logins, login failures, and missing desktop shortcuts on Floor 6 devices  
**Date:** Monday morning, 14 August 2026  
**Root Cause (most likely):** Multiple Friday changes were allowed into production without a single pre-production validation gate covering permissions, Copilot connector scope, endpoint provisioning load, and desktop baseline outcomes.

---

## Specific Process Control: Pre-Monday Floor 6 Change Validation Gate

### What It Is
A **mandatory Sunday 22:00 validation gate** for any Floor 6 change affecting document access, Copilot/search, Intune policy, application deployment, or desktop configuration. The gate combines an automated PowerShell validation run on pilot devices with a targeted access test for Copilot-connected content before production remains open for Monday.

### How It Works
1. **Run on 2-3 Floor 6 pilot devices and 1 controlled test account** kept aligned to the production ring.
2. **Validate Copilot and access boundaries before sign-off:**
   - Test that restricted client/matter content is not returned by Copilot/search for a user who should not have access
   - Confirm repository ACLs, inheritance, and connector entitlement scope match expected permissions
   - Record pass/fail evidence for at least one allowed query and one denied query
3. **Validate login and provisioning health:**
   - Force policy/app sync on pilot devices
   - Measure sign-in to usable desktop time
   - Check for failed sign-ins, conditional access/compliance errors, and first-logon app install delays
4. **Validate endpoint desktop baseline:**
   - Confirm required shortcuts exist in the correct desktop path
   - Confirm Outlook, Teams, and Edge launch successfully
   - Check for profile-load or temporary-profile indicators
5. **Generate a single go/no-go report:**
   - Success: "Floor 6 change set validated; safe for Monday production"
   - Failure: "STOP - Floor 6 validation failed at [specific control]; do not proceed until fixed or rolled back"
6. **Require named approval** from Endpoint plus Service Owner before the change remains live.
7. **If any control fails:** hold, roll back, or remove the affected scope before Monday morning.

### Why This Would Have Prevented The Incident
- The Copilot issue would have been caught because an unauthorized test query should have failed; a successful return would immediately block release.
- The login issue would have been exposed on pilot devices when policy, app install, and sign-in workload were tested together rather than in isolation.
- The shortcut issue would have appeared in the same validation run because the desktop baseline check verifies expected icons and profile state after login.
- The real failure was not just a missing desktop check; it was the absence of one control that tested the whole Floor 6 change set before Monday users arrived.

### Implementation
- **Owner:** IT Infrastructure, Endpoint Engineering, and the service owner for the affected repository/app
- **When:** Required for every Friday or weekend Floor 6 production change
- **Tooling:** Scheduled PowerShell validation, controlled Copilot/access test account, and a standard go/no-go checklist
- **Estimated effort:** 4-6 hours to build initially; 10-15 minutes per weekly validation run
- **No new hardware required; uses existing pilot devices and admin tooling**

---

## Acceptance Criteria
✓ Unauthorized Copilot/search retrieval is detected before production remains open  
✓ Pilot-device login completes within agreed threshold with no repeated sign-in or compliance failures  
✓ Required desktop shortcuts and core apps are present after validation login  
✓ Single pass/fail report generated and reviewed before Monday business start  
✓ Any failed control automatically triggers hold-or-rollback decision
