from fastapi import APIRouter
from app.api.v1 import auth, users, plans, subscriptions, coupons, payments, notifications, stats, referrals, affiliates, loyalty, support
from app.api.v1.admin import coupons as admin_coupons
from app.api.v1.admin import users as admin_users
from app.api.v1.admin import stats as admin_stats
from app.api.v1.admin import plans as admin_plans
from app.api.v1.admin import subscriptions as admin_subscriptions
from app.api.v1.admin import payments as admin_payments
from app.api.v1.admin import notifications as admin_notifications
from app.api.v1.admin import coupon_matches as admin_coupon_matches
from app.api.v1.admin import banners as admin_banners
from app.api.v1.admin import app_settings as admin_app_settings
from app.api.v1.admin import support_tickets as admin_support
from app.api.v1.admin import admin_logs
from app.api.v1.admin import affiliate_payouts as admin_affiliate_payouts
from app.api.v1.admin import referrals as admin_referrals

api_router = APIRouter(prefix="/api/v1")

# Routes publiques / utilisateur
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(plans.router)
api_router.include_router(subscriptions.router)
api_router.include_router(coupons.router)
api_router.include_router(payments.router)
api_router.include_router(notifications.router)
api_router.include_router(stats.router)
api_router.include_router(referrals.router)
api_router.include_router(affiliates.router)
api_router.include_router(loyalty.router)
api_router.include_router(support.router)

# Routes admin
api_router.include_router(admin_plans.router)
api_router.include_router(admin_coupons.router)
api_router.include_router(admin_coupon_matches.router)
api_router.include_router(admin_users.router)
api_router.include_router(admin_subscriptions.router)
api_router.include_router(admin_payments.router)
api_router.include_router(admin_stats.router)
api_router.include_router(admin_notifications.router)
api_router.include_router(admin_banners.router)
api_router.include_router(admin_app_settings.router)
api_router.include_router(admin_support.router)
api_router.include_router(admin_logs.router)
api_router.include_router(admin_affiliate_payouts.router)
api_router.include_router(admin_referrals.router)
