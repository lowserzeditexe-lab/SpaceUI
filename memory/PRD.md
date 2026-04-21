# SpaceUI — PRD

## Problème original
Kit UI Roblox minimaliste (SpaceUI) — site de documentation React + backend FastAPI servant des scripts Lua.

## Architecture
- **Frontend** : React (port 3000) — documentation, exemples, composants
- **Backend** : FastAPI (port 8001) — sert les JSON de données et les fichiers .lua
- **Data** : `/app/backend/spaceui/` — components.json, examples.json, spaceui.lua

## Ce qui a été implémenté

### Session initiale
- Projet SpaceUI complet (UI Kit Roblox monochrome)
- 4 exemples Lua : Hello World, Settings Panel, Combat Toolkit (ESP+Aim+Fly), Ultimate Toolkit

### Mise à jour — 2026-04-21
- **Section Money de l'exemple `ultimate-toolkit` mise à jour** :
  - Supprimé : Value Watcher automatique, Remote Spy (hookmetamethod), GiveMoney RemoteEvent, BankTransaction, TurfFarm
  - Ajouté : accès direct à `LocalPlayer.Valuestats.Wallet` et `LocalPlayer.Extra`
  - Nouvelles fonctions Lua : `getWallet()`, `getExtra()`
  - Nouvelle UI tabMoney :
    - Section **Wallet** (Valuestats.Wallet) : label temps réel, slider montant, bouton Ajouter, bouton Max
    - Section **Extra** (LocalPlayer.Extra) : label temps réel, bouton Ajouter, bouton Max

## Backlog / Améliorations possibles
- Ajouter d'autres jeux Roblox comme exemples (pas seulement Bronx Hood)
- Support multi-versions du script Lua
- Page de changelog
