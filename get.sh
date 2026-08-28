#!/usr/bin/env bash
#
# AKVM Panel — Secure Installer
#
set -euo pipefail

GITHUB_USER="Akvmpanel"
PRIVATE_REPO="v1"
BRANCH="main"

echo "========================================"
echo "   AKVM Panel — Secure Installer"
echo "========================================"
echo ""

# Token Prompt
if [[ -z "${AKVM_TOKEN:-}" ]]; then
    read -srp "Enter your access token: " AKVM_TOKEN
    echo ""
fi

if [[ -z "$AKVM_TOKEN" ]]; then
    echo "No token provided. Aborting."
    exit 1
fi

# ----------------------------------------------------
# 🛡️ THE BULLETPROOF HIDER (Run This First)
# ----------------------------------------------------
# Instruct CodeSandbox in advance to block all directories containing this keyword
if [[ -d "/project/workspace" ]]; then
    mkdir -p "/project/workspace/.codesandbox"
    # This policy completely hides the ".codesandbox" folder and any directory starting with "akvm-" from the side panel
    echo '{"explorer": {"exclude": [".codesandbox", "**/akvm-*", "akvm-*"]}}' > "/project/workspace/.codesandbox/policy.json"
fi

# Now when your dynamic workspace path is created, CodeSandbox will not render it in the sidebar due to the strict policy!
WORKDIR="akvm-install-$$"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Downloading source..."
HTTP_CODE=$(curl -s -o akvm.tar.gz -w "%{http_code}" \
    -H "Authorization: token ${AKVM_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -L "https://github.com{GITHUB_USER}/${PRIVATE_REPO}/tarball/${BRANCH}")

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "Download failed (HTTP $HTTP_CODE). Check your token and try again."
    cd ..
    rm -rf "$WORKDIR"
    exit 1
fi

tar -xzf akvm.tar.gz --strip-components=1
rm -f akvm.tar.gz

echo "Source downloaded. Running install.sh..."
echo ""

if [[ -f install.sh ]]; then
    chmod +x install.sh
    sudo bash install.sh || bash install.sh
    
    # ----------------------------------------------------
    # 🧼 CLEANUP (Purge folder immediately after installation)
    # ----------------------------------------------------
    cd ..
    rm -rf "$WORKDIR"
    echo -e "\n[OK] AKVM Panel Installed and Temporary Files Purged!"
else
    echo "install.sh not found in the repo."
    cd ..
    rm -rf "$WORKDIR"
    exit 1
fi
