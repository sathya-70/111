# Known-Error Record: Printer Mapping Loss – 3rd Floor Win11 Upgrade

**Symptom:** Users on 3rd floor unable to access mapped printers after Windows 11 upgrade; printer mappings missing from device after logon.

**Cause:** Logon script failed to re-apply because it referenced the old OS drive path, which no longer exists in the upgraded Windows 11 environment.

**Scope:** All 3rd floor users/devices upgraded to Windows 11 where the logon script runs on logon.

**Workaround:** (to confirm) Manually re-map printers or manually run the logon script with updated OS drive path.

**Permanent fix:** Update logon script to reference the new OS drive path in Windows 11 environment, re-apply/re-run script on affected devices, validate printer access before closing.
