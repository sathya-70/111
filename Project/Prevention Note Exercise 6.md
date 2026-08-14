# Prevention Note: Exercise 6
## Floor 6 Login & Desktop Configuration Incident

**Incident:** Slow logins (5–10 min), missing desktop shortcuts, login failures on Floor 6 devices  
**Date:** Monday morning, 14 August 2026  
**Root Cause (assumed):** Change to Group Policy or desktop baseline configuration not validated before production deployment

---

## Specific Process Control: Pre-Monday Automated Baseline Validation

### What It Is
A **scheduled PowerShell validation script** that runs on **Sunday evening (22:00)** on designated Floor 6 staging/pilot devices to catch configuration drift or policy changes before users arrive Monday morning.

### How It Works
1. **Script runs on 2–3 staging devices** (Floor 6 test machines kept in sync with production baseline)
2. **Verifies all required baselines:**
   - All expected desktop shortcuts exist and have correct target paths
   - Group Policy applied successfully (gpupdate /force; check event log for GP errors)
   - Network connectivity to domain controller and file shares
   - Critical applications launch without error (Outlook, Teams, Edge)
   - User logon time to desktop (must be ≤ 3 minutes in test environment)
3. **Generates automated pass/fail report:**
   - Success: "Floor 6 baseline validated; safe for Monday production"
   - Failure: "WARNING – Floor 6 baseline check failed at [specific step]; investigate before Monday"
4. **Email sent to** Floor 6 Team Lead + IT Infrastructure team Sunday 22:30
5. **If failure:** Rollback procedure is triggered or change is held until Monday investigation completes

### Why This Catches the Incident
- The misconfiguration (whether policy, shortcuts, or network routing) would **fail validation on the staging device Sunday evening**
- IT team has **8 hours before Monday morning** to investigate, roll back, or fix
- Users never see the issue on Monday

### Implementation
- **Owner:** IT Infrastructure / Endpoint Team
- **When:** Implement before next change window to Floor 6
- **Tool:** PowerShell script in scheduled task (System account, staging machines only)
- **Estimated effort:** 4 hours to build; <2 minutes to run
- **No new hardware or licensing required**

---

## Acceptance Criteria
✓ Script successfully validates all baseline elements  
✓ Report generated and emailed to stakeholders  
✓ Runs reliably every Sunday 22:00 with <5 minute execution time  
✓ False positive rate < 10% (validated in staging before production)
