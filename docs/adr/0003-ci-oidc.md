# ADR 0003 : CI par OIDC, plan uniquement

**Statut** : accepté
**Décision** : GitHub Actions assume un rôle lecture seule via OIDC (aucune clé) et exécute `plan` ; l'`apply` reste manuel.
**Conséquences** : le rôle peut assumer `OrganizationAccountAccessRole` (administrateur des comptes membres) pour rafraîchir l'état. Amélioration : créer des rôles lecture seule dédiés dans chaque compte membre.
