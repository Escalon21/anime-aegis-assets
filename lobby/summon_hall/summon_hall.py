"""
Anime Aegis TDS - Summon Hall (lobby piece 1)
=============================================
Run in Blender 4.x:  Scripting tab > Open > summon_hall.py > Run Script.
It clears the scene and builds the hall from scratch, then (optionally) exports FBX.

Scale: 1 Blender unit = 1 Roblox stud. When importing into Roblox Studio
(Avatar/3D Importer), set the file's unit / scale to "Stud" so nothing is resized.

Style: an alien ship that landed in Neo Tokyo. Pearl-white ceramic hull, graphite
armour, lavender iridescent metal, and a few bio-teal glows, plus street-level
Neo Tokyo clutter (hanging signs, paper lanterns, vending machines, AC units,
cables, a torii-style gate).

NAMING CONTRACT (the Roblox script SummonHallService relies on it):
  <Name>__<style>   style = pearl, graphite, lavender, bio, magenta, amber,
                    glass, screen, floor, cable, lantern
  Wall_* / Floor_* / Roof_*   solid, keep collisions (each one is a simple convex block)
  DoorL / DoorR               sliding door panels
  Spin_*                      rings that rotate
  MK_*                        invisible markers the script reads:
      MK_Center, MK_Front      hall centre + a point in front of the door (sets "forward")
      MK_Screen                banner screen surface (big screen on the facade)
      MK_Summoner              where the summoner character stands (press to summon)
      MK_ModelSpotL/R          two more character spots inside
      MK_Sign1..3              vertical sign text panels
Everything else is decoration and gets joined per style to keep the part count low.
"""
import bpy, bmesh, math
from mathutils import Vector, Matrix, Euler

EXPORT_FBX = True          # set False if you only want to look at it in Blender
FBX_PATH = "//SummonHall.fbx"  # next to the .blend (or the script's folder when unsaved)

# ------------------------------------------------------------------ palette
STYLES = {
    #            base colour (sRGB 0-255)   emission strength
    "pearl":    ((228, 231, 239), 0),
    "graphite": ((38, 42, 53), 0),
    "lavender": ((142, 134, 201), 0),
    "bio":      ((56, 242, 192), 4),
    "magenta":  ((255, 63, 164), 4),
    "amber":    ((255, 178, 63), 3),
    "lantern":  ((232, 65, 58), 2.5),
    "glass":    ((159, 216, 255), 0.6),
    "screen":   ((10, 14, 28), 0),
    "floor":    ((27, 31, 43), 0),
    "cable":    ((17, 19, 24), 0),
    "marker":   ((255, 0, 200), 0),
}

def srgb(c):
    def f(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return (f(c[0]), f(c[1]), f(c[2]), 1)

MATS = {}
def mat(style):
    if style in MATS:
        return MATS[style]
    col, emit = STYLES[style]
    m = bpy.data.materials.new(style)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = srgb(col)
    b.inputs["Roughness"].default_value = 0.35 if style in ("pearl", "lavender", "graphite") else 0.6
    b.inputs["Metallic"].default_value = 0.6 if style in ("lavender", "graphite") else 0.0
    if emit:
        b.inputs["Emission Color"].default_value = srgb(col)
        b.inputs["Emission Strength"].default_value = emit
    if style == "glass":
        b.inputs["Alpha"].default_value = 0.45
        m.blend_method = "BLEND"
    if style == "marker":
        b.inputs["Alpha"].default_value = 0.25
        m.blend_method = "BLEND"
    m.diffuse_color = srgb(col)
    MATS[style] = m
    return m

# ------------------------------------------------------------------ scene reset
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
root = bpy.data.collections.new("SummonHall")
scene.collection.children.link(root)
GROUPS = {}
def group(name):
    if name not in GROUPS:
        c = bpy.data.collections.new(name)
        root.children.link(c)
        GROUPS[name] = c
    return GROUPS[name]

# ------------------------------------------------------------------ mesh helpers
def finish(bm, name, style, grp, loc=(0, 0, 0), rot=(0, 0, 0)):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat(style))
    ob = bpy.data.objects.new(f"{name}__{style}" if not name.startswith("MK_") else name, me)
    ob.location = Vector(loc)
    ob.rotation_euler = Euler([math.radians(a) for a in rot])
    group(grp).objects.link(ob)
    if name.startswith("MK_"):
        ob.hide_render = True
    return ob

