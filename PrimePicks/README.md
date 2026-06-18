# mobile_app

A new Flutter project.

## Getting Started

# Task Manager Admin - Flutter Application

Application d'administration professionnelle pour la gestion des tâches et projets.

## 🚀 Installation et Configuration

### Prérequis
- Flutter SDK (3.10.0 ou plus récent)
- Dart SDK (3.0.0 ou plus récent)
- Android Studio / VS Code
- Git

### Installation
1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd adminApp
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Générer les fichiers JSON** (Important !)
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configurer Firebase** (Optionnel)
   - Ajouter `google-services.json` dans `android/app/`
   - Ajouter `GoogleService-Info.plist` dans `ios/Runner/`

### Lancement
```bash
flutter run
```

## 🏗️ Architecture

### Structure du projet
```
lib/
├── app/
│   ├── core/
│   │   ├── constants/     # Constantes de l'app
│   │   ├── services/      # Services (API, Storage)
│   │   ├── theme/         # Thèmes et styles
│   │   ├── translations/  # Internationalisation
│   │   └── widgets/       # Widgets réutilisables
│   ├── data/
│   │   └── models/        # Modèles de données
│   ├── modules/
│   │   ├── auth/          # Authentification
│   │   ├── dashboard/     # Tableau de bord
│   │   ├── users/         # Gestion utilisateurs
│   │   ├── projects/      # Gestion projets
│   │   ├── tasks/         # Gestion tâches
│   │   ├── reports/       # Rapports
│   │   └── profile/       # Profil utilisateur
│   └── routes/            # Navigation
└── main.dart
```

### Technologies utilisées
- **GetX** - Gestion d'état et navigation
- **Dio** - Requêtes HTTP
- **Hive** - Stockage local
- **Firebase** - Authentification et notifications
- **FL Chart** - Graphiques
- **JSON Serializable** - Sérialisation automatique

## 🌍 Fonctionnalités

### ✅ Authentification
- Connexion JWT sécurisée
- Gestion des tokens automatique
- Validation des rôles (Admin uniquement)

### ✅ Dashboard
- Statistiques en temps réel
- Graphiques interactifs
- Activités récentes
- Métriques de performance

### ✅ Gestion des Utilisateurs
- CRUD complet
- Filtres et recherche
- Assignation de rôles
- Interface intuitive

### ✅ Gestion des Projets
- Vue en grille moderne
- Suivi de progression
- Assignation d'équipes
- Statuts visuels

### ✅ Gestion des Tâches
- Interface Kanban-style
- Priorités et échéances
- Assignation développeurs
- Actions rapides

### ✅ Rapports
- Visualisation chronologique
- Filtres avancés
- Export de données
- Suivi d'activité

### ✅ Profil Utilisateur
- Modification informations
- Changement mot de passe
- Paramètres personnalisés
- Thèmes et langues

## 🎨 Interface

### Design System
- **Material Design 3** moderne
- **Palette cohérente** - Bleu primaire
- **Typographie Poppins** élégante
- **Animations fluides** - 300ms transitions
- **Responsive design** adaptatif

### Thèmes
- **Clair** - Interface lumineuse
- **Sombre** - Mode nuit confortable
- **Automatique** - Suit les préférences système

### Langues supportées
- 🇫🇷 **Français** (par défaut)
- 🇺🇸 **Anglais**

## 🔧 Configuration API

### Variables d'environnement
Modifier `lib/app/core/constants/app_constants.dart` :

