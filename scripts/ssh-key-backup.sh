#!/usr/bin/env bash
# Backup ~/.ssh/id_ed25519 to Proton Drive (for wipe / new-Mac recovery).
set -euo pipefail

SRC_KEY="${HOME}/.ssh/id_ed25519"
SRC_PUB="${HOME}/.ssh/id_ed25519.pub"

PD_ROOT="$(ls -d "${HOME}/Library/CloudStorage"/ProtonDrive-*-folder 2>/dev/null | head -1 || true)"
if [[ -z "${PD_ROOT}" ]]; then
  echo "Proton Drive folder not found under ~/Library/CloudStorage." >&2
  echo "Sign into Proton Drive, then re-run." >&2
  exit 1
fi

DEST="${PD_ROOT}/SSHKeys"
mkdir -p "${DEST}"

if [[ ! -f "${SRC_KEY}" || ! -f "${SRC_PUB}" ]]; then
  echo "Missing ${SRC_KEY} or ${SRC_PUB}" >&2
  exit 1
fi

install -m 600 "${SRC_KEY}" "${DEST}/id_ed25519"
install -m 644 "${SRC_PUB}" "${DEST}/id_ed25519.pub"

cat > "${DEST}/README.txt" <<'EOF'
SSH key backup for Joe Bak-Coleman (agenix + GitHub).

Restore on a new Mac:
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  cp id_ed25519 id_ed25519.pub ~/.ssh/
  chmod 600 ~/.ssh/id_ed25519
  chmod 644 ~/.ssh/id_ed25519.pub
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519

Then clone ~/dotfiles and run rebuild so agenix can decrypt secrets.
EOF

echo "Backed up SSH key to:"
echo "  ${DEST}/id_ed25519"
echo "  ${DEST}/id_ed25519.pub"