def box(name, size, loc, style, grp="Decor", rot=(0, 0, 0), bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=min(bevel, min(size) * 0.45), segments=1, affect="EDGES")
    return finish(bm, name, style, grp, loc, rot)

def cyl(name, r, depth, loc, style, grp="Decor", rot=(0, 0, 0), seg=16, r2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    return finish(bm, name, style, grp, loc, rot)

def cut_below(bm, z=0.0):
    """delete everything under z and cap the hole (turns a sphere/ring into a dome/arch)"""
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, z), plane_no=(0, 0, 1),
                           clear_inner=True)
    edges = [e for e in bm.edges if e.is_boundary]
    if edges:
        bmesh.ops.holes_fill(bm, edges=edges, sides=0)

def sphere(name, r, loc, style, grp="Decor", scale=(1, 1, 1), seg=12, rings=8, dome=False):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    bmesh.ops.scale(bm, vec=Vector(scale), verts=bm.verts)
    if dome:
        cut_below(bm)
    return finish(bm, name, style, grp, loc)

def torus(name, R, r, loc, style, grp="Decor", rot=(0, 0, 0), seg=32, sides=8):
    bm = bmesh.new()
    rings = []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        ring = []
        for j in range(sides):
            b = 2 * math.pi * j / sides
            d = R + r * math.cos(b)
            ring.append(bm.verts.new((d * math.cos(a), d * math.sin(a), r * math.sin(b))))
        rings.append(ring)
    for i in range(seg):
        for j in range(sides):
            a, b = rings[i], rings[(i + 1) % seg]
            bm.faces.new((a[j], b[j], b[(j + 1) % sides], a[(j + 1) % sides]))
    return finish(bm, name, style, grp, loc, rot)

def hull(name, pts, style, grp="Decor"):
    bm = bmesh.new()
    for p in pts:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    return finish(bm, name, style, grp)

def slab(name, a, b, width, thick, style, grp="Decor"):
    """thin plate from point a to b (a straight 'rod' with a rectangular section)"""
    a, b = Vector(a), Vector(b)
    d = b - a
    L = d.length
    ob = box(name, (width, thick, L), (a + b) / 2, style, grp)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    return ob

def fin(name, base_in, base_out, top, thick, style, grp="Decor"):
    """swept hull fin: a triangle-ish plate with thickness, the alien-ship silhouette"""
    base_in, base_out, top = Vector(base_in), Vector(base_out), Vector(top)
    side = (base_out - base_in).cross(Vector((0, 0, 1)))
    side = side.normalized() * thick / 2 if side.length > 1e-6 else Vector((thick / 2, 0, 0))
    pts = []
    for p in (base_in, base_out, top, base_in + Vector((0, 0, 3))):
        pts += [p + side, p - side]
    return hull(name, pts, style, grp)

# ================================================================== HALL SHELL
W, D, H = 56, 48, 24          # outer footprint (x, y) and wall height
DOOR_W, DOOR_H = 14, 17
FY = -D / 2 + 1               # front wall centre y  (-23)

box("Floor_Main", (W, D, 1), (0, 0, -0.5), "floor", "Shell")
box("Wall_Back", (W, 2, H), (0, D / 2 - 1, H / 2), "pearl", "Shell", bevel=0.4)
box("Wall_L", (2, D - 4, H), (-W / 2 + 1, 0, H / 2), "pearl", "Shell", bevel=0.4)
box("Wall_R", (2, D - 4, H), (W / 2 - 1, 0, H / 2), "pearl", "Shell", bevel=0.4)
side_w = (W - DOOR_W) / 2
box("Wall_FrontL", (side_w, 2, H), (-(DOOR_W / 2 + side_w / 2), FY, H / 2), "pearl", "Shell", bevel=0.4)
box("Wall_FrontR", (side_w, 2, H), ((DOOR_W / 2 + side_w / 2), FY, H / 2), "pearl", "Shell", bevel=0.4)
box("Wall_Lintel", (DOOR_W, 2, H - DOOR_H), (0, FY, DOOR_H + (H - DOOR_H) / 2), "pearl", "Shell")
box("Roof_Main", (W + 2, D + 2, 1.6), (0, 0, H + 0.8), "graphite", "Shell", bevel=0.6)

