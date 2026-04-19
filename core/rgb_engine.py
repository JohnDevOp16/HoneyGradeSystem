import math


# ══════════════════════════════════════════════════════════════════════
#  HONEYGRADE PROFESSIONAL ASSESSMENT ENGINE
#  Based on:
#    - USDA AMS-56 Honey Colour Standards
#    - Codex Alimentarius CODEX STAN 12-1981
#    - Tanzania Bureau of Standards TZS 37:1997
#
#  IMPORTANT DISCLAIMER:
#  Colour analysis is ONE indicator of honey quality.
#  A complete quality assessment requires:
#    - Moisture content (refractometer, max 20% per Codex)
#    - HMF level (max 40 mg/kg per Codex)
#    - Sugar profile (HPLC analysis)
#    - Microbiological testing
#    - Sensory evaluation (taste, aroma, texture)
#
#  This system provides a colour-based grade as a SCREENING TOOL only.
# ══════════════════════════════════════════════════════════════════════


# ── GRADE DEFINITIONS ─────────────────────────────────────────────────
GRADES = {
    'A': {
        'label':          'Grade A',
        'title':          'Premium Amber',
        'pfund_min':      51,
        'pfund_max':      140,
        'hue_min':        10,
        'hue_max':        38,
        'sat_min':        40,
        'rg_min':         1.15,
        'colour_class':   'Light Amber to Dark Amber',
        'usda_codes':     ['LA', 'A', 'DA'],
        'market':         'Premium local and export market',
        'confidence':     'High colour confidence',
        'recommendation': (
            'Colour profile is consistent with premium natural honey. '
            'Proceed with moisture content test (target ≤ 20%) and '
            'HMF test (target ≤ 40 mg/kg) before export certification.'
        ),
    },
    'B': {
        'label':          'Grade B',
        'title':          'Good Quality',
        'pfund_min':      35,
        'pfund_max':      85,
        'hue_min':        28,
        'hue_max':        52,
        'sat_min':        30,
        'rg_min':         1.05,
        'colour_class':   'Extra Light Amber to Light Amber',
        'usda_codes':     ['ELA', 'LA'],
        'market':         'Standard local and regional market',
        'confidence':     'Good colour confidence',
        'recommendation': (
            'Colour profile meets standard honey requirements. '
            'Suitable for local market. For export, additional '
            'testing including moisture content, sugar profile '
            'and sensory evaluation is recommended.'
        ),
    },
    'C': {
        'label':          'Grade C',
        'title':          'Acceptable',
        'pfund_min':      15,
        'pfund_max':      50,
        'hue_min':        42,
        'hue_max':        68,
        'sat_min':        18,
        'rg_min':         0.95,
        'colour_class':   'White to Extra Light Amber',
        'usda_codes':     ['W', 'EW', 'ELA'],
        'market':         'Local market only',
        'confidence':     'Moderate colour confidence',
        'recommendation': (
            'Colour profile is lighter than standard amber honey. '
            'This may indicate a naturally lighter variety (e.g. acacia), '
            'light filtration, or early harvest. Lab testing for moisture '
            'content and sugar profile is strongly recommended before sale. '
            'Do not export without full quality certification.'
        ),
    },
    'D': {
        'label':          'Grade D',
        'title':          'Below Standard',
        'pfund_min':      0,
        'pfund_max':      20,
        'hue_min':        55,
        'hue_max':        360,
        'sat_min':        0,
        'rg_min':         0,
        'colour_class':   'Water White to Extra White',
        'usda_codes':     ['WW', 'EW'],
        'market':         'Not recommended for sale without lab testing',
        'confidence':     'Low colour confidence',
        'recommendation': (
            'Colour profile does not meet minimum honey colour standards. '
            'Possible causes include: adulteration with water or sugar syrup, '
            'excessive heat processing, very early harvest (high moisture), '
            'or a non-honey substance. This is a COLOUR SCREENING RESULT only '
            '— laboratory analysis including refractometry, HMF testing and '
            'sugar profile (HPLC) is required before any market use. '
            'Do not sell without professional quality certification.'
        ),
    },
}


# ══════════════════════════════════════════════════════════════════════
#  RGB → HSV CONVERTER
# ══════════════════════════════════════════════════════════════════════
def rgb_to_hsv(r, g, b):
    """
    Convert RGB (0-255) to HSV.
    Returns hue (0-360°), saturation (0-100%), value (0-100%)
    """
    r_n = r / 255.0
    g_n = g / 255.0
    b_n = b / 255.0

    c_max  = max(r_n, g_n, b_n)
    c_min  = min(r_n, g_n, b_n)
    delta  = c_max - c_min

    # Hue
    if delta == 0:
        hue = 0.0
    elif c_max == r_n:
        hue = 60 * (((g_n - b_n) / delta) % 6)
    elif c_max == g_n:
        hue = 60 * (((b_n - r_n) / delta) + 2)
    else:
        hue = 60 * (((r_n - g_n) / delta) + 4)

    if hue < 0:
        hue += 360

    saturation = 0.0 if c_max == 0 else (delta / c_max) * 100
    value      = c_max * 100

    return round(hue, 2), round(saturation, 2), round(value, 2)


