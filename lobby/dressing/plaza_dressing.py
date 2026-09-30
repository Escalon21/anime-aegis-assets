"""
Anime Aegis TDS - Plaza Dressing (lobby piece: fills the bigger plaza)
=====================================================================
Glowing walkways from the spawn to every building, street lamps with lantern strings,
neon sakura trees in planters, benches, two ramen/snack stalls, vending machine corners,
holo billboards and hovering alien drones. Same palette + naming contract as the Summon Hall.

Built at FINAL size in lobby coordinates: origin = plaza centre, 1 unit = 1 stud.
Roblox (x, z) -> Blender (x, -z), height = Blender z. SummonHallService places it with
MK_Center/MK_Front (PIECE_SPOTS "PlazaDressing", Fixed = no extra scaling).
Nothing here is solid: players walk on the plaza floor underneath.
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Matrix, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, "helpers.py")).read().replace('"SummonHall"', '"PlazaDressing"')
exec(src)

def R(x, z, h=0.0):
    """Roblox lobby coords (x, z, height) -> Blender location"""
    return (x, -z, h)

# ------------------------------------------------------------------ layout (Roblox lobby coords after LOBBY_SPREAD)
SPAWN, CORE = (0, 88), (0, -12)
PATHS = [  # (from, to, width)
    ((0, 58), (0, 22), 12),          # spawn -> core
    ((0, -46), (0, -116), 12),       # core -> summon hall door
    ((-34, -18), (-126, -38), 10),   # core -> unit hangar
    ((34, -18), (128, -38), 10),     # core -> quest / bonds district
    ((-24, -40), (-134, -152), 9),   # core -> aegis shop
    ((24, -40), (140, -158), 9),     # core -> top waves
]

def V2(p): return Vector((p[0], -p[1], 0))

# ------------------------------------------------------------------ walkways: slab + bio edges + pearl chevrons
def walkway(i, a, b, w):
    A, B = V2(a), V2(b)
    d = (B - A)
    L = d.length
    u = d.normalized()
    n = Vector((-u.y, u.x, 0))
    mid = (A + B) / 2
    ang = math.degrees(math.atan2(u.y, u.x))
    box(f"Path{i}", (L, w, 0.12), mid + Vector((0, 0, 0.06)), "graphite", rot=(0, 0, ang))
    for s in (-1, 1):
        box(f"PathEdge{i}_{s}", (L, 0.3, 0.16), mid + n * s * (w / 2 - 0.15) + Vector((0, 0, 0.08)), "bio", rot=(0, 0, ang))
    k = 0
    t = 7.0
    while t < L - 5:
        p = A + u * t
        for s in (-1, 1):
            box(f"Chev{i}_{k}_{s}", (2.2, 0.35, 0.14), p + n * s * 0.9 - u * 0.6 + Vector((0, 0, 0.1)), "pearl", rot=(0, 0, ang + s * 35))
        k += 1
        t += 14
    return A, B, u, n, L

# ------------------------------------------------------------------ props
def lamp(name, p, face, glow):
    p = Vector(p)
    cyl(f"{name}Base", 0.7, 0.5, p + Vector((0, 0, 0.25)), "graphite", seg=8)
    cyl(f"{name}Pole", 0.22, 9, p + Vector((0, 0, 4.9)), "graphite", seg=8)
    arm_end = p + Vector((face.x * 1.8, face.y * 1.8, 9.3))
    slab(f"{name}Arm", p + Vector((0, 0, 9.2)), arm_end, 0.3, 0.3, "graphite")
    box(f"{name}Head", (1.1, 1.1, 0.5), arm_end - Vector((0, 0, 0.25)), "pearl", bevel=0.12)
    torus(f"{name}Ring", 0.55, 0.1, arm_end - Vector((0, 0, 0.55)), glow, seg=16, sides=6)
    box(f"{name}Tag", (0.12, 0.6, 1.6), p + Vector((0, 0, 6.5)) + face * 0.25, "amber" if glow == "magenta" else "magenta")
    return arm_end

def lantern_string(name, a, b, n=5):
    a, b = Vector(a), Vector(b)
    pts = []
    for i in range(n + 2):
        t = i / (n + 1)
        q = a.lerp(b, t) - Vector((0, 0, math.sin(math.pi * t) * 1.2))
        pts.append(q)
    for i in range(len(pts) - 1):
        slab(f"{name}Wire{i}", pts[i], pts[i + 1], 0.06, 0.06, "cable")
    for i in range(1, n + 1):
        q = pts[i] - Vector((0, 0, 0.55))
        box(f"{name}Lan{i}", (0.55, 0.55, 0.8), q, "lantern", bevel=0.15)

def sakura(name, p, big=1.0):
    p = Vector(p)
    cyl(f"{name}Planter", 3.2 * big, 1.4, p + Vector((0, 0, 0.7)), "pearl", seg=6)
    cyl(f"{name}PlanterRim", 3.35 * big, 0.25, p + Vector((0, 0, 1.45)), "bio", seg=6)
    cyl(f"{name}Soil", 2.9 * big, 0.2, p + Vector((0, 0, 1.45)), "cable", seg=6)
    cyl(f"{name}Trunk", 0.55 * big, 7 * big, p + Vector((0, 0, 1.4 + 3.5 * big)), "graphite", seg=6, r2=0.3 * big)
    top = p + Vector((0, 0, 1.4 + 7 * big))
    blobs = [(0, 0, 1.2, 2.8), (2.2, 0.6, 0.2, 2.1), (-2.0, -0.8, 0.4, 2.2), (0.6, -2.1, 0.1, 1.9), (-0.8, 2.0, 0.6, 1.8), (0, 0, 2.8, 1.7)]
    for i, (x, y, z, r) in enumerate(blobs):
        q = top + Vector((x, y, z)) * big
        if i < 5:
            slab(f"{name}Branch{i}", top - Vector((0, 0, 1.2 * big)), q, 0.3 * big, 0.3 * big, "graphite")
        sphere(f"{name}Bloom{i}", r * big, q, "magenta" if i % 3 else "lavender", seg=10, rings=6)
    for i in range(6):   # falling petals
        a = i * 1.1
        box(f"{name}Petal{i}", (0.25, 0.25, 0.06), top + Vector((math.cos(a) * 3.5, math.sin(a) * 3.5, -2 - i * 0.7)) * 1, "magenta", rot=(30, 20 * i, 45))

def bench(name, p, ang):
    p = Vector(p)
    r = math.radians(ang)
    fwd = Vector((math.cos(r), math.sin(r), 0))
    box(f"{name}Seat", (5, 1.5, 0.35), p + Vector((0, 0, 1.3)), "pearl", rot=(0, 0, ang), bevel=0.1)
    box(f"{name}Back", (5, 0.3, 1.4), p - Vector((-fwd.y, fwd.x, 0)) * 0.7 + Vector((0, 0, 2.2)), "lavender", rot=(0, 0, ang), bevel=0.08)
    for s in (-1, 1):
        box(f"{name}Leg{s}", (0.4, 1.3, 1.1), p + fwd * s * 2.1 + Vector((0, 0, 0.55)), "graphite", rot=(0, 0, ang))
    box(f"{name}Glow", (4.6, 0.12, 0.12), p + Vector((0, 0, 1.08)), "bio", rot=(0, 0, ang))

def stall(name, p, ang, sign_style):
    p = Vector(p)
    r = math.radians(ang)
    f = Vector((math.cos(r), math.sin(r), 0))        # along the counter
    n = Vector((-f.y, f.x, 0))                        # towards customers
    box(f"{name}Counter", (10, 3, 3.4), p + Vector((0, 0, 1.7)), "graphite", rot=(0, 0, ang), bevel=0.15)
    box(f"{name}Top", (10.4, 3.4, 0.3), p + Vector((0, 0, 3.55)), "pearl", rot=(0, 0, ang))
    box(f"{name}Kitchen", (10, 4, 6.5), p - n * 3.6 + Vector((0, 0, 3.25)), "pearl", rot=(0, 0, ang), bevel=0.3)
    for s in (-1, 1):
        box(f"{name}Post{s}", (0.4, 0.4, 8), p + f * s * 4.9 + n * 1.2 + Vector((0, 0, 4)), "graphite", rot=(0, 0, ang))
    roof = p - n * 1.2 + Vector((0, 0, 8.4))
    box(f"{name}Roof", (12, 8.5, 0.5), roof, "lantern", rot=(-8, 0, ang), bevel=0.1)
    box(f"{name}RoofTrim", (12.2, 0.3, 0.3), roof + n * 4.2 - Vector((0, 0, 0.5)), "amber", rot=(0, 0, ang))
    for k in range(5):   # noren curtains
        box(f"{name}Noren{k}", (1.8, 0.08, 1.6), p + f * (-3.8 + k * 1.9) + n * 1.3 + Vector((0, 0, 6.6)), "lantern", rot=(0, 0, ang))
    box(f"{name}Sign", (5, 0.3, 1.6), p - n * 1.0 + Vector((0, 0, 9.9)), "screen", rot=(0, 0, ang))
    box(f"{name}SignGlow", (5.3, 0.2, 1.9), p - n * 1.08 + Vector((0, 0, 9.9)), sign_style, rot=(0, 0, ang))
    for k in range(4):   # stools
        q = p + f * (-3.6 + k * 2.4) + n * 3.0
        cyl(f"{name}Stool{k}", 0.2, 1.8, q + Vector((0, 0, 0.9)), "graphite", seg=6)
        cyl(f"{name}StoolTop{k}", 0.7, 0.3, q + Vector((0, 0, 1.9)), "magenta" if k % 2 else "lavender", seg=10)
    for k in range(3):   # hanging lanterns over the counter
        box(f"{name}Lamp{k}", (0.8, 0.8, 1.1), p + f * (-3 + k * 3) + n * 1.2 + Vector((0, 0, 7.1)), "lantern", bevel=0.2)

def vending(name, p, ang, glow):
    p = Vector(p)
    box(f"{name}Body", (3.2, 2.4, 7), p + Vector((0, 0, 3.5)), "pearl", rot=(0, 0, ang), bevel=0.2)
    r = math.radians(ang)
    n = Vector((-math.sin(r), math.cos(r), 0)) * -1
    box(f"{name}Window", (2.6, 0.2, 3.6), p + n * 1.2 + Vector((0, 0, 4.4)), "glass", rot=(0, 0, ang))
    box(f"{name}Glow", (2.8, 0.15, 0.3), p + n * 1.25 + Vector((0, 0, 6.6)), glow, rot=(0, 0, ang))
    box(f"{name}Slot", (1.6, 0.2, 0.7), p + n * 1.2 + Vector((0, 0, 1.3)), "graphite", rot=(0, 0, ang))

def billboard(name, p, ang, glow):
    p = Vector(p)
    cyl(f"{name}Post", 0.9, 22, p + Vector((0, 0, 11)), "graphite", seg=8)
    box(f"{name}Screen", (9, 0.8, 15), p + Vector((0, 0, 26)), "screen", rot=(0, 0, ang))
    box(f"{name}Frame", (9.8, 0.6, 15.8), p + Vector((0, 0, 26)) + Vector((0, 0, 0)), glow, rot=(0, 0, ang))
    box(f"{name}Cap", (10.4, 1.4, 1.0), p + Vector((0, 0, 34.3)), "pearl", rot=(0, 0, ang), bevel=0.2)
    fin(f"{name}Fin", p + Vector((0, 0, 34.8)), p + Vector((0, 0, 34.8)) + Vector((math.cos(math.radians(ang)) * 5, math.sin(math.radians(ang)) * 5, 0)), p + Vector((0, 0, 40)), 0.5, "lavender")

def drone(name, p, glow):
    p = Vector(p)
    sphere(f"{name}Hull", 5, p, "lavender", scale=(1, 1, 0.28), seg=14, rings=6)
    sphere(f"{name}Dome", 2.2, p + Vector((0, 0, 0.9)), "glass", seg=10, rings=6, dome=True)
    torus(f"{name}Ring", 5.4, 0.25, p, glow, seg=24, sides=6)
    for k in range(3):
        a = k * 2 * math.pi / 3
        sphere(f"{name}Light{k}", 0.45, p + Vector((math.cos(a) * 3.5, math.sin(a) * 3.5, -1.1)), glow, seg=8, rings=4)

# ------------------------------------------------------------------ build
lamp_count = 0
for i, (a, b, w) in enumerate(PATHS):
    A, B, u, n, L = walkway(i, a, b, w)
    ends = {-1: [], 1: []}
    t = 6.0
    k = 0
    while t < L - 3:
        for s in (-1, 1):
            p = A + u * t + n * s * (w / 2 + 1.6)
            glow = "magenta" if (k + (s > 0)) % 2 == 0 else "amber"
            ends[s].append(lamp(f"Lamp{i}_{k}_{s}", p, -n * s, glow))
            lamp_count += 1
        k += 1
        t += 20
    for s in (-1, 1):
        pts = ends[s]
        for j in range(len(pts) - 1):
            lantern_string(f"Str{i}_{s}_{j}", pts[j] + Vector((0, 0, -0.4)), pts[j + 1] + Vector((0, 0, -0.4)), 4)
    # benches between lamps on the long paths
    if L > 60:
        for j, t in enumerate((L * 0.33, L * 0.66)):
            for s in (-1, 1):
                bench(f"Bench{i}_{j}_{s}", A + u * t + n * s * (w / 2 + 3.2), math.degrees(math.atan2(u.y, u.x)))

# promenade ring around the Aegis Core
RING_R, RING_W = 50, 7
segs = 24
for k in range(segs):
    a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
    c = V2(CORE)
    p0 = c + Vector((math.cos(a0), math.sin(a0), 0)) * RING_R
    p1 = c + Vector((math.cos(a1), math.sin(a1), 0)) * RING_R
    mid, d = (p0 + p1) / 2, (p1 - p0)
    ang = math.degrees(math.atan2(d.y, d.x))
    box(f"Ring{k}", (d.length + 0.4, RING_W, 0.12), mid + Vector((0, 0, 0.06)), "graphite", rot=(0, 0, ang))
    for s in (-1, 1):
        q = c + (mid - c).normalized() * (RING_R + s * (RING_W / 2 - 0.15))
        box(f"RingEdge{k}_{s}", (d.length * (RING_R + s * RING_W / 2) / RING_R + 0.3, 0.3, 0.16), q + Vector((0, 0, 0.08)), "lavender" if s < 0 else "bio", rot=(0, 0, ang))

# neon sakura groves (open plaza areas)
for i, (x, z, big) in enumerate([(-62, 40, 1.0), (62, 40, 1.0), (-100, 70, 1.2), (100, 70, 1.2), (-72, -96, 1.0), (72, -96, 1.0),
                                 (-205, 30, 1.3), (205, 30, 1.3), (-200, -110, 1.1), (200, -110, 1.1), (-40, 120, 0.9), (40, 120, 0.9),
                                 (-150, 110, 1.1), (150, 110, 1.1)]):
    sakura(f"Tree{i}", R(x, z), big)

# snack / ramen stalls facing the spawn walkway
stall("StallW", R(-60, 80), 0, "amber")
stall("StallE", R(60, 80), 0, "bio")
# vending corners
for i, (x, z, ang) in enumerate([(-215, 70, 0), (-209, 70, 0), (-203, 70, 0), (215, 70, 0), (209, 70, 0), (203, 70, 0),
                                 (-220, -40, 90), (-220, -34, 90), (220, -40, -90), (220, -34, -90)]):
    vending(f"Vend{i}", R(x, z), ang, ("bio", "magenta", "amber")[i % 3])
# holo billboards
for i, (x, z, ang, g) in enumerate([(-120, 95, 0, "magenta"), (120, 95, 0, "bio"), (-235, -70, 90, "amber"), (235, -70, -90, "magenta")]):
    billboard(f"Board{i}", R(x, z), ang, g)
# hovering alien drones overhead
for i, (x, z, h, g) in enumerate([(-80, 20, 42, "bio"), (90, -60, 55, "magenta"), (-40, -150, 60, "amber"), (160, 60, 48, "bio"), (-170, -20, 52, "magenta")]):
    drone(f"Drone{i}", R(x, z, h), g)

# markers (placement)
box("MK_Center", (1, 1, 1), (0, 0, 0.5), "marker", "Markers")
box("MK_Front", (1, 1, 1), (0, -10, 0.5), "marker", "Markers")   # Roblox +Z (south, towards the spawn)

# ------------------------------------------------------------------ join per style per quadrant (keeps meshes under Roblox's triangle limit)
def join(objs, name):
    if len(objs) == 1:
        objs[0].name = name
        return objs[0]
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs):
        bpy.ops.object.join()
    objs[0].name = name
    return objs[0]

def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)

buckets = {}
for ob in list(GROUPS["Decor"].objects):
    style = ob.name.split("__")[-1].split(".")[0]
    loc = ob.location
    q = (int(loc.x // 160), int(loc.y // 160))
    buckets.setdefault((style, q), []).append(ob)
final = []
for (style, q), objs in buckets.items():
    # split further if a bucket is too heavy
    chunk, count, part = [], 0, 0
    for ob in objs:
        t = tris(ob)
        if chunk and count + t > 9000:
            final.append(join(chunk, f"Deco{q[0]}_{q[1]}_{part}__{style}"))
            chunk, count, part = [], 0, part + 1
        chunk.append(ob)
        count += t
    if chunk:
        final.append(join(chunk, f"Deco{q[0]}_{q[1]}_{part}__{style}"))

bpy.context.view_layer.update()
mx = max(tris(o) for o in final)
print("Plaza dressing:", len(final), "meshes, lamps", lamp_count, "max tris", mx, "total tris", sum(tris(o) for o in final))

out = os.path.join(HERE, "PlazaDressing.fbx")
for ob in root.all_objects:
    ob.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_unit_scale=True, global_scale=1.0, apply_scale_options="FBX_SCALE_ALL",
                         axis_forward="-Z", axis_up="Y", use_mesh_modifiers=True, mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "PlazaDressing.blend"))
print("exported", out)
