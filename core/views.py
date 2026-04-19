from rest_framework              import status
from rest_framework.response     import Response
from rest_framework.views        import APIView
from rest_framework.permissions  import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts            import render
from django.http                 import HttpResponse
import csv
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

from .models       import User, Assessment, RGBResult, QRCertificate
from .serializers  import (RegisterSerializer, UserSerializer,
                            AssessmentSerializer, QRCertificateSerializer)
from .rgb_engine   import assess_image
from .qr_generator import generate_qr


# ── REGISTER ──────────────────────────────────────────────────────────
@method_decorator(csrf_exempt, name='dispatch')
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'Account created successfully.',
                'user':    UserSerializer(user).data,
                'tokens': {
                    'refresh': str(refresh),
                    'access':  str(refresh.access_token),
                }
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── LOGIN ─────────────────────────────────────────────────────────────
@method_decorator(csrf_exempt, name='dispatch')
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return Response(
                {'error': 'Username and password are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response(
                {'error': 'Invalid username or password.'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.check_password(password):
            return Response(
                {'error': 'Invalid username or password.'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Login successful.',
            'user':    UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access':  str(refresh.access_token),
            }
        }, status=status.HTTP_200_OK)


# ── PROFILE ───────────────────────────────────────────────────────────
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def put(self, request):
        serializer = UserSerializer(
            request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── ASSESS HONEY ──────────────────────────────────────────────────────
class AssessHoneyView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        image        = request.FILES.get('image')
        sample_label = request.data.get('sample_label', 'Sample')

        if not image:
            return Response(
                {'error': 'No image uploaded.'},
                status=status.HTTP_400_BAD_REQUEST)

        results = assess_image(image)

        # Save Assessment with all new fields
        assessment = Assessment.objects.create(
            user           = request.user,
            sample_label   = sample_label,
            image          = image,
            quality_result = results['quality_result'],
            grade_label    = results['grade_label'],
            grade_title    = results['grade_title'],
            colour_class   = results['colour_class'],
            market         = results['market'],
            confidence     = results['confidence'],
            recommendation = results['recommendation'],
            description    = results['description'],
        )

        # Save RGB + HSV + Pfund
        RGBResult.objects.create(
            assessment  = assessment,
            r_avg       = results['r_avg'],
            g_avg       = results['g_avg'],
            b_avg       = results['b_avg'],
            rg_ratio    = results['rg_ratio'],
            rb_ratio    = results['rb_ratio'],
            avg_score   = results['avg_score'],
            hue         = results['hue'],
            saturation  = results['saturation'],
            value       = results['value'],
            pfund_mm    = results['pfund_mm'],
            pfund_grade = results['pfund_grade'],
            pfund_code  = results['pfund_code'],
        )

        # Generate QR
        qr_data, qr_image = generate_qr(assessment)
        QRCertificate.objects.create(
            assessment = assessment,
            qr_data    = qr_data,
            qr_image   = qr_image,
        )

        return Response({
            'message':    'Assessment complete.',
            'assessment': AssessmentSerializer(
                assessment,
                context={'request': request}).data,
        }, status=status.HTTP_201_CREATED)


# ── ASSESSMENT HISTORY ────────────────────────────────────────────────
class AssessmentHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        assessments = Assessment.objects.filter(
            user=request.user).order_by('-assessed_at')
        serializer  = AssessmentSerializer(
            assessments, many=True, context={'request': request})
        return Response(serializer.data)


# ── ASSESSMENT DETAIL ─────────────────────────────────────────────────
class AssessmentDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            assessment = Assessment.objects.get(pk=pk, user=request.user)
        except Assessment.DoesNotExist:
            return Response(
                {'error': 'Assessment not found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        return Response(
            AssessmentSerializer(assessment, context={'request': request}).data)


# ── EXPORT CSV ────────────────────────────────────────────────────────
class ExportCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = \
            'attachment; filename="honeygrade_assessments.csv"'

        writer = csv.writer(response)
        writer.writerow([
            'Sample ID', 'Date', 'Quality Result',
            'R avg', 'G avg', 'B avg',
            'R:G Ratio', 'R:B Ratio', 'Avg Score', 'Description',
        ])

        assessments = Assessment.objects.filter(
            user=request.user).order_by('-assessed_at')

        for a in assessments:
            try:
                rgb = a.rgb_result
                writer.writerow([
                    a.sample_label,
                    a.assessed_at.strftime('%Y-%m-%d %H:%M'),
                    a.quality_result.upper(),
                    rgb.r_avg, rgb.g_avg, rgb.b_avg,
                    rgb.rg_ratio, rgb.rb_ratio, rgb.avg_score,
                    a.description,
                ])
            except RGBResult.DoesNotExist:
                pass

        return response


# ── DASHBOARD STATS ───────────────────────────────────────────────────
class DashboardStatsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        assessments  = Assessment.objects.filter(user=request.user)
        total        = assessments.count()
        quality      = assessments.filter(quality_result='quality').count()
        intermediate = assessments.filter(quality_result='intermediate').count()
        poor         = assessments.filter(quality_result='poor').count()

        recent = AssessmentSerializer(
            assessments.order_by('-assessed_at')[:5],
            many=True,
            context={'request': request}
        ).data

        return Response({
            'total':        total,
            'quality':      quality,
            'intermediate': intermediate,
            'poor':         poor,
            'pass_rate':    round((quality / total * 100), 1) if total > 0 else 0,
            'recent':       recent,
        })


# ── TEMPLATE VIEWS ────────────────────────────────────────────────────
def login_page(request):
    return render(request, 'core/login.html')


def dashboard_page(request):
    return render(request, 'core/dashboard.html')