# armour belt + panel lines (graphite over pearl)
def band(name, z, t, depth, style):
    """a strip running around the OUTSIDE of the walls (split at the door)"""
    o = depth / 2
    box(f"{name}B", (W + 2 * depth, depth, t), (0, D / 2 + o, z), style)
    for sx in (-1, 1):
        box(f"{name}S{sx}", (depth, D, t), (sx * (W / 2 + o), 0, z), style)
        box(f"{name}F{sx}", (side_w, depth, t), (sx * (DOOR_W / 2 + side_w / 2), -D / 2 - o, z), style)
for z in (0.9, 8.5, 16.5):
    band(f"Belt{z}", z, 1.8 if z < 1 else 0.35, 0.4, "graphite")
# bio seam at the foot of the hull (the only neon on the walls)
band("BioSeam", 1.9, 0.18, 0.3, "bio")

# ---- alien upper hull: flattened lavender dome with graphite ribs + spires
sphere("Dome", 17, (0, 4, H + 1.6), "lavender", scale=(1, 1, 0.42), seg=16, rings=8, dome=True)
for i in range(3):   # arched ribs over the dome: vertical rings squashed to the dome's shape
    rib = torus(f"DomeRib{i}", 17.25, 0.45, (0, 0, 0), "graphite", seg=32, sides=6)
    rib.data.transform(Matrix.Diagonal((1, 1, 0.42, 1)) @ Matrix.Rotation(math.pi * i / 3, 4, "Z") @ Matrix.Rotation(math.pi / 2, 4, "X"))
    bm = bmesh.new(); bm.from_mesh(rib.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0), plane_no=(0, 0, 1), clear_inner=True)
    bm.to_mesh(rib.data); bm.free()
    rib.location = (0, 4, H + 1.6)
cyl("DomeCap", 4.5, 1.6, (0, 4, H + 8.6), "graphite", seg=12)
cyl("DomeCapGlow", 3.2, 0.5, (0, 4, H + 9.6), "bio", seg=12)
for x in (-9, 9):
    cyl(f"Spire{x}", 0.9, 12, (x, 12, H + 9), "pearl", seg=8, r2=0.1)
    sphere(f"SpireTip{x}", 0.55, (x, 12, H + 15.2), "magenta", seg=8, rings=6)

# ---- swept corner fins (the "landed ship" silhouette)
for sx in (-1, 1):
    fin(f"FinFront{sx}", (sx * 27, -23, 0), (sx * 36, -33, 0), (sx * 27.5, -24, 31), 1.4, "pearl")
    fin(f"FinFrontEdge{sx}", (sx * 27.3, -23.4, 0.2), (sx * 35.4, -32.4, 0.2), (sx * 27.6, -24.2, 30.4), 1.6, "graphite")
    fin(f"FinBack{sx}", (sx * 27, 23, 0), (sx * 34, 31, 0), (sx * 27.5, 24, 26), 1.4, "pearl")
    # hull vents ("gills") on the side walls
    for k in range(5):
        box(f"Gill{sx}_{k}", (0.6, 5, 0.5), (sx * 28.3, -6 + k * 3.2 - 8, 12), "graphite", rot=(0, 0, 0))
        box(f"GillB{sx}_{k}", (0.6, 2.4, 0.9), (sx * 28.3, -14 + k * 3.2 + 1.6, 12.8), "graphite", rot=(35, 0, 0))

