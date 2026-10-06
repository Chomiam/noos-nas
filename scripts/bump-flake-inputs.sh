#!/usr/bin/env bash
# ==============================================================================
# Script d'automatisation de la mise à jour des inputs Flake — Noos NAS OS
# Fonctionne sur machine de dev locale (avec ou sans Nix local via SSH sur le NAS)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAS_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INPUT_ARG="${1:-}" # Optionnel : ex "noos-nas-dashboard" ou vide pour tout
NAS_HOST="${NAS_HOST:-192.168.1.20}"
NAS_USER="${NAS_USER:-chomiam}"

echo "🔄 [1/3] Mise à jour des dépendances Flake..."

if command -v nix &>/dev/null; then
  echo "✔ Nix local détecté."
  if [[ -n "${INPUT_ARG}" ]]; then
    (cd "${NAS_REPO_DIR}" && nix flake update "${INPUT_ARG}")
  else
    (cd "${NAS_REPO_DIR}" && nix flake update)
  fi
else
  echo "ℹ Nix n'est pas installé localement. Utilisation du NAS (${NAS_USER}@${NAS_HOST})..."
  if ssh -q -o BatchMode=yes -o ConnectTimeout=4 "${NAS_USER}@${NAS_HOST}" exit 2>/dev/null; then
    TMP_REMOTE_DIR="/tmp/noos-flake-bump-$$"
    ssh "${NAS_USER}@${NAS_HOST}" "mkdir -p ${TMP_REMOTE_DIR}"
    scp "${NAS_REPO_DIR}/flake.nix" "${NAS_REPO_DIR}/flake.lock" "${NAS_USER}@${NAS_HOST}:${TMP_REMOTE_DIR}/"
    if [[ -n "${INPUT_ARG}" ]]; then
      ssh "${NAS_USER}@${NAS_HOST}" "cd ${TMP_REMOTE_DIR} && nix flake update ${INPUT_ARG}"
    else
      ssh "${NAS_USER}@${NAS_HOST}" "cd ${TMP_REMOTE_DIR} && nix flake update"
    fi
    scp "${NAS_USER}@${NAS_HOST}:${TMP_REMOTE_DIR}/flake.lock" "${NAS_REPO_DIR}/flake.lock"
    ssh "${NAS_USER}@${NAS_HOST}" "rm -rf ${TMP_REMOTE_DIR}"
    echo "✔ flake.lock mis à jour avec succès depuis le NAS."
  else
    echo "⚠️ Impossible de joindre le NAS via SSH (${NAS_HOST}). Tentative via GitHub Actions..."
    if command -v gh &>/dev/null; then
      gh workflow run update-flake.yml -R Chomiam/noos-nas -f input="${INPUT_ARG}"
      echo "✔ Workflow GitHub Action déclenché sur Chomiam/noos-nas."
      exit 0
    else
      echo "❌ Impossible de mettre à jour : ni Nix local, ni accès NAS SSH, ni gh CLI disponible."
      exit 1
    fi
  fi
fi

echo "📝 [2/3] Validation des modifications..."
(cd "${NAS_REPO_DIR}" && git diff --stat flake.lock)

echo "📦 [3/3] Validation Git..."
CURRENT_BRANCH="$(cd "${NAS_REPO_DIR}" && git branch --show-current)"
(cd "${NAS_REPO_DIR}" && git add flake.lock)
COMMIT_MSG="chore(flake): mise à jour des dépendances flake.lock (${INPUT_ARG:-tous les paquets})"
(cd "${NAS_REPO_DIR}" && git commit -m "${COMMIT_MSG}") || echo "Aucun changement à commiter."

echo "🚀 Envoi sur origin/${CURRENT_BRANCH}..."
(cd "${NAS_REPO_DIR}" && git push origin "${CURRENT_BRANCH}")
echo "✅ Terminé avec succès !"
