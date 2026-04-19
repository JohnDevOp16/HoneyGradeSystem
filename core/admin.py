from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Assessment, RGBResult, QRCertificate

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display  = ('username', 'email', 'role', 'region', 'is_staff')
    list_filter   = ('role',)
    fieldsets     = UserAdmin.fieldsets + (
        ('HoneyGrade Info', {'fields': ('phone', 'region', 'role')}),
    )

@admin.register(Assessment)
class AssessmentAdmin(admin.ModelAdmin):
    list_display  = ('sample_label', 'user', 'quality_result', 'assessed_at')
    list_filter   = ('quality_result',)

@admin.register(RGBResult)
class RGBResultAdmin(admin.ModelAdmin):
    list_display  = ('assessment', 'r_avg', 'g_avg', 'b_avg', 'rg_ratio')

@admin.register(QRCertificate)
class QRCertificateAdmin(admin.ModelAdmin):
    list_display  = ('assessment', 'generated_at')