# ══════════════════════════════════════════════════════════════════════
#  HUE + SATURATION → PFUND SCALE
# ══════════════════════════════════════════════════════════════════════
def hue_to_pfund(hue, saturation, value):
    """
    Convert HUE angle to Pfund scale (mm).
    Based on USDA AMS-56 spectrophotometric correlation
    modified for RGB-extracted HSV values.
    """
    if saturation < 12:
        return 5.0
    if value < 20:
        return 5.0

    if hue <= 15:
        pfund = 130 + (15 - hue) * 1.5
    elif hue <= 22:
        pfund = 110 + (22 - hue) * 2.86
    elif hue <= 30:
        pfund = 86  + (30 - hue) * 3.0
    elif hue <= 38:
        pfund = 51  + (38 - hue) * 4.375
    elif hue <= 46:
        pfund = 35  + (46 - hue) * 2.0
    elif hue <= 54:
        pfund = 18  + (54 - hue) * 2.125
    elif hue <= 60:
        pfund = 9   + (60 - hue) * 1.5
    else:
        pfund = max(0, 9 - (hue - 60) * 1.5)

    # Adjustments
    pfund = pfund * (0.6 + 0.4 * (saturation / 100.0))
    pfund = pfund * (0.7 + 0.3 * (value / 100.0))

    return round(min(max(pfund, 0), 140), 1)


# ══════════════════════════════════════════════════════════════════════
#  PFUND → USDA COLOUR GRADE
# ══════════════════════════════════════════════════════════════════════
def pfund_to_usda(pfund_mm):
    """
    Map Pfund value to official USDA colour grade.
    Source: USDA AMS-56 Honey Grading Manual
    """
    if pfund_mm <= 8:
        return {'grade': 'Water White',       'code': 'WW',  'range': '0–8 mm'}
    elif pfund_mm <= 17:
        return {'grade': 'Extra White',        'code': 'EW',  'range': '9–17 mm'}
    elif pfund_mm <= 34:
        return {'grade': 'White',              'code': 'W',   'range': '18–34 mm'}
    elif pfund_mm <= 50:
        return {'grade': 'Extra Light Amber',  'code': 'ELA', 'range': '35–50 mm'}
    elif pfund_mm <= 85:
        return {'grade': 'Light Amber',        'code': 'LA',  'range': '51–85 mm'}
    elif pfund_mm <= 114:
        return {'grade': 'Amber',              'code': 'A',   'range': '86–114 mm'}
    else:
        return {'grade': 'Dark Amber',         'code': 'DA',  'range': '>114 mm'}


# ══════════════════════════════════════════════════════════════════════
#  PROFESSIONAL GRADE ASSIGNMENT
# ══════════════════════════════════════════════════════════════════════
def assign_grade(pfund_mm, hue, saturation, rg_ratio):
    """
    Assign professional grade (A, B, C, D) based on combined
    Pfund scale, HUE, saturation and RGB ratio analysis.

    Grading is based on colour profile only.
    A complete honey quality assessment requires additional
    laboratory testing as specified in Codex STAN 12-1981.
    """

    # ── GRADE A — Premium Amber ────────────────────────────────────────
    if (pfund_mm >= 51
            and hue  <= 38
            and saturation >= 40
            and rg_ratio >= 1.15):
        return 'A'

    # ── GRADE B — Good Quality ─────────────────────────────────────────
    elif (pfund_mm >= 35
            and hue  <= 52
            and saturation >= 28
            and rg_ratio >= 1.05):
        return 'B'

    # ── GRADE C — Acceptable ───────────────────────────────────────────
    elif (pfund_mm >= 15
            and hue  <= 68
            and saturation >= 16
            and rg_ratio >= 0.92):
        return 'C'

    # ── GRADE D — Below Standard ───────────────────────────────────────
    else:
        return 'D'


# ══════════════════════════════════════════════════════════════════════
#  CONFIDENCE SCORE
# ══════════════════════════════════════════════════════════════════════
def compute_confidence(saturation, value, pfund_mm):
    """
    Compute a confidence percentage for the colour assessment.
    Higher saturation and brightness = more reliable colour reading.
    """
    sat_score   = min(saturation / 60.0, 1.0)   # max at 60% sat
    val_score   = min(value / 80.0, 1.0)         # max at 80% brightness
    pfund_score = min(pfund_mm / 85.0, 1.0)      # max at 85mm Pfund

    confidence = (sat_score * 0.45 +
                  val_score * 0.30 +
                  pfund_score * 0.25) * 100

    return round(min(confidence, 98), 1)  # cap at 98% — never 100%


