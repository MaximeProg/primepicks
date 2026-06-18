# Plan de Développement Technique — Plateforme de Coupons de Paris Sportifs

> **Version** : 1.0  
> **Date** : 2026-06-17  
> **Stack** : FastAPI · PostgreSQL (Neon) · Firebase Auth/FCM · Cloudinary · FedaPay

---

## Table des matières

1. [Architecture globale](#1-architecture-globale)
2. [Stack technique détaillée](#2-stack-technique-détaillée)
3. [Structure du projet](#3-structure-du-projet)
4. [Modèle de données](#4-modèle-de-données)
5. [API — Endpoints par domaine](#5-api--endpoints-par-domaine)
6. [Authentification & Sécurité](#6-authentification--sécurité)
7. [Gestion des paiements FedaPay](#7-gestion-des-paiements-fedapay)
8. [Notifications Firebase FCM](#8-notifications-firebase-fcm)
9. [Gestion des fichiers Cloudinary](#9-gestion-des-fichiers-cloudinary)
10. [Tâches planifiées (Scheduler)](#10-tâches-planifiées-scheduler)
11. [Programmes Parrainage · Affiliation · Fidélité](#11-programmes-parrainage--affiliation--fidélité)
12. [Module IA](#12-module-ia)
13. [Frontends](#13-frontends)
14. [Phases de développement](#14-phases-de-développement)
15. [Variables d'environnement](#15-variables-denvironnement)
16. [Déploiement](#16-déploiement)

---

## 1. Architecture globale

```
┌──────────────────────────────────────────────────────────────┐
│                        CLIENTS                               │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │ Web (Next)  │  │Mobile(Expo) │  │  Admin (Next)        │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬───────────┘ │
└─────────┼────────────────┼──────────────────────┼────────────┘
          │                │                      │
          └────────────────▼──────────────────────┘
                           │  HTTPS / REST + JSON
                    ┌──────▼──────┐
                    │  FastAPI    │  ← JWT Firebase (middleware)
                    │  (Python)   │
                    └──────┬──────┘
          ┌────────────────┼──────────────────────┐
          ▼                ▼                      ▼
   ┌──────────────┐ ┌─────────────┐     ┌─────────────────┐
   │ PostgreSQL   │ │  Firebase   │     │   Services tiers │
   │  (Neon)      │ │ Auth / FCM  │     │ Cloudinary       │
   └──────────────┘ └─────────────┘     │ FedaPay          │
                                        └─────────────────┘
```

### Flux principal

```
Utilisateur → Firebase Auth → Token JWT
           → FastAPI vérifie le token Firebase
           → Accès aux ressources selon rôle + abonnement
```

---

## 2. Stack technique détaillée

### Backend

| Composant            | Technologie                  | Rôle                                 |
|----------------------|------------------------------|--------------------------------------|
| Framework API        | FastAPI 0.111+               | API REST asynchrone                  |
| ORM                  | SQLAlchemy 2.0 (async)       | Accès base de données                |
| Migrations           | Alembic                      | Versioning du schéma DB              |
| Validation           | Pydantic v2                  | Schémas requête/réponse              |
| Auth                 | firebase-admin SDK           | Vérification tokens Firebase         |
| Scheduler            | APScheduler 3.x              | Tâches périodiques                   |
| HTTP client          | httpx                        | Appels FedaPay / services externes   |
| Upload fichiers      | cloudinary SDK Python        | Images coupons, avatars              |
| Serveur ASGI         | Uvicorn + Gunicorn           | Production                           |

### Base de données

| Composant | Technologie    | Détail                              |
|-----------|----------------|-------------------------------------|
| SGBD      | PostgreSQL 16  | Via Neon (serverless, pool de conn) |
| Driver    | asyncpg        | Driver async PostgreSQL             |
| Pool      | SQLAlchemy async engine | Connection pooling            |

### Frontend

| App          | Framework       | Bibliothèques clés                      |
|--------------|-----------------|-----------------------------------------|
| Web public   | Next.js 14 (App Router) | TailwindCSS, shadcn/ui, React Query |
| App mobile   | Expo (React Native 0.74) | Expo Notifications, React Query   |
| Admin        | Next.js 14      | TailwindCSS, Recharts, React Table      |

---

## 3. Structure du projet

```
coupons/
├── backend/
│   ├── app/
│   │   ├── main.py                  # Point d'entrée FastAPI
│   │   ├── core/
│   │   │   ├── config.py            # Settings (pydantic-settings)
│   │   │   ├── database.py          # Engine SQLAlchemy async
│   │   │   ├── firebase.py          # Init firebase-admin
│   │   │   ├── security.py          # Vérification token JWT Firebase
│   │   │   └── dependencies.py      # get_current_user, require_roles, require_subscription
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── subscription.py
│   │   │   ├── plan.py
│   │   │   ├── coupon.py
│   │   │   ├── transaction.py
│   │   │   ├── referral.py
│   │   │   ├── affiliate.py
│   │   │   ├── loyalty.py
│   │   │   ├── notification_log.py
│   │   │   └── fcm_token.py
│   │   ├── schemas/
│   │   │   ├── user.py
│   │   │   ├── subscription.py
│   │   │   ├── coupon.py
│   │   │   ├── payment.py
│   │   │   ├── referral.py
│   │   │   ├── affiliate.py
│   │   │   └── stats.py
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── router.py        # Agrège toutes les routes
│   │   │   │   ├── auth.py
│   │   │   │   ├── users.py
│   │   │   │   ├── plans.py
│   │   │   │   ├── subscriptions.py
│   │   │   │   ├── coupons.py
│   │   │   │   ├── payments.py
│   │   │   │   ├── notifications.py
│   │   │   │   ├── referrals.py
│   │   │   │   ├── affiliates.py
│   │   │   │   ├── loyalty.py
│   │   │   │   ├── stats.py
│   │   │   │   └── admin/
│   │   │   │       ├── users.py
│   │   │   │       ├── coupons.py
│   │   │   │       ├── subscriptions.py
│   │   │   │       ├── payments.py
│   │   │   │       └── stats.py
│   │   ├── services/
│   │   │   ├── subscription_service.py
│   │   │   ├── payment_service.py
│   │   │   ├── notification_service.py
│   │   │   ├── referral_service.py
│   │   │   ├── affiliate_service.py
│   │   │   ├── loyalty_service.py
│   │   │   ├── cloudinary_service.py
│   │   │   └── ai_service.py
│   │   └── workers/
│   │       ├── scheduler.py         # Init APScheduler
│   │       ├── subscription_tasks.py
│   │       └── notification_tasks.py
│   ├── migrations/
│   │   └── versions/
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   ├── .env
│   ├── .env.example
│   ├── requirements.txt
│   └── alembic.ini
├── frontend-web/                    # Next.js — app publique
├── admin/                           # Next.js — dashboard admin
├── mobile/                          # Expo — app mobile
└── PLAN_TECHNIQUE.md
```

---

## 4. Modèle de données

### 4.1 Énumérations

```sql
CREATE TYPE user_role AS ENUM ('SUPER_ADMIN', 'ADMIN', 'AFFILIATE', 'USER');
CREATE TYPE subscription_status AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELLED', 'PENDING');
CREATE TYPE coupon_status AS ENUM ('PENDING', 'WON', 'LOST', 'CANCELLED');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');
CREATE TYPE loyalty_source AS ENUM ('SUBSCRIPTION', 'REFERRAL', 'CAMPAIGN', 'MANUAL');
```

### 4.2 Tables

#### `users`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
firebase_uid    VARCHAR(128) UNIQUE NOT NULL
email           VARCHAR(255) UNIQUE NOT NULL
phone           VARCHAR(20)
full_name       VARCHAR(255)
avatar_url      TEXT                          -- Cloudinary URL
role            user_role DEFAULT 'USER'
referral_code   VARCHAR(12) UNIQUE NOT NULL   -- généré à l'inscription
referred_by     UUID REFERENCES users(id)
loyalty_points  INTEGER DEFAULT 0
is_active       BOOLEAN DEFAULT TRUE
fcm_token       TEXT                          -- token FCM courant
created_at      TIMESTAMPTZ DEFAULT NOW()
updated_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `plans`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
name            VARCHAR(100) NOT NULL          -- ex: "Mensuel", "Trimestriel"
slug            VARCHAR(50) UNIQUE NOT NULL
price           NUMERIC(10,2) NOT NULL         -- en XOF
duration_days   INTEGER NOT NULL
description     TEXT
features        JSONB                          -- liste de fonctionnalités
is_active       BOOLEAN DEFAULT TRUE
created_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `subscriptions`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id) NOT NULL
plan_id         UUID REFERENCES plans(id) NOT NULL
status          subscription_status DEFAULT 'PENDING'
start_date      TIMESTAMPTZ
end_date        TIMESTAMPTZ
auto_renew      BOOLEAN DEFAULT FALSE
transaction_id  UUID REFERENCES transactions(id)
notified_d3     BOOLEAN DEFAULT FALSE          -- notification J-3 envoyée
notified_d1     BOOLEAN DEFAULT FALSE          -- notification J-1 envoyée
created_at      TIMESTAMPTZ DEFAULT NOW()
updated_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `transactions`
```sql
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id             UUID REFERENCES users(id) NOT NULL
plan_id             UUID REFERENCES plans(id)
amount              NUMERIC(10,2) NOT NULL
currency            VARCHAR(3) DEFAULT 'XOF'
status              transaction_status DEFAULT 'PENDING'
fedapay_id          VARCHAR(100)               -- ID transaction FedaPay
fedapay_token       TEXT                       -- token de paiement FedaPay
payment_url         TEXT                       -- URL de paiement FedaPay
metadata            JSONB                      -- données brutes webhook
paid_at             TIMESTAMPTZ
created_at          TIMESTAMPTZ DEFAULT NOW()
updated_at          TIMESTAMPTZ DEFAULT NOW()
```

#### `coupons`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
title           VARCHAR(255) NOT NULL
description     TEXT
analysis        TEXT                           -- analyse détaillée
odds            NUMERIC(6,2)                   -- cote globale
bookmaker_code  VARCHAR(100)                   -- code du coupon bookmaker
image_url       TEXT                           -- Cloudinary URL
valid_until     TIMESTAMPTZ
status          coupon_status DEFAULT 'PENDING'
is_published    BOOLEAN DEFAULT FALSE
published_at    TIMESTAMPTZ
created_by      UUID REFERENCES users(id)
updated_at      TIMESTAMPTZ DEFAULT NOW()
created_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `referrals`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
referrer_id     UUID REFERENCES users(id) NOT NULL
referred_id     UUID REFERENCES users(id) NOT NULL UNIQUE
reward_type     VARCHAR(50)                    -- 'POINTS' | 'DISCOUNT'
reward_value    NUMERIC(10,2)
reward_given    BOOLEAN DEFAULT FALSE
rewarded_at     TIMESTAMPTZ
created_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `affiliates`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id) UNIQUE NOT NULL
affiliate_code  VARCHAR(20) UNIQUE NOT NULL
commission_rate NUMERIC(5,2) DEFAULT 10.00    -- pourcentage
total_earned    NUMERIC(10,2) DEFAULT 0
is_active       BOOLEAN DEFAULT TRUE
created_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `affiliate_conversions`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
affiliate_id    UUID REFERENCES affiliates(id) NOT NULL
user_id         UUID REFERENCES users(id) NOT NULL
transaction_id  UUID REFERENCES transactions(id)
commission      NUMERIC(10,2) NOT NULL
paid_out        BOOLEAN DEFAULT FALSE
created_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `loyalty_transactions`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id) NOT NULL
points          INTEGER NOT NULL               -- positif ou négatif
source          loyalty_source NOT NULL
reference_id    UUID                           -- ID abonnement / parrainage / campagne
description     TEXT
created_at      TIMESTAMPTZ DEFAULT NOW()
```

#### `notification_logs`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id)      -- NULL = broadcast
title           VARCHAR(255) NOT NULL
body            TEXT NOT NULL
type            VARCHAR(50) NOT NULL           -- 'NEW_COUPON', 'EXPIRY', 'PAYMENT', etc.
data            JSONB
sent_at         TIMESTAMPTZ DEFAULT NOW()
success_count   INTEGER DEFAULT 0
failure_count   INTEGER DEFAULT 0
```

#### `fcm_tokens`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id) NOT NULL
token           TEXT NOT NULL
device_type     VARCHAR(20)                    -- 'WEB' | 'IOS' | 'ANDROID'
updated_at      TIMESTAMPTZ DEFAULT NOW()
UNIQUE(user_id, device_type)
```

---

## 5. API — Endpoints par domaine

### Convention

```
Base URL       : /api/v1
Auth requise   : Bearer {Firebase JWT}
Admin only     : rôle ADMIN ou SUPER_ADMIN
```

### 5.1 Authentification

| Méthode | Endpoint              | Auth | Description                                           |
|---------|-----------------------|------|-------------------------------------------------------|
| POST    | `/auth/sync`          | ✓    | Synchronise l'utilisateur Firebase → DB (1er login)   |
| POST    | `/auth/logout`        | ✓    | Révoque le token FCM                                  |

### 5.2 Utilisateurs

| Méthode | Endpoint                   | Auth  | Description                          |
|---------|----------------------------|-------|--------------------------------------|
| GET     | `/users/me`                | ✓     | Profil courant                       |
| PATCH   | `/users/me`                | ✓     | Mise à jour profil                   |
| POST    | `/users/me/avatar`         | ✓     | Upload avatar (Cloudinary)           |
| GET     | `/users/me/subscriptions`  | ✓     | Historique abonnements               |
| GET     | `/users/me/transactions`   | ✓     | Historique paiements                 |
| GET     | `/admin/users`             | Admin | Liste utilisateurs (pagination)      |
| GET     | `/admin/users/{id}`        | Admin | Détail utilisateur                   |
| PATCH   | `/admin/users/{id}`        | Admin | Modifier rôle / statut               |

### 5.3 Plans & Abonnements

| Méthode | Endpoint                        | Auth  | Description                          |
|---------|---------------------------------|-------|--------------------------------------|
| GET     | `/plans`                        | —     | Liste des offres actives             |
| GET     | `/plans/{id}`                   | —     | Détail d'un plan                     |
| POST    | `/admin/plans`                  | Admin | Créer un plan                        |
| PATCH   | `/admin/plans/{id}`             | Admin | Modifier un plan                     |
| DELETE  | `/admin/plans/{id}`             | Admin | Désactiver un plan                   |
| POST    | `/subscriptions`                | ✓     | Souscrire → initie paiement FedaPay  |
| GET     | `/subscriptions/me`             | ✓     | Abonnement actif courant             |
| POST    | `/subscriptions/me/renew`       | ✓     | Renouveler abonnement actif          |
| GET     | `/admin/subscriptions`          | Admin | Liste toutes les souscriptions       |
| PATCH   | `/admin/subscriptions/{id}`     | Admin | Modifier statut manuellement         |

### 5.4 Coupons

| Méthode | Endpoint               | Auth         | Description                             |
|---------|------------------------|--------------|------------------------------------------|
| GET     | `/coupons`             | ✓ + abonné   | Liste coupons publiés                   |
| GET     | `/coupons/{id}`        | ✓ + abonné   | Détail coupon (code bookmaker visible)  |
| GET     | `/coupons/public`      | —            | Aperçu limité (sans code bookmaker)     |
| POST    | `/admin/coupons`       | Admin        | Créer un coupon                         |
| PATCH   | `/admin/coupons/{id}`  | Admin        | Modifier un coupon                      |
| DELETE  | `/admin/coupons/{id}`  | Admin        | Supprimer un coupon                     |
| POST    | `/admin/coupons/{id}/publish`  | Admin | Publier + déclenche notification FCM   |
| PATCH   | `/admin/coupons/{id}/status`   | Admin | Changer statut (WON/LOST/CANCELLED)    |
| POST    | `/admin/coupons/{id}/image`    | Admin | Upload image coupon (Cloudinary)       |

### 5.5 Paiements

| Méthode | Endpoint                  | Auth   | Description                                       |
|---------|---------------------------|--------|---------------------------------------------------|
| POST    | `/payments/initiate`      | ✓      | Créer transaction + URL paiement FedaPay          |
| GET     | `/payments/verify/{id}`   | ✓      | Vérifier statut transaction                       |
| POST    | `/payments/webhook`       | —      | Callback FedaPay (HMAC vérifié)                   |
| GET     | `/admin/payments`         | Admin  | Liste toutes les transactions                     |
| GET     | `/admin/payments/stats`   | Admin  | Revenus totaux, mensuels, annuels                 |

### 5.6 Notifications

| Méthode | Endpoint                   | Auth  | Description                              |
|---------|----------------------------|-------|------------------------------------------|
| POST    | `/notifications/token`     | ✓     | Enregistrer/rafraîchir token FCM         |
| DELETE  | `/notifications/token`     | ✓     | Supprimer token FCM (logout)             |
| GET     | `/admin/notifications`     | Admin | Historique notifications envoyées       |
| POST    | `/admin/notifications/send`| Admin | Envoi manuel (broadcast ou ciblé)       |

### 5.7 Parrainage

| Méthode | Endpoint               | Auth | Description                              |
|---------|------------------------|------|------------------------------------------|
| GET     | `/referrals/me`        | ✓    | Code + lien de parrainage                |
| GET     | `/referrals/me/stats`  | ✓    | Filleuls + récompenses                   |

### 5.8 Affiliation

| Méthode | Endpoint                     | Auth      | Description                       |
|---------|------------------------------|-----------|-----------------------------------|
| POST    | `/affiliates/apply`          | ✓         | Demande de compte affilié         |
| GET     | `/affiliates/me`             | Affilié   | Dashboard affilié                 |
| GET     | `/affiliates/me/conversions` | Affilié   | Historique conversions            |
| GET     | `/affiliates/me/earnings`    | Affilié   | Commissions gagnées               |

### 5.9 Fidélité

| Méthode | Endpoint                   | Auth | Description                          |
|---------|----------------------------|------|--------------------------------------|
| GET     | `/loyalty/me`              | ✓    | Solde + historique points            |
| POST    | `/loyalty/redeem`          | ✓    | Échanger des points                  |

### 5.10 Statistiques

| Méthode | Endpoint                        | Auth  | Description                          |
|---------|---------------------------------|-------|--------------------------------------|
| GET     | `/stats/public`                 | —     | Perf publique (taux de réussite, …)  |
| GET     | `/admin/stats/overview`         | Admin | KPIs globaux                         |
| GET     | `/admin/stats/subscriptions`    | Admin | Évolution abonnements                |
| GET     | `/admin/stats/coupons`          | Admin | Performance coupons                  |
| GET     | `/admin/stats/monthly`          | Admin | Détail mensuel `?year=2026`          |
| GET     | `/admin/stats/revenue`          | Admin | Revenus par période                  |

---

## 6. Authentification & Sécurité

### Flux Firebase Auth

```
1. Client (Web/Mobile) → Firebase Auth SDK
   → Connexion Google OAuth ou Email/Password
   → Obtient un ID Token Firebase (JWT)

2. Client → API FastAPI
   → Header: Authorization: Bearer <firebase_id_token>

3. FastAPI middleware
   → firebase_admin.auth.verify_id_token(token)
   → Extrait firebase_uid, email
   → Cherche user en DB ou crée le profil (upsert)
   → Injecte user dans la requête via Depends()
```

### Middleware de sécurité

```python
# core/security.py

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    decoded = firebase_admin.auth.verify_id_token(token)
    user = await get_or_create_user(db, decoded)
    return user

def require_roles(*roles: UserRole):
    async def checker(user: User = Depends(get_current_user)):
        if user.role not in roles:
            raise HTTPException(403, "Accès refusé")
        return user
    return checker

async def require_active_subscription(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    sub = await get_active_subscription(db, user.id)
    if not sub:
        raise HTTPException(403, "Abonnement actif requis")
    return user
```

### Sécurité des webhooks FedaPay

```python
# Vérification signature HMAC-SHA256
import hmac, hashlib

def verify_fedapay_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)
```

### Contrôle d'accès par rôle (RBAC)

| Ressource              | USER | AFFILIATE | ADMIN | SUPER_ADMIN |
|------------------------|------|-----------|-------|-------------|
| Voir coupons           | ✓*   | ✓*        | ✓     | ✓           |
| Créer/modifier coupons | ✗    | ✗         | ✓     | ✓           |
| Gérer utilisateurs     | ✗    | ✗         | ✓     | ✓           |
| Gérer plans            | ✗    | ✗         | ✓     | ✓           |
| Voir stats admin       | ✗    | ✗         | ✓     | ✓           |
| Gérer admins           | ✗    | ✗         | ✗     | ✓           |

*✓ = abonnement actif requis*

---

## 7. Gestion des paiements FedaPay

### Flux de paiement

```
1. POST /payments/initiate
   ├── Créer transaction en DB (status=PENDING)
   ├── Appel FedaPay API → créer une transaction
   │   Body: { amount, currency, description, customer }
   ├── Récupérer payment_url FedaPay
   └── Retourner { transaction_id, payment_url } au client

2. Client → redirigé vers payment_url FedaPay
   └── Utilisateur paie (Mobile Money, carte)

3. FedaPay → POST /payments/webhook
   ├── Vérifier signature HMAC
   ├── Identifier la transaction locale via fedapay_id
   ├── Si event = "transaction.approved"
   │   ├── Marquer transaction PAID
   │   ├── Appeler subscription_service.activate(user_id, plan_id)
   │   │   ├── Créer subscription (start=now, end=now+duration_days)
   │   │   ├── status = ACTIVE
   │   ├── Appeler loyalty_service.credit(user_id, source=SUBSCRIPTION)
   │   ├── Appeler referral_service.process_reward(user_id)  # si parrainage
   │   └── Appeler notification_service.send(user_id, type=PAYMENT_SUCCESS)
   └── Répondre 200 OK à FedaPay

4. Client → GET /payments/verify/{id}
   └── Retourner statut transaction (polling ou redirect)
```

### Modèle de données transaction FedaPay (metadata JSON)

```json
{
  "fedapay_event": "transaction.approved",
  "fedapay_transaction_id": 123456,
  "customer_id": "cus_xxx",
  "payment_method": "mtn_mobile_money",
  "fees": 150,
  "raw_response": { ... }
}
```

---

## 8. Notifications Firebase FCM

### Types de notifications

```python
class NotificationType(str, Enum):
    NEW_COUPON       = "NEW_COUPON"
    COUPON_WON       = "COUPON_WON"
    COUPON_LOST      = "COUPON_LOST"
    COUPON_CANCELLED = "COUPON_CANCELLED"
    SUB_ACTIVATED    = "SUB_ACTIVATED"
    SUB_EXPIRY_D3    = "SUB_EXPIRY_D3"
    SUB_EXPIRY_D1    = "SUB_EXPIRY_D1"
    SUB_EXPIRED      = "SUB_EXPIRED"
    PROMO            = "PROMO"
    PAYMENT_SUCCESS  = "PAYMENT_SUCCESS"
```

### Service FCM

```python
# services/notification_service.py

async def send_to_user(user_id: UUID, title: str, body: str, type: NotificationType, data: dict = {}):
    tokens = await get_user_fcm_tokens(user_id)
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        data={"type": type, **data},
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(...)
    )
    response = messaging.send_each_for_multicast(message)
    await log_notification(user_id, title, body, type, response)

async def broadcast_to_subscribers(title: str, body: str, type: NotificationType):
    # Récupère tous les tokens des abonnés actifs
    tokens = await get_all_active_subscriber_tokens()
    # Envoie par batch de 500 (limite FCM)
    for batch in chunks(tokens, 500):
        await send_multicast(batch, title, body, type)
```

---

## 9. Gestion des fichiers Cloudinary

### Configuration

```python
import cloudinary
import cloudinary.uploader

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True
)
```

### Service upload

```python
# services/cloudinary_service.py

async def upload_coupon_image(file: UploadFile) -> str:
    result = cloudinary.uploader.upload(
        await file.read(),
        folder="coupons",
        transformation=[{"width": 800, "crop": "limit"}, {"quality": "auto"}]
    )
    return result["secure_url"]

async def upload_avatar(file: UploadFile, user_id: str) -> str:
    result = cloudinary.uploader.upload(
        await file.read(),
        folder="avatars",
        public_id=f"avatar_{user_id}",
        overwrite=True,
        transformation=[{"width": 200, "height": 200, "crop": "fill"}, {"quality": "auto"}]
    )
    return result["secure_url"]
```

---

## 10. Tâches planifiées (Scheduler)

```python
# workers/scheduler.py — APScheduler avec AsyncIOScheduler

scheduler = AsyncIOScheduler(timezone="Africa/Abidjan")

# Expiration des abonnements — toutes les heures
@scheduler.scheduled_job("interval", hours=1)
async def expire_subscriptions():
    # SELECT * FROM subscriptions WHERE status='ACTIVE' AND end_date <= NOW()
    # UPDATE status = 'EXPIRED'
    # Envoyer notification SUB_EXPIRED

# Notification J-3 — chaque jour à 9h
@scheduler.scheduled_job("cron", hour=9, minute=0)
async def notify_expiry_d3():
    # SELECT * FROM subscriptions WHERE status='ACTIVE'
    #   AND end_date BETWEEN NOW() AND NOW() + INTERVAL '3 days'
    #   AND notified_d3 = FALSE
    # Envoyer notification SUB_EXPIRY_D3
    # UPDATE notified_d3 = TRUE

# Notification J-1 — chaque jour à 9h
@scheduler.scheduled_job("cron", hour=9, minute=30)
async def notify_expiry_d1():
    # SELECT * FROM subscriptions WHERE status='ACTIVE'
    #   AND end_date BETWEEN NOW() AND NOW() + INTERVAL '1 day'
    #   AND notified_d1 = FALSE
    # Envoyer notification SUB_EXPIRY_D1
    # UPDATE notified_d1 = TRUE

# Calcul statistiques quotidiennes — à minuit
@scheduler.scheduled_job("cron", hour=0, minute=5)
async def compute_daily_stats():
    # Agrégation coupons, abonnements, revenus
    # Stockage dans une table stats_snapshots
```

---

## 11. Programmes Parrainage · Affiliation · Fidélité

### Parrainage — Règles métier

```
À l'inscription avec code parrainage :
  → Stocker referred_by sur le user

Au 1er paiement du filleul :
  → Créer enregistrement referral
  → Créditer parrain : +200 points OR réduction X%
  → Envoyer notification au parrain
```

### Affiliation — Calcul commission

```
Transaction validée via lien affilié :
  → Récupérer affiliate via ?ref=CODE
  → commission = transaction.amount * affiliate.commission_rate / 100
  → Créer affiliate_conversion
  → Incrémenter affiliate.total_earned
```

### Fidélité — Table de gains/échanges

| Action                        | Points |
|-------------------------------|--------|
| Souscription plan mensuel     | +100   |
| Souscription plan trimestriel | +250   |
| Parrainage réussi             | +200   |
| Campagne promotionnelle       | variable |

| Échange                       | Coût   |
|-------------------------------|--------|
| Réduction 10% sur prochain abonnement | 500 pts |
| 1 mois offert                 | 1000 pts |
| Accès 7 jours offert          | 300 pts |

---

## 12. Module IA

> Priorité : **v2** — implémentation après stabilisation du core.

### Fonctionnalités prévues

1. **Score de confiance** : basé sur l'historique des coupons (taux de réussite par type de pari, bookmaker, cote)
2. **Analyse de tendances** : performances des 30 derniers jours
3. **Suggestions automatiques** : propositions de coupons avec indicateurs, validées manuellement par l'admin

### Stack IA

```
- scikit-learn : modèle de scoring (régression logistique ou random forest)
- pandas : traitement des données historiques
- Optionnel : Claude API (claude-sonnet-4-6) pour génération d'analyses textuelles
```

### Endpoint

```
GET /admin/ai/suggestions         → liste de coupons suggérés par le modèle
GET /coupons/{id}/confidence      → score de confiance d'un coupon
```

---

## 13. Frontends

### 13.1 Web public (Next.js 14)

```
pages/
  /                  → Landing : stats publiques, plans, témoignages
  /login             → Firebase Auth UI (Google + Email)
  /register          → Inscription (+ champ code parrainage)
  /plans             → Offres d'abonnement
  /dashboard         → Coupons du jour (abonné)
  /coupons/[id]      → Détail coupon + analyse + code bookmaker
  /account           → Profil, historique, fidélité
  /account/referral  → Code + lien parrainage
  /account/billing   → Historique paiements
```

### 13.2 App mobile (Expo / React Native)

- Authentification Firebase via `expo-auth-session` (Google) + Email
- Notifications push via `expo-notifications` + FCM
- Paiement FedaPay via WebView (`expo-web-browser`)
- Navigation : Expo Router (file-based)

### 13.3 Dashboard Admin (Next.js 14 — domaine séparé)

```
pages/
  /                       → KPIs : revenus, abonnés actifs, taux réussite
  /coupons                → Table + filtres, CRUD, changement de statut
  /coupons/new            → Formulaire création coupon
  /users                  → Table utilisateurs, détail, modification rôle
  /subscriptions          → Table abonnements, activation manuelle
  /payments               → Table transactions, export CSV
  /affiliates             → Gestion affiliés, validation demandes
  /notifications          → Historique + envoi manuel
  /stats/coupons          → Graphiques performance coupons
  /stats/revenue          → Graphiques revenus
  /stats/subscriptions    → Évolution abonnements
  /settings               → Plans, paramètres plateforme
```

---

## 14. Phases de développement

### Phase 0 — Setup & Infrastructure (Semaine 1)

- [ ] Initialiser le monorepo (Git)
- [ ] Configurer le projet Firebase (Auth + FCM + serviceAccountKey)
- [ ] Créer la base de données Neon (PostgreSQL)
- [ ] Créer les comptes : Cloudinary, FedaPay sandbox
- [ ] Initialiser le projet FastAPI avec structure de dossiers
- [ ] Configurer Alembic
- [ ] Créer le `.env.example` complet
- [ ] Mettre en place le CI/CD de base (GitHub Actions)

### Phase 1 — Backend Core (Semaines 2–3)

- [ ] Modèles SQLAlchemy + migrations Alembic (toutes les tables)
- [ ] Middleware Firebase Auth (`get_current_user`)
- [ ] Endpoints auth (`/auth/sync`)
- [ ] CRUD utilisateurs
- [ ] CRUD plans
- [ ] CRUD coupons (admin)
- [ ] Endpoint coupons publics (accès contrôlé par abonnement)
- [ ] Service Cloudinary (avatar + image coupon)

### Phase 2 — Paiements & Abonnements (Semaine 4)

- [ ] Service FedaPay : initiation transaction
- [ ] Webhook FedaPay + vérification HMAC
- [ ] Service activation abonnement automatique
- [ ] Service calcul dates start/end
- [ ] Endpoints souscription / renouvellement
- [ ] Tests d'intégration webhook (sandbox FedaPay)

### Phase 3 — Notifications & Scheduler (Semaine 5)

- [ ] Service FCM (envoi unitaire + broadcast)
- [ ] Enregistrement tokens FCM (`/notifications/token`)
- [ ] Scheduler APScheduler (expiration + notifications J-3, J-1)
- [ ] Notification à la publication d'un coupon
- [ ] Notification au changement de statut coupon

### Phase 4 — Parrainage · Affiliation · Fidélité (Semaine 6)

- [ ] Génération code parrainage à l'inscription
- [ ] Service traitement récompense parrainage
- [ ] Système affilié : code, tracking conversions, commissions
- [ ] Service points fidélité (crédit + échange)
- [ ] Endpoints parrainage, affiliation, fidélité

### Phase 5 — Statistiques & Performance (Semaine 7)

- [ ] Endpoint stats publiques (`/stats/public`)
- [ ] Endpoints stats admin (revenus, abonnés, coupons)
- [ ] Calcul quotidien des snapshots stats (scheduler)
- [ ] Export CSV des transactions (admin)

### Phase 6 — Frontend Web (Semaines 8–10)

- [ ] Landing page + stats publiques
- [ ] Authentification Firebase (Google + Email)
- [ ] Page plans + souscription + redirect FedaPay
- [ ] Dashboard abonné + liste coupons
- [ ] Détail coupon + analyse
- [ ] Page compte + historique + fidélité
- [ ] Page parrainage

### Phase 7 — Dashboard Admin (Semaines 11–12)

- [ ] Layout admin + authentification ADMIN
- [ ] CRUD coupons + publication
- [ ] Gestion utilisateurs
- [ ] Gestion abonnements
- [ ] Historique paiements
- [ ] Statistiques avec graphiques (Recharts)
- [ ] Envoi notifications manuelles

### Phase 8 — Application Mobile (Semaines 13–14)

- [ ] Setup Expo + Firebase
- [ ] Authentification (Google + Email)
- [ ] Push notifications (FCM)
- [ ] Écrans principaux (coupons, compte, plans)
- [ ] Paiement FedaPay via WebView
- [ ] Build EAS (Android + iOS)

### Phase 9 — Tests & Sécurité (Semaine 15)

- [ ] Tests unitaires services critiques (paiement, abonnement, parrainage)
- [ ] Tests intégration webhook FedaPay
- [ ] Rate limiting (slowapi)
- [ ] Audit RBAC complet
- [ ] Test de charge (locust)
- [ ] Revue sécurité (injection, XSS, CORS)

### Phase 10 — Déploiement (Semaine 16)

- [ ] Backend → Railway / Render / Fly.io
- [ ] Frontend web → Vercel
- [ ] Admin → Vercel
- [ ] Mobile → Expo EAS → stores
- [ ] Passage FedaPay en production
- [ ] Mise en place monitoring (Sentry + logs)
- [ ] Documentation API (auto-générée FastAPI /docs)

---

## 15. Variables d'environnement

```env
# Base de données
DATABASE_URL=postgresql+asyncpg://user:password@host/dbname

# Firebase
FIREBASE_PROJECT_ID=xxx
FIREBASE_PRIVATE_KEY=xxx
FIREBASE_CLIENT_EMAIL=xxx
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json

# FedaPay
FEDAPAY_API_KEY=sk_sandbox_xxx
FEDAPAY_WEBHOOK_SECRET=whsec_xxx
FEDAPAY_BASE_URL=https://sandbox-api.fedapay.com/v1

# Cloudinary
CLOUDINARY_CLOUD_NAME=xxx
CLOUDINARY_API_KEY=xxx
CLOUDINARY_API_SECRET=xxx

# Application
APP_ENV=development
APP_SECRET_KEY=xxx
FRONTEND_URL=http://localhost:3000
ADMIN_URL=http://localhost:3001
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# Planificateur
TIMEZONE=Africa/Abidjan
```

---

## 16. Déploiement

### Infrastructure cible

| Service            | Hébergement         | Notes                                |
|--------------------|---------------------|--------------------------------------|
| FastAPI API        | Railway             | Docker, auto-deploy GitHub           |
| PostgreSQL         | Neon                | Serverless, pooling intégré          |
| Frontend web       | Vercel              | Next.js natif                        |
| Dashboard admin    | Vercel              | Domaine séparé (admin.domaine.com)   |
| App mobile         | Expo EAS Build      | Android + iOS                        |
| Fichiers           | Cloudinary          | CDN intégré                          |
| Auth + Notif       | Firebase            | Google infrastructure                |
| Paiements          | FedaPay             | Sandbox → Production                 |
| Monitoring         | Sentry              | Erreurs + performances               |

### Dockerfile (backend)

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

### Configuration CORS (production)

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Livrables finaux

| Livrable                  | Statut    |
|---------------------------|-----------|
| API FastAPI documentée    | `/docs`   |
| Application web publique  | Vercel    |
| Application mobile        | Stores    |
| Dashboard administrateur  | Vercel    |
| Documentation utilisateur | PDF/Notion|

---

*Document généré le 2026-06-17 — à maintenir à jour à chaque sprint.*
