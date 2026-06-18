from pydantic import BaseModel


class PublicStatsResponse(BaseModel):
    total_coupons: int
    won: int
    lost: int
    cancelled: int
    pending: int
    win_rate: float


class MonthlyStats(BaseModel):
    month: str
    total: int
    won: int
    lost: int
    win_rate: float


class AdminOverviewResponse(BaseModel):
    total_users: int
    active_subscribers: int
    new_users_this_month: int
    total_revenue: float
    revenue_this_month: float
    total_coupons: int
    win_rate: float


class RevenueStats(BaseModel):
    period: str
    amount: float
    transactions_count: int
