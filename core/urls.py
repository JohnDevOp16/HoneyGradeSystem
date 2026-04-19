from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, LoginView, ProfileView,
    AssessHoneyView, AssessmentHistoryView,
    AssessmentDetailView, ExportCSVView, DashboardStatsView,
    login_page, dashboard_page,
)

urlpatterns = [
    # ── HTML PAGES ──────────────────────────────────────────────
    path('',           login_page,     name='login_page'),
    path('dashboard/', dashboard_page, name='dashboard_page'),

    # ── AUTH API ────────────────────────────────────────────────
    path('api/auth/register/', RegisterView.as_view(),    name='register'),
    path('api/auth/login/',    LoginView.as_view(),        name='login'),
    path('api/auth/refresh/',  TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/profile/',  ProfileView.as_view(),      name='profile'),

    # ── DASHBOARD API ───────────────────────────────────────────
    path('api/dashboard/',     DashboardStatsView.as_view(), name='dashboard_stats'),

    # ── ASSESSMENT API ──────────────────────────────────────────
    path('api/assess/',          AssessHoneyView.as_view(),       name='assess'),
    path('api/assess/history/',  AssessmentHistoryView.as_view(), name='history'),
    path('api/assess/<int:pk>/', AssessmentDetailView.as_view(),  name='assess_detail'),

    # ── EXPORT ──────────────────────────────────────────────────
    path('api/export/csv/',      ExportCSVView.as_view(), name='export_csv'),
]