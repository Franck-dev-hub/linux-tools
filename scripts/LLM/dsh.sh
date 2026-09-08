#!/usr/bin/env bash

# Mise à jour automatique au lancement
git pull origin main
pnpm install
pnpm run build

# Nettoyage automatique des processus enfants à la fermeture du script
cleanup() {
  echo "Fermeture de dsh et libération des ressources..."
  pkill -P $$
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Lancement de dsh
pnpm dsh web
