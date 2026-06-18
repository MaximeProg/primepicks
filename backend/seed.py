"""
Script de seed : crée les plans tarifaires et le premier super admin.

Usage :
    python seed.py
    python seed.py --admin-email admin@example.com --admin-firebase-uid <uid>
"""
import asyncio
import argparse
import shortuuid
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import select
from dotenv import load_dotenv
import os

load_dotenv()

from app.models.plan import Plan
from app.models.user import User, UserRole

DATABASE_URL = os.environ["DATABASE_URL"]

engine = create_async_engine(DATABASE_URL, connect_args={"ssl": "require"})
Session = async_sessionmaker(bind=engine, expire_on_commit=False)

PLANS = [
    {
        "name": "Hebdomadaire",
        "slug": "weekly",
        "price": 1000,
        "duration_days": 7,
        "description": "Accès 7 jours à tous les coupons premium",
        "features": {"coupons": True, "analyses": True, "notifications": True},
        "loyalty_points_reward": 50,
    },
    {
        "name": "Mensuel",
        "slug": "monthly",
        "price": 3000,
        "duration_days": 30,
        "description": "Accès 30 jours à tous les coupons premium",
        "features": {"coupons": True, "analyses": True, "notifications": True, "stats": True},
        "loyalty_points_reward": 100,
    },
    {
        "name": "Trimestriel",
        "slug": "quarterly",
        "price": 7500,
        "duration_days": 90,
        "description": "Accès 90 jours — Meilleur rapport qualité/prix",
        "features": {"coupons": True, "analyses": True, "notifications": True, "stats": True, "priority": True},
        "loyalty_points_reward": 250,
    },
    {
        "name": "Annuel",
        "slug": "yearly",
        "price": 25000,
        "duration_days": 365,
        "description": "Accès 365 jours — Offre complète",
        "features": {"coupons": True, "analyses": True, "notifications": True, "stats": True, "priority": True, "vip": True},
        "loyalty_points_reward": 1000,
    },
]


async def seed_plans(db: AsyncSession):
    created = 0
    for plan_data in PLANS:
        existing = await db.execute(select(Plan).where(Plan.slug == plan_data["slug"]))
        if existing.scalar_one_or_none():
            print(f"  [skip] Plan '{plan_data['slug']}' existe déjà")
            continue
        plan = Plan(**plan_data)
        db.add(plan)
        created += 1
        print(f"  [ok]   Plan '{plan_data['slug']}' créé ({plan_data['price']} XOF / {plan_data['duration_days']}j)")
    await db.commit()
    return created


async def seed_admin(db: AsyncSession, email: str, firebase_uid: str):
    existing = await db.execute(select(User).where(User.email == email))
    user = existing.scalar_one_or_none()

    if user:
        user.role = UserRole.SUPER_ADMIN
        user.firebase_uid = firebase_uid
        await db.commit()
        print(f"  [ok] Utilisateur '{email}' mis à jour → SUPER_ADMIN")
    else:
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            full_name="Super Admin",
            role=UserRole.SUPER_ADMIN,
            referral_code=shortuuid.ShortUUID().random(length=8).upper(),
        )
        db.add(user)
        await db.commit()
        print(f"  [ok] Super admin '{email}' créé")


async def main(admin_email: str | None, admin_firebase_uid: str | None):
    async with Session() as db:
        print("\n=== Seed des plans ===")
        n = await seed_plans(db)
        print(f"  >> {n} plan(s) cree(s)\n")

        if admin_email and admin_firebase_uid:
            print("=== Seed du super admin ===")
            await seed_admin(db, admin_email, admin_firebase_uid)
        else:
            print("=== Super admin ignoré (--admin-email et --admin-firebase-uid non fournis) ===")

    print("\nSeed terminé.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed la base de données")
    parser.add_argument("--admin-email", type=str, default=None, help="Email du super admin")
    parser.add_argument("--admin-firebase-uid", type=str, default=None, help="Firebase UID du super admin")
    args = parser.parse_args()

    asyncio.run(main(args.admin_email, args.admin_firebase_uid))
