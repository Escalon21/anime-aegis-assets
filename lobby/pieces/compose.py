import bpy, math, sys
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
# (file, plaza x, plaza y, rotation deg about Z so front(-Y) faces the target)
LAYOUT = [("AAT_Border.glb",0,0,0), ("AAT_PlazaGround.glb",0,0,0), ("AAT_AegisCore.glb",0,-22,0),
          ("AAT_SpawnPad.glb",0,-72,180), ("AAT_UnitHangar.glb",-80,-9,90), ("AAT_QuestBond.glb",80,-9,-90),
          ("AAT_TopWaves.glb",72,62,0), ("AAT_AegisShop.glb",-70,60,0)]
for f,x,y,r in LAYOUT:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=f)
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    for o in roots:
        o.rotation_mode = 'XYZ'
        o.rotation_euler.z += math.radians(r)
        o.location = Vector((x, y, 0)) + o.location
# summon hall from its blend (front -Y, centre 62 north), linked in as objects
with bpy.data.libraries.load("../hall/SummonHall.blend") as (src, dst):
    dst.objects = [n for n in src.objects]
for o in dst.objects:
    if o is None: continue
    sc.collection.objects.link(o)
    o.location.y += 62; o.location.z += 0.08
for o in bpy.data.objects:
    if o.name.startswith("MK_"): o.hide_render = True
glow = {"bio":4, "magenta":4, "amber":3, "lantern":2.5}
for m in bpy.data.materials:
    if m.use_nodes and m.name.split(".")[0] in glow:
        b = m.node_tree.nodes.get("Principled BSDF")
        if b:
            b.inputs["Emission Color"].default_value = b.inputs["Base Color"].default_value
            b.inputs["Emission Strength"].default_value = glow[m.name.split(".")[0]]
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 20; sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = 1280, 720
sc.view_settings.view_transform = "AgX"
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.03, 0.035, 0.08, 1)
d = bpy.data.lights.new("sun", "SUN"); d.energy = 1.4; d.color = (0.75, 0.8, 1)
so = bpy.data.objects.new("sun", d); so.rotation_euler = (math.radians(50), 0, math.radians(-30)); sc.collection.objects.link(so)
def cam(name, loc, target, lens, ortho=None):
    c = bpy.data.cameras.new(name); c.lens = lens; c.clip_end = 3000
    if ortho: c.type = 'ORTHO'; c.ortho_scale = ortho
    o = bpy.data.objects.new(name, c); o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(o); return o
shots = [("top", cam("top", (0, -2, 400), (0, 0, 0), 50, ortho=230)),
         ("persp", cam("persp", (-120, -190, 110), (0, -5, 5), 24)),
         ("walk", cam("walk", (0, -62, 5.5), (0, 40, 12), 16))]
for n, c in shots:
    sc.camera = c; sc.render.filepath = f"//lobby_{n}.png"; bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath="LobbyComposite.blend")
print("rendered")
