#!/usr/bin/env bash
#
# AKVM Panel — Secure Installer
# Downloads the private source code using a GitHub access token, then runs
# the real install.sh. Nobody can see or download your code without a valid
# token — this script alone (public) does nothing useful on its own.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Akvmpanel/get-akvm/main/get.sh)
#
set -euo pipefail

GITHUB_USER="Akvmpanel"
PRIVATE_REPO="v1"
BRANCH="main"

echo "========================================"
echo "   AKVM Panel — Secure Installer"
echo "========================================"
echo ""

# Token can be passed via env var to skip the prompt:
#   AKVM_TOKEN=ghp_xxx bash <(curl -fsSL ...)
if [[ -z "${AKVM_TOKEN:-}" ]]; then
    read -srp "Enter your access token: " AKVM_TOKEN
    echo ""
fi

if [[ -z "$AKVM_TOKEN" ]]; then
    echo "No token provided. Aborting."
    exit 1
fi

# Domain is optional — if given, install.sh will set up Nginx + a free SSL
# cert (Let's Encrypt) so the panel is reachable at https://yourdomain
# instead of http://IP:5000. Leave blank to skip and use IP:PORT only.
#   AKVM_DOMAIN=panel.example.com bash <(curl -fsSL ...)
if [[ -z "${AKVM_DOMAIN:-}" ]]; then
    read -rp "Enter your domain (leave blank to skip, use IP:5000 instead): " AKVM_DOMAIN
    echo ""
fi
export AKVM_DOMAIN

WORKDIR="$(mktemp -d /tmp/akvm-install-XXXXXX)"
cleanup() {
    cd / 2>/dev/null || true
    rm -rf "$WORKDIR"
}
trap cleanup EXIT
cd "$WORKDIR"

echo "Downloading source..."
HTTP_CODE=$(curl -s -o akvm.tar.gz -w "%{http_code}" \
    -H "Authorization: token ${AKVM_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -L "https://api.github.com/repos/${GITHUB_USER}/${PRIVATE_REPO}/tarball/${BRANCH}")

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "Download failed (HTTP $HTTP_CODE). Check your token and try again."
    exit 1
fi

tar -xzf akvm.tar.gz --strip-components=1
rm -f akvm.tar.gz

echo "Source downloaded. Running install.sh..."
echo ""

if [[ -f install.sh ]]; then
    chmod +x install.sh
    sudo -E AKVM_DOMAIN="$AKVM_DOMAIN" bash install.sh || AKVM_DOMAIN="$AKVM_DOMAIN" bash install.sh
else
    echo "install.sh not found in the repo."
fi
# cleanup runs automatically via the EXIT trap — the downloaded source
# never stays visible in your workspace/file explorer.
