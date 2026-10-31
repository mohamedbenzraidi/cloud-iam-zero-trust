# ADR 0002 : stratégie de SCP

**Statut** : accepté
**Décision** : 4 SCP (CloudTrail, root + sortie d'organisation, utilisateurs IAM + clés, régions) attachées directement aux comptes membres (limite de 5 SCP directes par cible respectée). Le compte de gestion n'est pas soumis aux SCP : il ne porte aucune charge de travail.
**Conséquences** : `us-east-1` doit rester autorisée (évènements globaux) ; aucune exception pour `OrganizationAccountAccessRole` sur la SCP IAM.
