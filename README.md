# Slipstream
lighter, easier-to-carry body and a more affordable motion platform

# Setup guideline
1. Clone repository
```git clone https://github.com/Pepen0/Slipstream.git```
2. fill up .env file
- Create a GitHub personal access token (PAT):
    - Open https://github.com/settings/tokens
    - Prefer a Fine‑grained token: Settings → Developer settings → Personal access tokens → Fine‑grained tokens.
    - Grant access to the Slipstream repository.
    - Required permissions:
        - Contents: Read & write (needed for branch creation)
        - Issues: Read (to read the payload)
    - Alternatively, use a classic PAT with the repo scope for a test repo.
- Add the token to your .env:
- Add your GitHub username to .env
```
# --- secrets ---
GITHUB_TOKEN=ghp_yourRealTokenHere

# --- repo info ---
REPO_OWNER=Pepen0
REPO_NAME=Slipstream
REPO_FULL_NAME=Pepen0/Slipstream
DEFAULT_BRANCH=main

# --- issue payload ---
ISSUE_NUMBER=1234
ISSUE_TITLE=Docs: Improve quickstart
SENDER_LOGIN=yourUsername

# --- act runtime prefs ---
UBUNTU_IMAGE=ghcr.io/catthehacker/ubuntu:act-24.04
ARCH=linux/amd64
```
- Copy the contents of .env.example to .env at the root of the repository.

# Testing guideline
## How to test workflow (locally)
1. install required librearies
- `brew install act`
- `brew install --cask docker`
2. Verify that the required environment variables are set in .env file
3. make script executable
```chmod +x scripts/run-act.sh```
4. run script
```./scripts/run-act.sh```