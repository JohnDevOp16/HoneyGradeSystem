from django.db import models
from django.contrib.auth.models import AbstractUser


# ── CUSTOM USER ──────────────────────────────────────────────────────
class User(AbstractUser):
    ROLE_CHOICES = [
        ('beekeeper', 'Beekeeper'),
        ('buyer',     'Buyer / Consumer'),
        ('inspector', 'Quality Inspector'),
        ('other',     'Other'),
    ]
    phone    = models.CharField(max_length=20, blank=True)
    region   = models.CharField(max_length=100, blank=True)
    role     = models.CharField(max_length=20, choices=ROLE_CHOICES,
                                default='beekeeper')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.get_full_name()} ({self.role})'


# ── ASSESSMENT ───────────────────────────────────────────────────────
class Assessment(models.Model):

    # Grade A/B/C/D system
    GRADE_CHOICES = [
        ('A', 'Grade A — Premium Amber'),
        ('B', 'Grade B — Good Quality'),
        ('C', 'Grade C — Acceptable'),
        ('D', 'Grade D — Below Standard'),
    ]

    user           = models.ForeignKey(
        User, on_delete=models.CASCADE,
        related_name='assessments')
    sample_label   = models.CharField(max_length=60, blank=True)
    image          = models.ImageField(upload_to='honey_images/')
    quality_result = models.CharField(
        max_length=5, choices=GRADE_CHOICES)
    grade_label    = models.CharField(
        max_length=30, blank=True, default='')
    grade_title    = models.CharField(
        max_length=30, blank=True, default='')
    colour_class   = models.CharField(
        max_length=50, blank=True, default='')
    market         = models.CharField(
        max_length=100, blank=True, default='')
    confidence     = models.DecimalField(
        max_digits=5, decimal_places=1, default=0)
    recommendation = models.TextField(blank=True, default='')
    description    = models.TextField(blank=True)
    assessed_at    = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return (f'{self.sample_label} — '
                f'{self.quality_result} ({self.user})')


# ── RGB RESULT ───────────────────────────────────────────────────────
class RGBResult(models.Model):
    assessment  = models.OneToOneField(
        Assessment, on_delete=models.CASCADE,
        related_name='rgb_result')
    # RGB
    r_avg       = models.DecimalField(max_digits=6, decimal_places=2)
    g_avg       = models.DecimalField(max_digits=6, decimal_places=2)
    b_avg       = models.DecimalField(max_digits=6, decimal_places=2)
    rg_ratio    = models.DecimalField(max_digits=5, decimal_places=3)
    rb_ratio    = models.DecimalField(max_digits=5, decimal_places=3)
    avg_score   = models.DecimalField(max_digits=5, decimal_places=3)
    # HSV
    hue         = models.DecimalField(
        max_digits=6, decimal_places=2, default=0)
    saturation  = models.DecimalField(
        max_digits=5, decimal_places=2, default=0)
    value       = models.DecimalField(
        max_digits=5, decimal_places=2, default=0)
    # Pfund
    pfund_mm    = models.DecimalField(
        max_digits=5, decimal_places=1, default=0)
    pfund_grade = models.CharField(max_length=30, default='Unknown')
    pfund_code  = models.CharField(max_length=5,  default='--')

    def __str__(self):
        return (f'{self.assessment.sample_label} — '
                f'Pfund:{self.pfund_mm}mm '
                f'HUE:{self.hue}°')
    assessment = models.OneToOneField(Assessment, on_delete=models.CASCADE,
                                      related_name='rgb_result')
    r_avg      = models.DecimalField(max_digits=6, decimal_places=2)
    g_avg      = models.DecimalField(max_digits=6, decimal_places=2)
    b_avg      = models.DecimalField(max_digits=6, decimal_places=2)
    rg_ratio   = models.DecimalField(max_digits=5, decimal_places=3)
    rb_ratio   = models.DecimalField(max_digits=5, decimal_places=3)
    avg_score  = models.DecimalField(max_digits=5, decimal_places=3)

    def __str__(self):
        return f'RGB for {self.assessment.sample_label} — R:{self.r_avg} G:{self.g_avg} B:{self.b_avg}'


# ── QR CERTIFICATE ───────────────────────────────────────────────────
class QRCertificate(models.Model):
    assessment     = models.OneToOneField(Assessment, on_delete=models.CASCADE,
                                          related_name='qr_certificate')
    qr_data        = models.JSONField()
    qr_image       = models.ImageField(upload_to='qr_codes/')
    generated_at   = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'QR for {self.assessment.sample_label}'