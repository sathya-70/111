Symptom : Users see a black screen after login on AVD Finance desktops. Some sessions recover after about 30 seconds, while others disconnect and require reconnect.

Cause : A graphics/display stack regression introduced by the 02:00 image update on POOL-FIN-01 caused Desktop Window Manager (dwm.exe) to crash in Intel module igdumd64.dll during post-login desktop initialization. This produced session instability and black-screen behavior.

Scope : The incident affected about 40% of users in POOL-FIN-01 between about 07:00 and 10:00 on 2024-03-15. POOL-FIN-02 was unaffected.

Workaround : Pause further rollout of the updated image branch and drain/isolate affected POOL-FIN-01 capacity to reduce user exposure. Restore service by moving POOL-FIN-01 back to known-good baseline capacity/remediated image path.

Permanent fix: Keep POOL-FIN-01 on the known-good baseline/remediated image path validated for stable post-login behavior. Add mandatory canary logon-cycle testing with DWM crash checks and block promotion on any dwm.exe Application Error Event 1000.

How to spot it: On affected hosts, look for Event 21 (logon success) followed within seconds by Application Error Event 1000 showing dwm.exe faulting in igdumd64.dll (exception 0xc0000005), then Event 40 (disconnect) and Event 9009 (DWM exited). On unaffected comparison hosts in the same window, Event 9011 (DWM started successfully) appears and Event 1000 entries are absent.
