import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def make_icon():
    S = 2048
    cx = S / 2.0
    cy = S / 2.0 + 350.0  # approximate starting pivot
    
    # ── 1. GEOMETRY HELPERS ──────────────────────────────────────────────────
    def cubic_bezier(p0, p1, p2, p3, steps=90):
        t = np.linspace(0, 1, steps)
        x = (1-t)**3 * p0[0] + 3*(1-t)**2*t * p1[0] + 3*(1-t)*t**2 * p2[0] + t**3 * p3[0]
        y = (1-t)**3 * p0[1] + 3*(1-t)**2*t * p1[1] + 3*(1-t)*t**2 * p2[1] + t**3 * p3[1]
        return list(zip(x, y))

    def rotate_point(p, angle_rad, origin=(0, 0)):
        ox, oy = origin
        px, py = p
        qx = ox + math.cos(angle_rad) * (px - ox) - math.sin(angle_rad) * (py - oy)
        qy = oy + math.sin(angle_rad) * (px - ox) + math.cos(angle_rad) * (py - oy)
        return (qx, qy)

    def generate_petal_shape(length, width, angle_deg, pivot=(cx, cy), curve_pinch=0.38):
        p0 = (0, 0)
        p1 = (-width * 0.92, -length * curve_pinch)
        p2 = (-width * 0.58, -length * 0.83)
        p3 = (0, -length)
        pts_left = cubic_bezier(p0, p1, p2, p3, steps=75)
        
        p4 = (width * 0.58, -length * 0.83)
        p5 = (width * 0.92, -length * curve_pinch)
        p6 = (0, 0)
        pts_right = cubic_bezier(p3, p4, p5, p6, steps=75)
        
        raw_pts = pts_left + pts_right
        rad = math.radians(angle_deg)
        transformed = []
        for pt in raw_pts:
            rot_pt = rotate_point(pt, rad, origin=(0, 0))
            transformed.append((rot_pt[0] + pivot[0], rot_pt[1] + pivot[1]))
            
        spine_pts = cubic_bezier((0, 0), (0, -length * 0.33), (0, -length * 0.66), (0, -length), steps=45)
        spine_trans = []
        for pt in spine_pts:
            rot_pt = rotate_point(pt, rad, origin=(0, 0))
            spine_trans.append((rot_pt[0] + pivot[0], rot_pt[1] + pivot[1]))
            
        return transformed, spine_trans

    y_grid, x_grid = np.mgrid[0:S, 0:S]

    def render_gradient_petal(poly_pts, spine_pts, c_tip, c_base, highlight_color=(255, 255, 255, 95)):
        mask = Image.new("L", (S, S), 0)
        mdraw = ImageDraw.Draw(mask)
        mdraw.polygon(poly_pts, fill=255)
        
        mask_arr = np.array(mask).astype(np.float32) / 255.0
        ys = [p[1] for p in poly_pts]
        top_y, bot_y = min(ys), max(ys)
        span = max(bot_y - top_y, 1.0)
        
        grad_t = np.clip((y_grid - top_y) / span, 0.0, 1.0)
        
        r = c_tip[0] * (1.0 - grad_t) + c_base[0] * grad_t
        g = c_tip[1] * (1.0 - grad_t) + c_base[1] * grad_t
        b = c_tip[2] * (1.0 - grad_t) + c_base[2] * grad_t
        a = (c_tip[3] * (1.0 - grad_t) + c_base[3] * grad_t) * mask_arr
        
        arr = np.stack([
            np.clip(r, 0, 255).astype(np.uint8),
            np.clip(g, 0, 255).astype(np.uint8),
            np.clip(b, 0, 255).astype(np.uint8),
            np.clip(a, 0, 255).astype(np.uint8)
        ], axis=-1)
        base_layer = Image.fromarray(arr, mode="RGBA")
        
        spine_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(spine_layer)
        for i in range(len(spine_pts) - 1):
            t_s = i / len(spine_pts)
            alpha_s = int(highlight_color[3] * (1.0 - t_s * 0.5))
            w = max(2, int(10 * (1.0 - t_s)))
            sdraw.line([spine_pts[i], spine_pts[i+1]], fill=(highlight_color[0], highlight_color[1], highlight_color[2], alpha_s), width=w)
            
        spine_blurred = spine_layer.filter(ImageFilter.GaussianBlur(radius=3))
        s_arr = np.array(spine_blurred)
        s_arr[:, :, 3] = (s_arr[:, :, 3].astype(np.float32) * mask_arr).astype(np.uint8)
        spine_masked = Image.fromarray(s_arr, mode="RGBA")
        
        return Image.alpha_composite(base_layer, spine_masked)

    # ── BUILD RAW EMBLEM LAYERS ──────────────────────────────────────────────
    layers = []

    # Halo center is positioned relative to lotus core
    halo_cy = cy - 290
    halo_img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(halo_img)
    
    r1 = 680
    hdraw.ellipse([cx - r1, halo_cy - r1, cx + r1, halo_cy + r1], outline=(6, 182, 212, 130), width=14)
    r2 = 620
    hdraw.ellipse([cx - r2, halo_cy - r2, cx + r2, halo_cy + r2], outline=(139, 92, 246, 85), width=9)
    r3 = 560
    hdraw.ellipse([cx - r3, halo_cy - r3, cx + r3, halo_cy + r3], outline=(16, 185, 129, 65), width=6)
    layers.append(halo_img)

    # Petals (scaled slightly larger for prominent visibility)
    # Tier 1: Outer Petals
    p_out_l, s_out_l = generate_petal_shape(length=780, width=245, angle_deg=-47, pivot=(cx, cy + 30), curve_pinch=0.40)
    l_out_l = render_gradient_petal(p_out_l, s_out_l, (139, 92, 246, 240), (79, 70, 229, 150), (220, 205, 255, 95))
    layers.append(l_out_l)

    p_out_r, s_out_r = generate_petal_shape(length=780, width=245, angle_deg=47, pivot=(cx, cy + 30), curve_pinch=0.40)
    l_out_r = render_gradient_petal(p_out_r, s_out_r, (139, 92, 246, 240), (16, 185, 129, 150), (220, 205, 255, 95))
    layers.append(l_out_r)

    # Tier 2: Mid Petals
    p_mid_l, s_mid_l = generate_petal_shape(length=850, width=230, angle_deg=-26, pivot=(cx, cy + 15), curve_pinch=0.37)
    l_mid_l = render_gradient_petal(p_mid_l, s_mid_l, (6, 182, 212, 250), (99, 102, 241, 180), (180, 245, 255, 115))
    layers.append(l_mid_l)

    p_mid_r, s_mid_r = generate_petal_shape(length=850, width=230, angle_deg=26, pivot=(cx, cy + 15), curve_pinch=0.37)
    l_mid_r = render_gradient_petal(p_mid_r, s_mid_r, (16, 185, 129, 250), (6, 182, 212, 180), (180, 255, 220, 115))
    layers.append(l_mid_r)

    # Tier 3: Inner Petals
    p_inn_l, s_inn_l = generate_petal_shape(length=900, width=215, angle_deg=-11, pivot=(cx, cy), curve_pinch=0.34)
    l_inn_l = render_gradient_petal(p_inn_l, s_inn_l, (56, 189, 248, 255), (6, 182, 212, 225), (220, 250, 255, 140))
    layers.append(l_inn_l)

    p_inn_r, s_inn_r = generate_petal_shape(length=900, width=215, angle_deg=11, pivot=(cx, cy), curve_pinch=0.34)
    l_inn_r = render_gradient_petal(p_inn_r, s_inn_r, (52, 211, 153, 255), (16, 185, 129, 225), (220, 255, 240, 140))
    layers.append(l_inn_r)

    # Tier 4: Central Flame Petal
    p_core, s_core = generate_petal_shape(length=960, width=195, angle_deg=0, pivot=(cx, cy - 15), curve_pinch=0.31)
    l_core = render_gradient_petal(p_core, s_core, (255, 255, 255, 255), (6, 182, 212, 245), (255, 255, 255, 190))
    layers.append(l_core)

    # Pedestal & Base Ripple
    pedestal_img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(pedestal_img)
    
    crescent_top = cubic_bezier((cx - 430, cy - 15), (cx - 190, cy + 90), (cx + 190, cy + 90), (cx + 430, cy - 15), steps=70)
    crescent_bot = cubic_bezier((cx + 430, cy - 15), (cx + 220, cy + 160), (cx - 220, cy + 160), (cx - 430, cy - 15), steps=70)
    pdraw.polygon(crescent_top + crescent_bot, fill=(6, 182, 212, 230))
    
    # Inner luminous node
    pdraw.ellipse([cx - 48, cy + 50, cx + 48, cy + 105], fill=(255, 255, 255, 250))
    pdraw.ellipse([cx - 24, cy + 63, cx + 24, cy + 93], fill=(103, 232, 249, 255))
    
    # Tranquility water ripples
    pdraw.ellipse([cx - 360, cy + 115, cx + 360, cy + 210], outline=(103, 232, 249, 160), width=10)
    pdraw.ellipse([cx - 230, cy + 145, cx + 230, cy + 215], outline=(139, 92, 246, 130), width=7)
    layers.append(pedestal_img)

    # Spark of clarity star at apex
    spark_img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(spark_img)
    sx, sy = cx, cy - 15 - 960
    sr = 60
    star_pts = [
        (sx, sy - sr * 1.55),
        (sx + sr * 0.30, sy - sr * 0.30),
        (sx + sr * 1.55, sy),
        (sx + sr * 0.30, sy + sr * 0.30),
        (sx, sy + sr * 1.55),
        (sx - sr * 0.30, sy + sr * 0.30),
        (sx - sr * 1.55, sy),
        (sx - sr * 0.30, sy - sr * 0.30),
    ]
    sdraw.polygon(star_pts, fill=(255, 255, 255, 255))
    sdraw.ellipse([sx - 18, sy - 18, sx + 18, sy + 18], fill=(255, 255, 255, 255))

    def add_star(x, y, r, alpha=220):
        pts = [
            (x, y - r),
            (x + r * 0.28, y - r * 0.28),
            (x + r, y),
            (x + r * 0.28, y + r * 0.28),
            (x, y + r),
            (x - r * 0.28, y + r * 0.28),
            (x - r, y),
            (x - r * 0.28, y - r * 0.28),
        ]
        sdraw.polygon(pts, fill=(255, 255, 255, alpha))

    add_star(cx - 420, halo_cy - 510, 28, 220)
    add_star(cx + 420, halo_cy - 510, 28, 220)
    add_star(cx - 580, halo_cy - 140, 22, 190)
    add_star(cx + 580, halo_cy - 140, 22, 190)
    layers.append(spark_img)

    # ── MERGE ALL EMBLEM LAYERS ──────────────────────────────────────────────
    raw_emblem = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    for l in layers:
        raw_emblem = Image.alpha_composite(raw_emblem, l)

    # ── DYNAMIC PERFECT CENTERING ────────────────────────────────────────────
    # Find bounding box of non-zero alpha pixels
    alpha_arr = np.array(raw_emblem.split()[-1])
    y_indices, x_indices = np.where(alpha_arr > 20)
    min_y, max_y = np.min(y_indices), np.max(y_indices)
    min_x, max_x = np.min(x_indices), np.max(x_indices)
    
    current_center_y = (min_y + max_y) / 2.0
    current_center_x = (min_x + max_x) / 2.0
    
    shift_y = int(round((S / 2.0) - current_center_y))
    shift_x = int(round((S / 2.0) - current_center_x))
    
    # Translate emblem so its visual bounding box is exactly at (S/2, S/2)
    emblem = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    emblem.paste(raw_emblem, (shift_x, shift_y))
    
    # ── BACKGROUND WITH MATCHING AMBIENT GLOW ────────────────────────────────
    t_v = (y_grid / S).astype(np.float32)
    r_bg = 12.0 * (1.0 - t_v) + 5.0 * t_v
    g_bg = 17.0 * (1.0 - t_v) + 8.0 * t_v
    b_bg = 30.0 * (1.0 - t_v) + 18.0 * t_v
    
    # Center ambient radial glow right at S/2
    dist_c = np.sqrt((x_grid - (S/2))**2 + (y_grid - (S/2))**2)
    glow_c = np.clip(1.0 - (dist_c / (S * 0.65)), 0.0, 1.0) ** 2.0
    
    r_bg += glow_c * 26.0
    g_bg += glow_c * 58.0
    b_bg += glow_c * 115.0
    
    r_bg = np.clip(r_bg, 0, 255).astype(np.uint8)
    g_bg = np.clip(g_bg, 0, 255).astype(np.uint8)
    b_bg = np.clip(b_bg, 0, 255).astype(np.uint8)
    bg_img = Image.fromarray(np.stack([r_bg, g_bg, b_bg], axis=-1), mode="RGB")

    # ── BLOOM GLOW PASSES ────────────────────────────────────────────────────
    glow_wide   = emblem.filter(ImageFilter.GaussianBlur(radius=85))
    glow_medium = emblem.filter(ImageFilter.GaussianBlur(radius=32))
    glow_crisp  = emblem.filter(ImageFilter.GaussianBlur(radius=10))

    final_canvas = bg_img.convert("RGBA")
    final_canvas = Image.alpha_composite(final_canvas, glow_wide)
    final_canvas = Image.alpha_composite(final_canvas, glow_medium)
    final_canvas = Image.alpha_composite(final_canvas, glow_crisp)
    final_canvas = Image.alpha_composite(final_canvas, emblem)

    # ── EXPORT ASSETS ────────────────────────────────────────────────────────
    os.makedirs("assets/icons", exist_ok=True)

    # 1. Main 1024x1024 RGB Icon
    icon_1024 = final_canvas.resize((1024, 1024), Image.Resampling.LANCZOS)
    icon_1024.convert("RGB").save("assets/icons/app_icon.png", format="PNG", quality=100)

    # 2. Android Adaptive Icon Background
    bg_1024 = bg_img.resize((1024, 1024), Image.Resampling.LANCZOS)
    bg_1024.convert("RGB").save("assets/icons/app_icon_background.png", format="PNG", quality=100)

    # 3. Android Adaptive Icon Foreground
    # For Android adaptive icon, ensure foreground stays comfortably within the 66% circle safe area
    fg_canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg_canvas = Image.alpha_composite(fg_canvas, glow_medium)
    fg_canvas = Image.alpha_composite(fg_canvas, glow_crisp)
    fg_canvas = Image.alpha_composite(fg_canvas, emblem)
    
    target_scale = 0.65
    fg_w = int(S * target_scale)
    fg_h = int(S * target_scale)
    fg_resized = fg_canvas.resize((fg_w, fg_h), Image.Resampling.LANCZOS)
    
    fg_scaled = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pos_x = (S - fg_w) // 2
    pos_y = (S - fg_h) // 2
    fg_scaled.paste(fg_resized, (pos_x, pos_y), fg_resized)
    
    fg_1024 = fg_scaled.resize((1024, 1024), Image.Resampling.LANCZOS)
    fg_1024.save("assets/icons/app_icon_foreground.png", format="PNG")

    # 4. Transparent High-Res Logo for Splash & UI
    logo_trans = emblem.resize((1024, 1024), Image.Resampling.LANCZOS)
    logo_trans.save("assets/icons/logo_transparent.png", format="PNG")

    print("[SUCCESS] Master icon generated with automatic mathematical centering!")

if __name__ == "__main__":
    make_icon()
