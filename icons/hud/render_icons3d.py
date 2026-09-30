"""
HUD icons in 3D: every Material Symbols glyph is extruded + bevelled in Blender and rendered in glossy white
(the game tints it with ImageColor3, so the shading survives), plus a full-colour gem and a gold yen coin.
Output: HudIcons3D.png, 4 columns x 5 rows of 128px cells (8px padding) - same order as ReplicatedStorage.HudIcons.
"""
import bpy, math, os, addon_utils
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
addon_utils.enable("io_curve_svg", default_set=True)
NAMES = ["storefront", "star", "backpack", "receipt_long", "auto_awesome", "link", "rocket_launch", "local_fire_department",
         "military_tech", "leaderboard", "badge", "calendar_month", "settings", "emoji_events", "campaign"]
RES = 224  # rendered per icon, downsampled to 112 in the sheet

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    addon_utils.enable("io_curve_svg", default_set=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48; sc.cycles.use_denoising = True
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.view_settings.view_transform = "Standard"
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.55
    cam = bpy.data.cameras.new("cam"); cam.type = "ORTHO"; cam.ortho_scale = 2.35
    co = bpy.data.objects.new("cam", cam); co.location = (0, 0, 10); sc.collection.objects.link(co); sc.camera = co
    for loc, e, size in [((-3, 4, 6), 900, 3), ((4, -2, 5), 250, 4), ((0, 0, 8), 150, 6)]:
        l = bpy.data.lights.new("l", "AREA"); l.energy = e; l.size = size
        lo = bpy.data.objects.new("l", l); lo.location = loc
        lo.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.collection.objects.link(lo)
    return sc

def material(name, color, rough=0.22, metal=0.0, coat=0.6, emit=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Coat Weight"].default_value = coat
    if emit:
        b.inputs["Emission Color"].default_value = color
        b.inputs["Emission Strength"].default_value = emit
    return m

def tilt(obs):
    for o in obs:
        o.rotation_euler = (math.radians(-14), math.radians(16), 0)

def glyph(name):
    sc = reset()
    before = set(bpy.data.objects)
    bpy.ops.import_curve.svg(filepath=os.path.join(HERE, name + ".svg"))
    curves = [o for o in bpy.data.objects if o not in before and o.type == "CURVE"]
    white = material("white", (0.93, 0.93, 0.95, 1), emit=0.12)
    for c in curves:
        c.data.materials.clear(); c.data.materials.append(white)
    # join into one mesh, centre + normalise to ~1.9 units
    bpy.ops.object.select_all(action="DESELECT")
    for c in curves: c.select_set(True)
    bpy.context.view_layer.objects.active = curves[0]
    bpy.ops.object.convert(target="MESH")
    if len(curves) > 1: bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    ob.location = (0, 0, 0)
    s = 1.9 / max(ob.dimensions.x, ob.dimensions.y)
    ob.scale = (s, s, s)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.mesh.remove_doubles(threshold=0.0005)
    bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode="OBJECT")
    sol = ob.modifiers.new("s", "SOLIDIFY"); sol.thickness = 0.22; sol.offset = 0
    bev = ob.modifiers.new("b", "BEVEL"); bev.width = 0.035; bev.segments = 3; bev.limit_method = "ANGLE"
    tilt([ob])
    return sc

def gem():
    sc = reset()
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.85, radius2=0.5, depth=0.35, location=(0, 0, 0.35))
    top = bpy.context.object
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.85, radius2=0.0, depth=1.0, location=(0, 0, -0.33), rotation=(math.pi, 0, 0))
    bot = bpy.context.object
    body = material("gem", (0.2, 0.14, 0.62, 1), rough=0.12, metal=0.3, coat=1.0, emit=0.05)
    edge = material("edge", (0.22, 0.95, 0.75, 1), rough=0.1, emit=2.5)
    for o in (top, bot):
        o.data.materials.append(body)
        bev = o.modifiers.new("b", "BEVEL"); bev.width = 0.03
        wf = o.modifiers.new("w", "WIREFRAME"); wf.thickness = 0.035; wf.use_replace = False; wf.material_offset = 1
        o.data.materials.append(edge)
        o.rotation_euler = (math.radians(62), 0, math.radians(18))
        o.location = Vector(o.location) * 1.0
    for o in (top, bot):
        o.scale = (1.05, 1.05, 1.05)
    return sc

def coin():
    sc = reset()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.95, depth=0.22)
    c = bpy.context.object
    goldm = material("gold", (1.0, 0.7, 0.25, 1), rough=0.25, metal=1.0, coat=0.3)
    c.data.materials.append(goldm)
    bev = c.modifiers.new("b", "BEVEL"); bev.width = 0.06; bev.segments = 3
    bpy.ops.mesh.primitive_torus_add(major_radius=0.78, minor_radius=0.045, location=(0, 0, 0.11))
    rim = bpy.context.object; rim.data.materials.append(material("rim", (1.0, 0.84, 0.55, 1), rough=0.2, metal=1.0))
    bpy.ops.object.text_add(location=(0, 0, 0.1))
    t = bpy.context.object
    t.data.body = "¥"
    t.data.align_x = "CENTER"; t.data.align_y = "CENTER"
    t.data.size = 1.25; t.data.extrude = 0.05; t.data.bevel_depth = 0.012
    t.data.materials.append(material("yen", (0.55, 0.3, 0.02, 1), rough=0.35, metal=0.8))
    for o in (c, rim, t):
        o.rotation_euler = (math.radians(-22), math.radians(20), 0)
    rim.location = (0, 0, 0.11)
    return sc

def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)

os.makedirs(os.path.join(HERE, "r3d"), exist_ok=True)
import sys
ONLY = os.environ.get("ONLY")
jobs = [(n, lambda n=n: glyph(n)) for n in NAMES] + [("gem", gem), ("coin", coin)]
if ONLY: jobs = [j for j in jobs if j[0] == ONLY]
for n, fn in jobs:
    fn()
    render(os.path.join(HERE, "r3d", n + ".png"))
print("rendered", len(jobs))
