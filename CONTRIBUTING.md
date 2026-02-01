# Contributing Guidelines — Slipstream (Team #12)

Thanks for helping improve Slipstream! This project accepts contributions to firmware (Code), software (Code), electronics, mechanical files and docs.

## TL;DR
- **Do not commit directly to `main`.**
- Create an issue → work on a **feature branch** → open a **PR to `main`**.
- **Rebase** your branch on `main` before opening the PR.
- Get **1 approvals**. **CI must pass.**
- Merge via **squash or rebase** (no merge commits).

---

## 1) Workflow

1. **Open an issue**
   - Describe the problem/feature and acceptance criteria.
   - Tag it (e.g., `firmware`, `pc-software`, `electronics`, `mechanical`, `docs`).

2. **Create a feature branch**
   - From the latest `main`:
     ```bash
     git checkout main
     git pull origin main
     git checkout -b feature/<short-description>
     ```
   - Examples:  
     `feature/pid-anti-windup` • `fix/serial-timeout` • `docs/assembly-notes`

3. **Make changes with small, focused commits**
   - Keep commits logically scoped and buildable.

4. **Rebase before PR**
   ```bash
   git fetch origin
   git rebase origin/main

* Resolve conflicts locally; ensure tests pass.

5. **Open a Pull Request (PR) to `main`**

   * Title: short and action-oriented (e.g., `feat: add PID anti-windup`).
   * Description: what/why, risks, and testing evidence.

6. **Reviews & Merge**

   * Require **1 approvals**.
   * All **CI checks must pass**.
   * Maintainer merges using **Squash & Merge** or **Rebase & Merge**.

---

## 2) Branches

* **Protected:** `main` (no direct commits, no force-push).
* **Feature branches:** `feature/*`, `fix/*`, `docs/*`.

---

## 3) Commit Messages (Conventional Commits recommended)

Examples:

* `feat(firmware): add PID anti-windup`
* `fix(pc-software): handle 250 Hz telemetry without drops`
* `docs(mechanical): add seat mounting torque table`

> Use present tense, minimal scope, and make the first line ≤ 72 chars.

---

## 4) Pull Request Checklist

Before opening a PR, ensure:

* [ ] Rebased on latest `main`.
* [ ] Builds locally; tests pass.
* [ ] Updated docs if behavior/usage changed.
* [ ] Kept PR small and focused.

Extra measures:
* [ ] Included minimal tests or logs/screenshots proving it works.

PR description should include:

* **What changed & why**
* **How it was tested** (commands, logs, screenshots, photos if hardware)
* **Impact** (breaking changes, migrations, safety considerations)

---

## 5) Tests & Minimum Evidence

Provide evidence appropriate to your change:

* **Firmware:** unit or bench logs; note latency/limits if relevant.
* **PC software:** unit tests or a short repro script; confirm no regressions.
* **Electronics:** ERC/DRC clean report or annotated screenshot.
* **Mechanical:** export updated STEP + drawing/PDF; note any interface changes.
* **Docs:** build or preview link/screenshots.

> If automated tests aren’t feasible, attach manual test notes (steps + result).

---

## 6) CI & Required Checks

* PRs must pass:

  * Build/format/lint jobs relevant to changed areas.
  * Any existing unit tests.
  * Fix or justify failures before requesting review.
  * Exception: the KiBot (KiCad documentation) check on PRs is informational and may fail for schematic-only projects; do not block PRs on it. Release/tag runs should pass.

---

## 7) Large/Binary Files

* Use **Git LFS** for large assets (e.g., STEP, renders, firmware binaries, Gerbers).
* Don’t commit generated build artifacts.

---

## 8) Code Review Etiquette

* Be specific and constructive; link to references if suggesting changes.
* Authors: respond to all comments or resolve them explicitly.
* Reviewers: approve only when the PR is **tested and functional**.

---

## 9) Licensing & Attribution

* By contributing, you agree your changes are provided under the project license.
* Ensure third-party content is license-compatible and properly attributed.

---

## 10) Security/Safety Reporting

If you discover a safety-critical or security issue (e.g., motion runaway, E-stop bypass):

* **Do not file a public issue.**
* Contact the maintainers directly (see repository README for contacts).

---

### Quick Start

```bash
# 1) Create branch
git checkout -b feature/<short-description>

# 2) Do work; commit in small chunks
git add .
git commit -m "feat: <what you added>"

# 3) Rebase, push, open PR
git fetch origin
git rebase origin/main
git push -u origin HEAD
# Open PR to main and request 2 reviews
```
