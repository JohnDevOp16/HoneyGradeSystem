import qrcode
import json
import os
from io               import BytesIO
from django.core.files.base import ContentFile


def generate_qr(assessment):
    qr_data = {
        'platform':      'HoneyGrade',
        'sample_id':     assessment.sample_label,
        'assessor':      (assessment.user.get_full_name()
                         or assessment.user.username),
        'date':          assessment.assessed_at.strftime(
                         '%Y-%m-%d %H:%M'),
        'region':        assessment.user.region,
        # Professional grade
        'grade':         assessment.quality_result,
        'grade_label':   assessment.grade_label,
        'grade_title':   assessment.grade_title,
        'colour_class':  assessment.colour_class,
        'confidence':    f'{assessment.confidence}%',
        'market':        assessment.market,
        # Pfund info
        'pfund_grade':   getattr(
            assessment.rgb_result, 'pfund_grade', '--'),
        'pfund_mm':      str(getattr(
            assessment.rgb_result, 'pfund_mm', '--')),
        'pfund_code':    getattr(
            assessment.rgb_result, 'pfund_code', '--'),
        # Standards
        'standard':      'USDA AMS-56 / Codex STAN 12-1981',
        'disclaimer':    'Colour screening only. Lab testing required.',
    }
    # Data to encode into the QR code
    qr_data = {
        'platform':      'HoneyGrade',
        'sample_id':     assessment.sample_label,
        'assessor':      assessment.user.get_full_name() or assessment.user.username,
        'result':        assessment.quality_result.upper(),
        'date':          assessment.assessed_at.strftime('%Y-%m-%d %H:%M'),
        'region':        assessment.user.region,
    }

    # Generate QR image
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    qr.add_data(json.dumps(qr_data))
    qr.make(fit=True)

    img     = qr.make_image(fill_color='#78350F', back_color='#FFFBEB')
    buffer  = BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)

    filename      = f'qr_{assessment.sample_label}_{assessment.id}.png'
    image_content = ContentFile(buffer.read(), name=filename)

    return qr_data, image_content