# ══════════════════════════════════════════════════════════════════════
#  BUILD PROFESSIONAL REPORT
# ══════════════════════════════════════════════════════════════════════
def build_report(grade_key, usda, pfund_mm, hue,
                 saturation, value, rg_ratio, confidence):
    """
    Build a complete professional assessment report.
    """
    grade = GRADES[grade_key]

    description = (
        f'COLOUR-BASED SCREENING RESULT\n\n'
        f'Professional Grade:  {grade["label"]} — {grade["title"]}\n'
        f'USDA Colour Class:   {usda["grade"]} ({usda["code"]}) '
        f'— {usda["range"]}\n'
        f'Pfund Value:         {pfund_mm} mm\n'
        f'HUE Angle:           {hue}°\n'
        f'Saturation:          {saturation}%\n'
        f'Colour Confidence:   {confidence}%\n\n'
        f'Colour Classification: {grade["colour_class"]}\n'
        f'Market Suitability:    {grade["market"]}\n\n'
        f'RECOMMENDATION:\n{grade["recommendation"]}\n\n'
        f'IMPORTANT DISCLAIMER:\n'
        f'This assessment is based on RGB colour analysis only. '
        f'Colour is one indicator of honey quality but does not '
        f'solely determine overall quality. A complete assessment '
        f'per Codex Alimentarius CODEX STAN 12-1981 requires: '
        f'moisture content ≤ 20%, HMF ≤ 40 mg/kg, sugar profile, '
        f'and sensory evaluation. Results of this screening should '
        f'be used as a preliminary guide only.\n\n'
        f'Standards Referenced:\n'
        f'• USDA AMS-56 Honey Grading Manual\n'
        f'• Codex Alimentarius CODEX STAN 12-1981\n'
        f'• Tanzania Bureau of Standards TZS 37:1997'
    )

    return {
        'grade':            grade_key,
        'grade_label':      grade['label'],
        'grade_title':      grade['title'],
        'colour_class':     grade['colour_class'],
        'market':           grade['market'],
        'recommendation':   grade['recommendation'],
        'confidence':       confidence,
        'description':      description,
    }


# ══════════════════════════════════════════════════════════════════════
#  IMAGE RGB EXTRACTION
# ══════════════════════════════════════════════════════════════════════
def extract_rgb(image_file):
    """
    Open image, crop centre 60% ROI, compute average R, G, B.
    """
    from PIL import Image
    img  = Image.open(image_file).convert('RGB')
    w, h = img.size
    roi  = img.crop((int(w*0.2), int(h*0.2),
                     int(w*0.8), int(h*0.8)))
    pixels = list(roi.getdata())
    n      = len(pixels)
    r_avg  = sum(p[0] for p in pixels) / n
    g_avg  = sum(p[1] for p in pixels) / n
    b_avg  = sum(p[2] for p in pixels) / n
    return round(r_avg, 2), round(g_avg, 2), round(b_avg, 2)


# ══════════════════════════════════════════════════════════════════════
#  MAIN PIPELINE
# ══════════════════════════════════════════════════════════════════════
def assess_image(image_file):
    """
    Full professional assessment pipeline:
    Image → RGB → HSV → Pfund → USDA Grade →
    Professional Grade (A/B/C/D) → Confidence → Report
    """
    # Step 1 — RGB extraction
    r_avg, g_avg, b_avg = extract_rgb(image_file)

    # Step 2 — RGB to HSV
    hue, saturation, value = rgb_to_hsv(r_avg, g_avg, b_avg)

    # Step 3 — Pfund scale
    pfund_mm = hue_to_pfund(hue, saturation, value)

    # Step 4 — USDA colour grade
    usda = pfund_to_usda(pfund_mm)

    # Step 5 — RGB ratios
    g_safe    = g_avg if g_avg > 0 else 0.01
    b_safe    = b_avg if b_avg > 0 else 0.01
    rg_ratio  = round(r_avg / g_safe, 3)
    rb_ratio  = round(r_avg / b_safe, 3)
    avg_score = round((rg_ratio + rb_ratio) / 2, 3)

    # Step 6 — Professional grade (A/B/C/D)
    grade_key = assign_grade(pfund_mm, hue, saturation, rg_ratio)

    # Step 7 — Confidence score
    confidence = compute_confidence(saturation, value, pfund_mm)

    # Step 8 — Build full report
    report = build_report(
        grade_key, usda, pfund_mm, hue,
        saturation, value, rg_ratio, confidence)

    return {
        # RGB
        'r_avg':          r_avg,
        'g_avg':          g_avg,
        'b_avg':          b_avg,
        'rg_ratio':       rg_ratio,
        'rb_ratio':       rb_ratio,
        'avg_score':      avg_score,
        # HSV
        'hue':            hue,
        'saturation':     saturation,
        'value':          value,
        # Pfund
        'pfund_mm':       pfund_mm,
        'pfund_grade':    usda['grade'],
        'pfund_code':     usda['code'],
        'pfund_range':    usda['range'],
        # Professional grade
        'quality_result': grade_key,          # 'A', 'B', 'C', 'D'
        'grade_label':    report['grade_label'],
        'grade_title':    report['grade_title'],
        'colour_class':   report['colour_class'],
        'market':         report['market'],
        'confidence':     confidence,
        'recommendation': report['recommendation'],
        'description':    report['description'],
    }