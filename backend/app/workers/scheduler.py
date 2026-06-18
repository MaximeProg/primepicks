from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy import update

from app.core.database import AsyncSessionLocal
from app.core.config import settings
from app.models.subscription import Subscription
from app.services.subscription_service import expire_due_subscriptions, get_subscriptions_expiring_in
from app.services.notification_service import send_to_user, NotificationType

scheduler = AsyncIOScheduler(timezone=settings.TIMEZONE)


async def _task_expire_subscriptions():
    async with AsyncSessionLocal() as db:
        count = await expire_due_subscriptions(db)
        if count > 0:
            print(f"[Scheduler] {count} abonnement(s) expirés")


async def _task_notify_expiry(days: int):
    from datetime import datetime, timezone
    async with AsyncSessionLocal() as db:
        subs = await get_subscriptions_expiring_in(db, days)
        notified_field = "notified_d3" if days == 3 else "notified_d1"
        for sub in subs:
            await send_to_user(
                db,
                user_id=sub.user_id,
                title="Abonnement bientôt expiré",
                body=f"Votre abonnement expire dans {days} jour(s). Renouvelez-le pour garder accès.",
                notif_type=NotificationType.SUB_EXPIRY_D3 if days == 3 else NotificationType.SUB_EXPIRY_D1,
                data={"subscription_id": str(sub.id)},
            )
            await db.execute(
                update(Subscription)
                .where(Subscription.id == sub.id)
                .values(**{notified_field: True})
            )
        await db.commit()
        if subs:
            print(f"[Scheduler] {len(subs)} notification(s) expiration J-{days} envoyées")


def start_scheduler():
    scheduler.add_job(
        _task_expire_subscriptions,
        trigger=IntervalTrigger(hours=1),
        id="expire_subscriptions",
        replace_existing=True,
    )
    scheduler.add_job(
        lambda: __import__("asyncio").get_event_loop().create_task(_task_notify_expiry(3)),
        trigger=CronTrigger(hour=9, minute=0, timezone=settings.TIMEZONE),
        id="notify_expiry_d3",
        replace_existing=True,
    )
    scheduler.add_job(
        lambda: __import__("asyncio").get_event_loop().create_task(_task_notify_expiry(1)),
        trigger=CronTrigger(hour=9, minute=30, timezone=settings.TIMEZONE),
        id="notify_expiry_d1",
        replace_existing=True,
    )
    scheduler.start()
    print("[Scheduler] Démarré")


def stop_scheduler():
    scheduler.shutdown(wait=False)
    print("[Scheduler] Arrêté")