# ---- door frame + sliding door panels
box("DoorPostL", (1.6, 3.2, DOOR_H + 1.6), (-(DOOR_W / 2 + 0.8), FY - 0.4, (DOOR_H + 1.6) / 2), "graphite", bevel=0.2)
box("DoorPostR", (1.6, 3.2, DOOR_H + 1.6), ((DOOR_W / 2 + 0.8), FY - 0.4, (DOOR_H + 1.6) / 2), "graphite", bevel=0.2)
box("DoorHead", (DOOR_W + 3.2, 3.2, 1.6), (0, FY - 0.4, DOOR_H + 0.8), "graphite", bevel=0.2)
box("DoorGlowL", (0.2, 0.2, DOOR_H), (-(DOOR_W / 2) + 0.1, FY - 2.05, DOOR_H / 2), "bio")
box("DoorGlowR", (0.2, 0.2, DOOR_H), ((DOOR_W / 2) - 0.1, FY - 2.05, DOOR_H / 2), "bio")
box("DoorL", (DOOR_W / 2, 0.8, DOOR_H), (-DOOR_W / 4, FY, DOOR_H / 2), "pearl", "Door", bevel=0.15)
box("DoorR", (DOOR_W / 2, 0.8, DOOR_H), (DOOR_W / 4, FY, DOOR_H / 2), "pearl", "Door", bevel=0.15)
# door trim (joins into Door group, moves with the doors because the script moves DoorL/R only;
# keep trims as part of the door objects by making them children-free: we draw the seam on the panels)
box("DoorSeamL", (0.3, 0.9, DOOR_H - 2), (-0.25, FY - 0.05, DOOR_H / 2), "graphite", "DoorTrimL")
box("DoorSeamR", (0.3, 0.9, DOOR_H - 2), (0.25, FY - 0.05, DOOR_H / 2), "graphite", "DoorTrimR")
box("DoorBandL", (DOOR_W / 2 - 0.6, 0.9, 0.5), (-DOOR_W / 4, FY - 0.05, 10), "lavender", "DoorTrimL")
box("DoorBandR", (DOOR_W / 2 - 0.6, 0.9, 0.5), (DOOR_W / 4, FY - 0.05, 10), "lavender", "DoorTrimR")

# ---- the big banner screen on the facade (above the door, stands proud of the wall)
SCR_W, SCR_H, SCR_Z = 34, 15, 28.5
SY = FY - 2.2
pts = []
for (x, z) in [(-19, SCR_Z - 9.5), (19, SCR_Z - 9.5), (21.5, SCR_Z - 6), (21.5, SCR_Z + 6), (18, SCR_Z + 10.5),
               (-18, SCR_Z + 10.5), (-21.5, SCR_Z + 6), (-21.5, SCR_Z - 6)]:
    pts += [(x, SY + 0.8, z), (x, SY - 0.8, z)]
hull("ScreenFrame", pts, "pearl")
box("ScreenBack", (SCR_W + 1.2, 1.4, SCR_H + 1.2), (0, SY - 0.9, SCR_Z), "graphite")
box("Screen", (SCR_W, 0.2, SCR_H), (0, SY - 1.65, SCR_Z), "screen")
box("MK_Screen", (SCR_W, 0.1, SCR_H), (0, SY - 1.8, SCR_Z), "marker", "Markers")
box("ScreenUnderGlow", (SCR_W - 4, 0.3, 0.25), (0, SY - 1.2, SCR_Z - 8.9), "bio")
for sx in (-1, 1):   # swept "antenna" fins on the crown
    fin(f"CrownFin{sx}", (sx * 16, SY, SCR_Z + 10), (sx * 23, SY + 4, SCR_Z + 9), (sx * 18.5, SY + 1, SCR_Z + 17), 0.9, "lavender")
    box(f"CrownStrut{sx}", (1.2, 6, 1.2), (sx * 12, SY + 3, SCR_Z + 10.6), "graphite")

