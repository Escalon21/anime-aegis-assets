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
