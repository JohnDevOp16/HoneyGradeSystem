from rest_framework import serializers
from .models import User, Assessment, RGBResult, QRCertificate

# ── REGISTER ─────────────────────────────────────────────────────────
class RegisterSerializer(serializers.ModelSerializer):
    password  = serializers.CharField(write_only=True, min_length=6)
    password2 = serializers.CharField(write_only=True, label='Confirm Password')

    class Meta:
        model  = User
        fields = [
            'username', 'first_name', 'last_name',
            'email', 'phone', 'region', 'role',
            'password', 'password2',
        ]

    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError('Passwords do not match.')
        return data

    def create(self, validated_data):
        validated_data.pop('password2')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


# ── USER PROFILE ─────────────────────────────────────────────────────
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = [
            'id', 'username', 'first_name', 'last_name',
            'email', 'phone', 'region', 'role', 'created_at',
        ]

        from .models import Assessment, RGBResult, QRCertificate


# ── ASSESSMENT ────────────────────────────────────────────────────────
class AssessmentSerializer(serializers.ModelSerializer):
    rgb_result     = serializers.SerializerMethodField()
    qr_certificate = serializers.SerializerMethodField()

    class Meta:
        model  = Assessment
        fields = [
            'id', 'sample_label', 'image',
            # Grade fields
            'quality_result', 'grade_label', 'grade_title',
            'colour_class', 'market', 'confidence',
            'recommendation', 'description',
            'assessed_at',
            # Related
            'rgb_result', 'qr_certificate',
        ]

    def get_rgb_result(self, obj):
        try:
            r = obj.rgb_result
            return {
                'r_avg':      float(r.r_avg),
                'g_avg':      float(r.g_avg),
                'b_avg':      float(r.b_avg),
                'rg_ratio':   float(r.rg_ratio),
                'rb_ratio':   float(r.rb_ratio),
                'avg_score':  float(r.avg_score),
                'hue':        float(r.hue),
                'saturation': float(r.saturation),
                'value':      float(r.value),
                'pfund_mm':   float(r.pfund_mm),
                'pfund_grade': r.pfund_grade,
                'pfund_code':  r.pfund_code,
            }
        except RGBResult.DoesNotExist:
            return None

    def get_qr_certificate(self, obj):
        try:
            qr      = obj.qr_certificate
            request = self.context.get('request')
            qr_url  = request.build_absolute_uri(qr.qr_image.url) \
                      if request else qr.qr_image.url
            return {
                'qr_data':  qr.qr_data,
                'qr_image': qr_url,
            }
        except QRCertificate.DoesNotExist:
            return None
    rgb_result     = serializers.SerializerMethodField()
    qr_certificate = serializers.SerializerMethodField()

    class Meta:
        model  = Assessment
        fields = [
            'id', 'sample_label', 'image', 'quality_result',
            'description', 'assessed_at', 'rgb_result', 'qr_certificate',
        ]

    def get_rgb_result(self, obj):
        try:
            r = obj.rgb_result
            return {
                'r_avg':     float(r.r_avg),
                'g_avg':     float(r.g_avg),
                'b_avg':     float(r.b_avg),
                'rg_ratio':  float(r.rg_ratio),
                'rb_ratio':  float(r.rb_ratio),
                'avg_score': float(r.avg_score),
                'hue':        float(r.hue),
                'saturation': float(r.saturation),
                'value':      float(r.value),
                'pfund_mm':   float(r.pfund_mm),
            }
        except RGBResult.DoesNotExist:
            return None

    def get_qr_certificate(self, obj):
        try:
            qr      = obj.qr_certificate
            request = self.context.get('request')
            qr_url  = request.build_absolute_uri(qr.qr_image.url) \
                      if request else qr.qr_image.url
            return {
                'qr_data':  qr.qr_data,
                'qr_image': qr_url,
            }
        except QRCertificate.DoesNotExist:
            return None
        
        # ── QR CERTIFICATE ────────────────────────────────────────────────────
class QRCertificateSerializer(serializers.ModelSerializer):
    class Meta:
        model  = QRCertificate
        fields = ['id', 'qr_data', 'qr_image', 'generated_at']