# ================================================================== INTERIOR
# summon platform + floating rings + light column
cyl("Platform", 9, 0.4, (0, -2, 0.2), "pearl", seg=24)
torus("PlatformGlow", 9.3, 0.18, (0, -2, 0.42), "bio", seg=32, sides=6)
cyl("PlatformInner", 5.5, 0.12, (0, -2, 0.46), "graphite", seg=24)
torus("Spin_RingA", 7, 0.45, (0, -2, 13), "lavender", "Spin_RingA", rot=(14, 0, 0), seg=40)
torus("Spin_RingB", 5, 0.3, (0, -2, 13), "bio", "Spin_RingB", rot=(-22, 10, 0), seg=32)
cyl("LightColumn", 0.9, H - 0.6, (0, -2, (H - 0.6) / 2 + 0.3), "glass", seg=12)
cyl("CeilingEmitter", 3, 1, (0, -2, H - 0.8), "graphite", seg=12)
cyl("CeilingEmitterGlow", 2, 0.2, (0, -2, H - 1.35), "bio", seg=12)

# summoner dais at the back (character stands on MK_Summoner)
cyl("Dais", 4.6, 1.2, (0, 15, 0.6), "graphite", seg=20)
torus("DaisGlow", 4.7, 0.14, (0, 15, 1.22), "bio", seg=28, sides=6)
cyl("DaisTop", 4.0, 0.1, (0, 15, 1.25), "pearl", seg=20)
box("MK_Summoner", (3, 3, 6), (0, 15, 1.3 + 3), "marker", "Markers")
# alien "iris" wall behind the summoner
cyl("Iris", 7.5, 0.6, (0, D / 2 - 2.3, 11), "graphite", rot=(90, 0, 0), seg=24)
cyl("IrisGlass", 6, 0.3, (0, D / 2 - 2.7, 11), "glass", rot=(90, 0, 0), seg=24)
for i in range(8):
    a = 2 * math.pi * i / 8
    slab(f"IrisBlade{i}", (math.cos(a) * 2.2, D / 2 - 2.9, 11 + math.sin(a) * 2.2),
         (math.cos(a) * 6.8, D / 2 - 2.9, 11 + math.sin(a) * 6.8), 1.1, 0.3, "lavender")

# two character spots (alcoves left / right)
for sx, tag in ((-1, "L"), (1, "R")):
    x = sx * 16
    cyl(f"Pedestal{tag}", 3.2, 1, (x, 8, 0.5), "graphite", seg=18)
    torus(f"PedestalGlow{tag}", 3.3, 0.12, (x, 8, 1.02), "bio", seg=24, sides=6)
    box(f"MK_ModelSpot{tag}", (3, 3, 6), (x, 8, 1.05 + 3), "marker", "Markers")
    # alcove arch behind each spot
    box(f"AlcoveBack{tag}", (9, 1, 14), (x, 12.5, 7), "lavender", bevel=0.3)
    box(f"AlcoveTop{tag}", (10, 3, 1.2), (x, 11.5, 14.4), "graphite", bevel=0.2)
    for ex in (-4.6, 4.6):
        box(f"AlcoveCol{tag}{ex}", (1, 3, 14), (x + ex, 11.5, 7), "graphite", bevel=0.2)
    box(f"AlcoveGlow{tag}", (8, 0.2, 0.25), (x, 12.0, 13.6), "bio")

# ribs on the inner walls + ceiling (alien ship skeleton)
for i, y in enumerate(range(-18, 21, 7)):
    for sx in (-1, 1):
        box(f"RibWall{i}{sx}", (1.2, 1.4, H - 1), (sx * (W / 2 - 2.6), y, (H - 1) / 2), "lavender", bevel=0.2)
    box(f"RibCeil{i}", (W - 4, 1.4, 1.2), (0, y, H - 1), "lavender", bevel=0.2)
for y in (-12, 6):
    box(f"CeilPanel{y}", (30, 3, 0.2), (0, y, H - 1.7), "glass")
# interior floor inlay lines
for sx in (-1, 1):
    box(f"FloorLine{sx}", (0.25, 36, 0.06), (sx * 11, -2, 0.03), "bio")