```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

### Endpoints supportés
- `POST /login` - Authentification
- `GET /profile` - Profil utilisateur
- `GET /admin/statistics` - Statistiques
- `GET /admin/users` - Liste utilisateurs
- `GET /projects` - Liste projets
- `GET /tasks` - Liste tâches
- `GET /reports` - Liste rapports

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📱 Build Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🐛 Résolution de problèmes

### Erreurs de génération JSON
Si vous voyez des erreurs `_$ModelFromJson` :
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Problèmes de dépendances
```bash
flutter clean
flutter pub get
```

### Erreurs Firebase
Vérifiez que les fichiers de configuration sont bien placés et que les services sont activés.

## 📄 Licence

Ce projet est sous licence MIT.

## 👥 Équipe

Développé avec ❤️ pour une gestion de tâches moderne et efficace.




I/flutter (19598): API Service: Headers actuels: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA1LCJleHAiOjE3NTc4NDc5MDUsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.fTH7x4QN0yqcAXdGd6HqJ0AtZO0OVq6e95X8axGzBrZkK6EhUKfiXVoMhQPotbHqdXI3_6-dvKKnuBwGa5ZSUh6MX
I/flutter (19598): Storage Service: Sauvegarde du token d'authentification
I/flutter (19598): API Service: Token d'authentification sauvegardé dans le stockage
I/flutter (19598): Token d'authentification Google défini: eyJhbGciOiJSUzI1NiIs...
I/flutter (19598): Headers après définition du token: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA1LCJleHAiOjE3NTc4NDc5MDUsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.fTH7x4QN0yqcAXdGd6HqJ0AtZO0OVq6e95X8axGzBrZkK6EhUKfiXVoMhQPotbHqdXI3_6-dvKKnuBwGa5
I/flutter (19598): signInWithGoogle: Utilisateur Firebase authentifié: kouassimaxime540@gmail.com
I/flutter (19598): signInWithGoogle: Est-ce un nouvel utilisateur? true
I/flutter (19598): signInWithGoogle: Enregistrement du nouvel utilisateur dans l'API
I/flutter (19598): signInWithGoogle: Données utilisateur à enregistrer: {firebase_uid: njI61H41hRPWBkQnRCsAJ5CzCfC2, email: kouassimaxime540@gmail.com, first_name: KOUASSI, last_name: MAXIME, phone: }
I/flutter (19598): AuthRepository: Tentative d'enregistrement avec données: {firebase_uid: njI61H41hRPWBkQnRCsAJ5CzCfC2, email: kouassimaxime540@gmail.com, first_name: KOUASSI, last_name: MAXIME, phone: }
I/flutter (19598): AuthRepository: Headers avant envoi: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA1LCJleHAiOjE3NTc4NDc5MDUsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.fTH7x4QN0yqcAXdGd6HqJ0AtZO0OVq6e95X8axGzBrZkK6EhUKfiXVoMhQPotbHqdXI3_6-dvKKnuBwGa5
I/flutter (19598): API POST Request: https://3wf.servicerdv.com/api/auth/register
I/flutter (19598): API Headers avant envoi: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA1LCJleHAiOjE3NTc4NDc5MDUsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.fTH7x4QN0yqcAXdGd6HqJ0AtZO0OVq6e95X8axGzBrZkK6EhUKfiXVoMhQPotbHqdXI3_6-dvKKnuBwGa5ZSUh6MXAe8m2
I/flutter (19598): API POST Data: {"firebase_uid":"njI61H41hRPWBkQnRCsAJ5CzCfC2","email":"kouassimaxime540@gmail.com","first_name":"KOUASSI","last_name":"MAXIME","phone":""}
D/TrafficStats(19598): tagSocket(179) with statsTag=0xffffffff, statsUid=-1
D/FirebaseAuth(19598): Notifying id token listeners about user ( njI61H41hRPWBkQnRCsAJ5CzCfC2 ).
I/flutter (19598): _setInitialScreen: Récupération d'un nouveau token
I/flutter (19598): API Service: Token d'authentification défini: eyJhbGciOi...
I/flutter (19598): API Service: Headers actuels: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA3LCJleHAiOjE3NTc4NDc5MDcsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.B0Ubjmwvr81VsvmAbI82WOIlfFwZhBpkYFDR6t59_7ieKDZOEhjNkzPgizKS8FPzz5Rux1s7rI8IKYp36Ssm-QdoX
I/flutter (19598): Storage Service: Sauvegarde du token d'authentification
I/flutter (19598): API Service: Token d'authentification sauvegardé dans le stockage
I/flutter (19598): _setInitialScreen: Token défini avec succès
I/flutter (19598): API POST Response Status: 500
I/flutter (19598): API POST Response Body: {"success":false,"message":"Registration failed","error":"SQLSTATE[42S22]: Column not found: 1054 Unknown column 'date_of_birth' in 'INSERT INTO' (Connection: mysql, SQL: insert into `users` (`firebas...
I/flutter (19598): API _processResponse: Status Code 500
I/flutter (19598): API _processResponse: Error Response: {success: false, message: Registration failed, error: SQLSTATE[42S22]: Column not found: 1054 Unknown column 'date_of_birth' in 'INSERT INTO' (Connection: mysql, SQL: insert into `users` (`firebase_uid`, `email`, `first_name`, `last_name`, `phone`, `date_of_birth`, `gender`, `referral_code`, `referred_by_code`, `updated_at`, `created_at`) values (njI61H41hRPWBkQnRCsAJ5CzCfC2, kouassimaxime540@gmail.com, KOUASSI, MAXIME, ?, ?, ?, W20WAFRS, ?, 2025-09-14 10:05:08, 2025-09-14 10:05:08))}
I/flutter (19598): AuthRepository: Réponse d'enregistrement reçue: {success: false, message: Registration failed, error: SQLSTATE[42S22]: Column not found: 1054 Unknown column 'date_of_birth' in 'INSERT INTO' (Connection: mysql, SQL: insert into `users` (`firebase_uid`, `email`, `first_name`, `last_name`, `phone`, `date_of_birth`, `gender`, `referral_code`, `referred_by_code`, `updated_at`, `created_at`) values (njI61H41hRPWBkQnRCsAJ5CzCfC2, kouassimaxime540@gmail.com, KOUASSI, MAXIME, ?, ?, ?, W20WAFRS, 
?, 2025-09-14 10:05:08, 2025-09-14 10:05:08))}
I/flutter (19598): AuthRepository: Erreur lors de l'enregistrement: Registration failed
I/flutter (19598): signInWithGoogle: Réponse d'enregistrement reçue: {success: false, message: Registration failed, error: SQLSTATE[42S22]: Column not found: 1054 Unknown column 'date_of_birth' in 'INSERT INTO' (Connection: mysql, SQL: insert into `users` (`firebase_uid`, `email`, `first_name`, `last_name`, `phone`, `date_of_birth`, `gender`, `referral_code`, `referred_by_code`, `updated_at`, `created_at`) values (njI61H41hRPWBkQnRCsAJ5CzCfC2, kouassimaxime540@gmail.com, KOUASSI, MAXIME, ?, ?, ?, W20WAFRS, ?, 2025-09-14 10:05:08, 2025-09-14 10:05:08))}
I/flutter (19598): AuthRepository: Déconnexion de l'utilisateur
I/flutter (19598): AuthRepository: Headers avant déconnexion: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA3LCJleHAiOjE3NTc4NDc5MDcsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.B0Ubjmwvr81VsvmAbI82WOIlfFwZhBpkYFDR6t59_7ieKDZOEhjNkzPgizKS8FPzz5Rux1s7rI8
I/flutter (19598): API POST Request: https://3wf.servicerdv.com/api/auth/logout
I/flutter (19598): API Headers avant envoi: {Content-Type: application/json, Accept: application/json, Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUwMDZlMjc5MTVhMTcwYWIyNmIxZWUzYjgxZDExNjU0MmYxMjRmMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS09VQVNTSSBNQVhJTUUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSTc0a3Y5R29hQ3N6X1BBT1BzTThPQzVZLVYyUmhZbWl1VTA2QmQ0NE1GLWdqOXJBPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3dmaW5mby0zYjlhNyIsImF1ZCI6IndmaW5mby0zYjlhNyIsImF1dGhfdGltZSI6MTc1Nzg0NDMwNSwidXNlcl9pZCI6Im5qSTYxSDQxaFJQV0JrUW5SQ3NBSjVDekNmQzIiLCJzdWIiOiJuakk2MUg0MWhSUFdCa1FuUkNzQUo1Q3pDZkMyIiwiaWF0IjoxNzU3ODQ0MzA3LCJleHAiOjE3NTc4NDc5MDcsImVtYWlsIjoia291YXNzaW1heGltZTU0MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNTAxNTM0NzcwOTkxNzYzNjEwNyJdLCJlbWFpbCI6WyJrb3Vhc3NpbWF4aW1lNTQwQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.B0Ubjmwvr81VsvmAbI82WOIlfFwZhBpkYFDR6t59_7ieKDZOEhjNkzPgizKS8FPzz5Rux1s7rI8IKYp36Ssm-QdoXtrWuE
I/flutter (19598): API POST Data: {}
Another exception was thrown: A RenderFlex overflowed by 0.647 pixels on the right.
I/flutter (19598): API POST Response Status: 200
I/flutter (19598): API POST Response Body: {"success":true,"message":"Logged out successfully"}...
I/flutter (19598): API _processResponse: Status Code 200
I/flutter (19598): API _processResponse: Successful Response Type: _Map<String, dynamic>
I/flutter (19598): API _processResponse: Response Keys: [success, message]
I/flutter (19598): AuthRepository: Réponse de déconnexion: {success: true, message: Logged out successfully}
I/flutter (19598): Déconnexion réussie côté API
I/flutter (19598): Déconnexion Google réussie
I/flutter (19598): Données utilisateur supprimées du stockage local
I/flutter (19598): Données locales nettoyées
I/flutter (19598): API Service: Token d'authentification supprimé des headers
I/flutter (19598): Storage Service: Suppression du token d'authentification
I/flutter (19598): API Service: Token d'authentification supprimé du stockage
I/flutter (19598): Token d'authentification supprimé
D/FirebaseAuth(19598): Notifying id token listeners about a sign-out event.
D/FirebaseAuth(19598): Notifying auth state listeners about a sign-out event.
I/flutter (19598): Déconnexion Firebase réussie
W/OnBackInvokedCallback(19598): OnBackInvokedCallback is not enabled for the application.
W/OnBackInvokedCallback(19598): Set 'android:enableOnBackInvokedCallback="true"' in the application manifest.
