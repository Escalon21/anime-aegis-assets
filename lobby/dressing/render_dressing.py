import bpy, math, os
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "PlazaDressing.blend"))
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = 1280, 720
sc.view_settings.view_transform = "AgX"
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.03, 0.035, 0.08, 1)
# ground + building stand-ins (grey blocks where the real pieces are)
def block(loc, size, col):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object; o.scale = (size[0]/2, size[1]/2, size[2]/2)
    m = bpy.data.materials.new("g"); m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = col
    o.data.materials.append(m)
block((0, 19*2, -0.5), (500, 450, 1), (0.02, 0.022, 0.03, 1))
for (x, z, sx, sz, h) in [(0, -12, 62, 62, 20), (0, 88, 56, 56, 6), (0, -180, 105, 124, 50), (-160, -38, 60, 51, 28), (160, -38, 50, 52, 30), (144, -180, 22, 26, 60), (-140, -176, 37, 32, 40)]:
    block((x, -z, h/2), (sx, sz, h), (0.12, 0.12, 0.16, 1))
sun = bpy.data.lights.new("s", "SUN"); sun.energy = 0.6
so = bpy.data.objects.new("s", sun); so.rotation_euler = (math.radians(50), 0, math.radians(30)); sc.collection.objects.link(so)
def cam(loc, target, lens):
    c = bpy.data.cameras.new("c"); c.lens = lens; c.clip_end = 3000
    o = bpy.data.objects.new("c", c); o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(o); return o
for name, loc, tgt, lens in [("top", (0, -330, 300), (0, 20, 0), 24), ("walk", (-14, -150, 9), (0, -40, 5), 22)]:
    sc.camera = cam(loc, tgt, lens)
    sc.render.filepath = os.path.join(HERE, f"preview_{name}.png")
    bpy.ops.render.render(write_still=True)
print("done")