# ================================================================== NEO TOKYO STREET
box("Floor_Plaza", (84, 44, 0.4), (0, -46, -0.2), "floor", "Shell")
for x in (-30, -10, 10, 30):
    box(f"PlazaLine{x}", (0.25, 40, 0.05), (x, -46, 0.03), "bio")
box("Crosswalk", (16, 8, 0.05), (0, -32, 0.03), "pearl")
for i in range(7):
    box(f"CrossStripe{i}", (1.1, 8, 0.07), (-6.6 + i * 2.2, -32, 0.04), "floor")

# torii-style gate at the plaza entrance
for sx in (-1, 1):
    cyl(f"GatePillar{sx}", 1.1, 20, (sx * 12, -58, 10), "graphite", seg=12)
    cyl(f"GateFoot{sx}", 1.6, 1.2, (sx * 12, -58, 0.6), "pearl", seg=12)
box("GateBeamTop", (34, 2.6, 1.6), (0, -58, 20.6), "graphite", bevel=0.3)
box("GateBeamTopGlow", (34.2, 2.7, 0.25), (0, -58, 21.5), "magenta")
box("GateBeamLow", (27, 1.6, 1.2), (0, -58, 17.2), "graphite", bevel=0.2)
box("GatePlaque", (5, 0.8, 3.4), (0, -58, 18.9), "pearl", bevel=0.2)
box("MK_Sign3", (4.4, 0.1, 2.8), (0, -58.5, 18.9), "marker", "Markers")

# vertical hanging signs on the facade
for sx, tag, style in ((-1, "1", "magenta"), (1, "2", "amber")):
    x = sx * 24
    box(f"SignBoard{tag}", (3.6, 1, 15), (x, FY - 3.2, 14.5), "graphite", bevel=0.2)
    box(f"SignFace{tag}", (3.0, 0.15, 14.2), (x, FY - 3.75, 14.5), style)
    box(f"MK_Sign{tag}", (2.8, 0.1, 13.6), (x, FY - 3.9, 14.5), "marker", "Markers")
    for z in (8, 21):
        box(f"SignArm{tag}{z}", (0.4, 2.4, 0.4), (x, FY - 1.8, z), "graphite")

# lantern line: two poles, a sagging cable, paper lanterns
POLE_Y = -38
for sx in (-1, 1):
    cyl(f"LanternPole{sx}", 0.45, 15, (sx * 24, POLE_Y, 7.5), "graphite", seg=8)
    box(f"LanternPoleCap{sx}", (1.4, 1.4, 0.6), (sx * 24, POLE_Y, 15.1), "pearl")
N = 12
prev = None
for i in range(N + 1):
    t = i / N
    x = -24 + 48 * t
    z = 14.6 - 3.2 * math.sin(math.pi * t)
    p = (x, POLE_Y, z)
    if prev:
        slab(f"Cable{i}", prev, p, 0.12, 0.12, "cable")
    if 0 < i < N:
        cyl(f"Lantern{i}", 0.85, 1.7, (x, POLE_Y, z - 1.5), "lantern" if i % 3 else "amber", seg=10)
        cyl(f"LanternTop{i}", 0.5, 0.25, (x, POLE_Y, z - 0.55), "graphite", seg=8)
        cyl(f"LanternBot{i}", 0.5, 0.25, (x, POLE_Y, z - 2.45), "graphite", seg=8)
    prev = p
# cables from the roof edge to the poles
for sx in (-1, 1):
    slab(f"RoofCable{sx}", (sx * 26, -24, H), (sx * 24, POLE_Y, 14.8), 0.1, 0.1, "cable")

# vending machines (left of the door)
for i, x in enumerate((-12.5, -16)):
    box(f"Vend{i}", (3.2, 2.4, 6.6), (x, FY - 2.4, 3.3), "pearl", bevel=0.15)
    box(f"VendGlass{i}", (2.4, 0.15, 3.4), (x, FY - 3.65, 4.1), "glass")
    box(f"VendStrip{i}", (2.6, 0.15, 0.3), (x, FY - 3.65, 6.2), "bio" if i else "magenta")
    box(f"VendSlot{i}", (1.6, 0.2, 0.7), (x, FY - 3.65, 1.2), "graphite")
