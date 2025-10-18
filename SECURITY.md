# Security & Safety Policy — Slipstream

Slipstream is a physical motion system. Certain failures (software, firmware, electronics, or mechanical)
can produce unsafe motion, electrical hazards, or physical injury. Because of this:

**Do NOT file public GitHub issues for safety-critical or security-relevant findings.**

Instead, read and follow the disclosure instructions below.

---

## What Should Be Reported Privately

Report privately if the issue could result in any of the following:

- **Uncontrolled or unintended motion** (runaway, overshoot, oscillation, limit bypass)
- **Bypassing or disabling Emergency Stop**
- **Incorrect current/voltage limiting or relay control**
- **Firmware faults that prevent safe shutdown / safe-mode**
- **Telemetry or comms faults that could cause hazardous actuation**
- **Injection / spoofing / replay of commands causing unsafe motion**
- **Hardware wiring or PCB defects that can lead to fire, shock, or unsafe failure**

If you are unsure if the issue is safety relevant — **treat it as if it is.**

---

## Private Disclosure Method

Contact the maintainers (do not open a public issue):

```

https://www.linkedin.com/in/penoelo-thibeaud-6a092b235/

```

Use the subject line:

```

[SECURITY-Slipstream] <short description>

```

Include:
- A clear description of the issue
- Steps or conditions where it occurs
- Evidence (logs/photos/scope traces) if safe to collect
- Whether you reproduced it more than once
- Whether hardware could be damaged if reproduced again

---

## What Happens After Disclosure

1) We will acknowledge receipt within **14 days**.  
2) We will assess reproducibility and potential severity.  
3) We will develop a fix or mitigation (hardware, firmware, or doc update).  
4) We will coordinate disclosure timing if public fix is required.  

No security/safety issues will be publicly disclosed until a fix or mitigation exists.

---

## Scope

This policy covers all artifacts in the Slipstream repository and downstream use:
- Firmware (control, safety, telemetry handlers)
- PC software / telemetry mapping
- Motor drivers / PCB / wiring interfaces
- Mechanical safety features (limit stops, mounting, etc.)

---

## Responsible Use of Exploits

If you discover a vulnerability **do not actively exploit it on real hardware**
beyond what is minimally required to document the issue — uncontrolled testing can
damage equipment or injure users.

---

## Public Issues for Non-Safety Bugs

If a bug does **not** affect safety or security (e.g., docs typo, UI glitch, slow PID tuning),
open a normal GitHub issue using the templates in `.github/ISSUE_TEMPLATE/`.

---

Thank you for helping keep Slipstream **safe**, **reliable**, and **responsibly developed**.
