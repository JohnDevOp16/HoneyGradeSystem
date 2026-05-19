import qrcode
import json
import os
from io                     import BytesIO
from django.core.files.base import ContentFile
from PIL                    import Image, ImageDraw, ImageFont


def generate_qr(assessment):
    """
    Generate a professional QR certificate image.
    QR encodes: grade, pfund, hue, usda, assessor, date, sample.
    """
    # ── Build QR data payload ─────────────────────────────────────────
    try:
        rgb = assessment.rgb_result
        pfund_grade = rgb.pfund_grade
        pfund_mm    = str(rgb.pfund_mm)
        pfund_code  = rgb.pfund_code
        hue         = str(rgb.hue)
        confidence  = str(assessment.confidence)
    except Exception:
        pfund_grade = '--'
        pfund_mm    = '--'
        pfund_code  = '--'
        hue         = '--'
        confidence  = '--'

    qr_data = {
        'platform':     'HoneyGrade',
        'version':      '2.0',
        'sample_id':    assessment.sample_label,
        'assessor':     (assessment.user.get_full_name()
                        or assessment.user.username),
        'region':       assessment.user.region,
        'date':         assessment.assessed_at.strftime('%Y-%m-%d %H:%M'),
        'grade':        assessment.quality_result,
        'grade_label':  assessment.grade_label,
        'grade_title':  assessment.grade_title,
        'colour_class': assessment.colour_class,
        'market':       assessment.market,
        'confidence':   confidence + '%',
        'pfund_grade':  pfund_grade,
        'pfund_mm':     pfund_mm + ' mm',
        'pfund_code':   pfund_code,
        'hue_angle':    hue + '°',
        'standards':    'USDA AMS-56 / Codex STAN 12-1981',
        'disclaimer':   'Colour screening only. Lab testing required.',
    }

    # ── Generate QR code ──────────────────────────────────────────────
    grade_colors = {
        'A': ('#16A34A', '#F0FDF4'),
        'B': ('#2563EB', '#EFF6FF'),
        'C': ('#CA8A04', '#FEFCE8'),
        'D': ('#DC2626', '#FEF2F2'),
    }
    grade = assessment.quality_result
    dark_color, light_color = grade_colors.get(
        grade, ('#78350F', '#FFFBEB'))

    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=8,
        border=2,
    )
    qr.add_data(json.dumps(qr_data, ensure_ascii=False))
    qr.make(fit=True)

    qr_img = qr.make_image(
        fill_color=dark_color,
        back_color='white'
    ).convert('RGB')

    # ── Build certificate card ────────────────────────────────────────
    card_w, card_h = 500, 620
    card = Image.new('RGB', (card_w, card_h), '#FFFBEB')
    draw = ImageDraw.Draw(card)

    # Header gradient strip
    header_color = dark_color
    draw.rectangle([0, 0, card_w, 90], fill=header_color)

    # Honey jar emoji area (circle)
    draw.ellipse([20, 15, 70, 65], fill='white')
    draw.text((28, 18), '🍯', fill=header_color)

    # Header text
    draw.text((85, 20), 'HoneyGrade', fill='white')
    draw.text((85, 45), 'Professional Honey Quality Certificate', fill='#FDE68A')
    draw.text((85, 65), 'USDA AMS-56  |  Codex STAN 12-1981', fill='#FCD34D')

    # Grade circle
    grade_x, grade_y, grade_r = 400, 45, 35
    draw.ellipse(
        [grade_x - grade_r, grade_y - grade_r,
         grade_x + grade_r, grade_y + grade_r],
        fill='white')
    draw.text((grade_x - 10, grade_y - 16), grade,
              fill=header_color)

    # Sample info section
    draw.rectangle([0, 90, card_w, 92], fill='#F59E0B')
    draw.rectangle([20, 105, card_w - 20, 200],
                   fill=light_color, outline=dark_color + '40')

    draw.text((35, 115), 'Sample ID:', fill='#92400E')
    draw.text((35, 133), assessment.sample_label or '--',
              fill='#1C0A00')
    draw.text((35, 153), 'Assessor:', fill='#92400E')
    draw.text((35, 171), (assessment.user.get_full_name()
                          or assessment.user.username),
              fill='#1C0A00')

    draw.text((260, 115), 'Date:', fill='#92400E')
    draw.text((260, 133),
              assessment.assessed_at.strftime('%Y-%m-%d'),
              fill='#1C0A00')
    draw.text((260, 153), 'Region:', fill='#92400E')
    draw.text((260, 171), assessment.user.region or '--',
              fill='#1C0A00')

    # Grade result section
    draw.rectangle([20, 210, card_w - 20, 290],
                   fill=dark_color)
    draw.text((35, 218), 'ASSESSMENT RESULT', fill='#FDE68A')
    draw.text((35, 238), assessment.grade_label or ('Grade ' + grade),
              fill='white')
    draw.text((35, 260), assessment.grade_title or '',
              fill='#FCD34D')

    # Confidence
    conf = float(assessment.confidence or 0)
    draw.text((card_w - 130, 238), f'Confidence', fill='#FDE68A')
    draw.text((card_w - 100, 258), f'{conf:.1f}%', fill='white')

    # Technical data section
    draw.rectangle([20, 300, card_w - 20, 390],
                   fill='white', outline='#FCD34D')
    draw.text((35, 308), 'COLOUR ANALYSIS DATA', fill='#92400E')
    draw.line([35, 322, card_w - 35, 322], fill='#FCD34D', width=1)

    draw.text((35, 330), f'Pfund Value:', fill='#44230B')
    draw.text((160, 330), pfund_mm + ' mm', fill='#1C0A00')
    draw.text((260, 330), f'USDA Grade:', fill='#44230B')
    draw.text((370, 330), pfund_grade, fill='#1C0A00')

    draw.text((35, 350), f'Pfund Code:', fill='#44230B')
    draw.text((160, 350), pfund_code, fill='#1C0A00')
    draw.text((260, 350), f'HUE Angle:', fill='#44230B')
    draw.text((370, 350), hue + '°', fill='#1C0A00')

    draw.text((35, 370), f'Colour Class:', fill='#44230B')
    draw.text((160, 370),
              (assessment.colour_class or '--')[:30],
              fill='#1C0A00')

    # QR code section
    qr_size = 180
    qr_resized = qr_img.resize((qr_size, qr_size), Image.LANCZOS)
    qr_x = (card_w - qr_size) // 2
    card.paste(qr_resized, (qr_x, 400))

    draw.text((card_w // 2 - 80, 590),
              'Scan to verify certificate',
              fill='#92400E')

    # Disclaimer footer
    draw.rectangle([0, card_h - 30, card_w, card_h],
                   fill='#FEF3C7')
    draw.text((10, card_h - 22),
              'Colour screening only. Full lab testing required for certification.',
              fill='#92400E')

    # Border
    draw.rectangle([0, 0, card_w - 1, card_h - 1],
                   outline=dark_color, width=3)
    draw.rectangle([3, 3, card_w - 4, card_h - 4],
                   outline='#F59E0B', width=1)

    # ── Save to buffer ────────────────────────────────────────────────
    buffer = BytesIO()
    card.save(buffer, format='PNG', quality=95)
    buffer.seek(0)

    filename      = f'qr_{assessment.sample_label}_{assessment.id}.png'
    image_content = ContentFile(buffer.read(), name=filename)

    return qr_data, image_content