# AC units + pipes on the side walls
for sx in (-1, 1):
    for k, (y, z) in enumerate(((-12, 7), (-2, 15), (10, 7), (16, 18))):
        box(f"AC{sx}{k}", (1.8, 3, 2.4), (sx * (W / 2 + 0.9), y, z), "pearl", bevel=0.1)
        cyl(f"ACFan{sx}{k}", 0.9, 0.2, (sx * (W / 2 + 1.85), y, z), "graphite", rot=(0, 90, 0), seg=12)
    for y in (-20, 21):
        cyl(f"Pipe{sx}{y}", 0.45, H, (sx * (W / 2 + 0.6), y, H / 2), "graphite", seg=8)
# right of the door: stacked crates + a small holo kiosk
for i, (x, z) in enumerate(((13, 1), (15.5, 1), (14.2, 3))):
    box(f"Crate{i}", (2.2, 2.2, 2), (x, FY - 2.6, z), "graphite" if i != 2 else "lavender", bevel=0.15)
cyl("Kiosk", 0.9, 4, (18, FY - 3, 2), "pearl", seg=10)
box("KioskHolo", (2.4, 0.1, 1.6), (18, FY - 3, 5), "glass")
# bollards with bio caps along the approach
for x in (-9, 9):
    for y in (-28, -34, -40, -46, -52):
        cyl(f"Bollard{x}{y}", 0.45, 1.6, (x, y, 0.8), "graphite", seg=8)
        cyl(f"BollardCap{x}{y}", 0.5, 0.2, (x, y, 1.7), "bio", seg=8)
# bio pods along the hull base (alien organic touch)
for sx in (-1, 1):
    for y in (-16, -6, 4, 14):
        sphere(f"Pod{sx}{y}", 0.9, (sx * (W / 2 + 0.3), y, 3.2), "bio", scale=(0.7, 1, 1.3), seg=8, rings=6)

# markers for direction
box("MK_Center", (1, 1, 1), (0, 0, 1), "marker", "Markers")
box("MK_Front", (1, 1, 1), (0, -40, 1), "marker", "Markers")

# ================================================================== join decor per style
KEEP_SEPARATE = ("Wall_", "Floor_", "Roof_", "DoorL", "DoorR", "Spin_", "MK_")
def join(objs, name):
    if len(objs) == 1:
        objs[0].name = name
        return objs[0]
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs):
        bpy.ops.object.join()
    objs[0].name = name
    return objs[0]

# door trims become part of their door panel so they slide with it
for side in ("L", "R"):
    door = bpy.data.objects[f"Door{side}__pearl"]
    trims = list(GROUPS[f"DoorTrim{side}"].objects)
    # join keeps the active object's material slots and appends the others
    with bpy.context.temp_override(active_object=door, selected_editable_objects=[door] + trims, selected_objects=[door] + trims):
        bpy.ops.object.join()

buckets = {}
for ob in list(GROUPS["Decor"].objects):
    style = ob.name.split("__")[-1].split(".")[0]
    buckets.setdefault(style, []).append(ob)
for style, objs in buckets.items():
    join(objs, f"Deco_{style}__{style}")

# apply transforms so the exported pieces have clean pivots
for ob in root.all_objects:
    ob.select_set(False)
bpy.context.view_layer.update()

counts = {g: len(c.objects) for g, c in GROUPS.items()}
print("Summon Hall built:", counts, "objects total:", len(list(root.all_objects)))

if EXPORT_FBX:
    path = bpy.path.abspath(FBX_PATH) if bpy.data.filepath else FBX_PATH.replace("//", "")
    for ob in root.all_objects:
        ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True,
                             global_scale=1.0, apply_scale_options="FBX_SCALE_ALL",
                             axis_forward="-Z", axis_up="Y", use_mesh_modifiers=True,
                             mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)
    print("Exported", path)
