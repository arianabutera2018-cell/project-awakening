"""
Prévia do cenário no Blender (NÃO é o visual real do Roblox).

Lê world/Temple.model.json e renderiza 4 imagens só para conferir posições, tamanhos e cores.
Uso: blender -b --python tools/previa_blender.py -- world/Temple.model.json docs/previa-blender
"""
import bpy, json, sys, math
from mathutils import Matrix

args = sys.argv[sys.argv.index("--") + 1:]
src, outdir = args[0], args[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))  # Roblox (Y up) -> Blender (Z up)
RCYL = Matrix(((0, 0, 1, 0), (0, 1, 0, 0), (-1, 0, 0, 0), (0, 0, 0, 1)))  # Blender Z-axis cylinder -> X axis

meshes = {}
bpy.ops.mesh.primitive_cube_add(size=2); meshes["Block"] = bpy.context.object.data; bpy.data.objects.remove(bpy.context.object)
bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=24, ring_count=12); meshes["Ball"] = bpy.context.object.data; bpy.data.objects.remove(bpy.context.object)
bpy.ops.mesh.primitive_cylinder_add(radius=1, depth=2, vertices=24); meshes["Cylinder"] = bpy.context.object.data; bpy.data.objects.remove(bpy.context.object)
for m in meshes.values():
    for p in m.polygons:
        p.use_smooth = False

mats = {}
def material(rgb, kind, transparency):
    key = (tuple(round(c, 3) for c in rgb), kind, round(transparency, 2))
    if key in mats:
        return mats[key]
    mat = bpy.data.materials.new("m%d" % len(mats))
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = 0.35 if kind == "Metal" else 0.8
    bsdf.inputs["Metallic"].default_value = 0.6 if kind == "Metal" else 0
    if kind == "Neon":
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Strength"].default_value = 3.0
    if transparency > 0:
        bsdf.inputs["Alpha"].default_value = 1 - transparency
        mat.blend_method = "BLEND"
    mats[key] = mat
    return mat

def walk(node):
    props = node.get("Properties", {})
    cls = node.get("ClassName")
    if cls in ("Part", "SpawnLocation") and props.get("Transparency", 0) < 0.99:
        size = props["Size"]
        cf = props["CFrame"]["CFrame"]
        (r, pos) = cf["orientation"], cf["position"]
        M = Matrix(((r[0][0], r[0][1], r[0][2], pos[0]), (r[1][0], r[1][1], r[1][2], pos[1]),
                    (r[2][0], r[2][1], r[2][2], pos[2]), (0, 0, 0, 1)))
        S = Matrix.Diagonal((size[0] / 2, size[1] / 2, size[2] / 2, 1))
        shape = props.get("Shape", "Block")
        obj = bpy.data.objects.new(node.get("Name", "Part"), meshes[shape])
        obj.matrix_world = C @ M @ S @ (RCYL if shape == "Cylinder" else Matrix.Identity(4))
        rgb = props["Color"]["Color3"]
        mat = material(rgb, props.get("Material"), props.get("Transparency", 0))
        scene.collection.objects.link(obj)
        if len(obj.material_slots) == 0:
            obj.data.materials.append(None)
        obj.material_slots[0].link = "OBJECT"
        obj.material_slots[0].material = mat
        for child in node.get("Children", []):
            if child.get("ClassName") == "PointLight":
                lp = child["Properties"]
                ld = bpy.data.lights.new("L", "POINT")
                ld.color = lp["Color"]["Color3"]
                ld.energy = lp["Brightness"] * 900
                ld.shadow_soft_size = 0.5
                lo = bpy.data.objects.new("Light", ld)
                lo.location = (C @ M).to_translation()
                scene.collection.objects.link(lo)
    for child in node.get("Children", []):
        walk(child)

walk(json.load(open(src)))

# Sun + sky approximating the Lighting settings
sun = bpy.data.lights.new("Sun", "SUN"); sun.energy = 3.2; sun.color = (1, 0.93, 0.85)
so = bpy.data.objects.new("Sun", sun); so.rotation_euler = (math.radians(50), 0, math.radians(30)); scene.collection.objects.link(so)
world = bpy.data.worlds.new("W"); scene.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.62, 0.66, 0.95, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9

scene.render.engine = "BLENDER_EEVEE"
scene.eevee.use_bloom = True
scene.eevee.use_gtao = True
scene.eevee.taa_render_samples = 32
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast"
scene.render.resolution_x, scene.render.resolution_y = 1280, 720

def shot(name, eye, target, lens=24):
    cam = bpy.data.cameras.new(name); cam.lens = lens; cam.clip_end = 1000
    co = bpy.data.objects.new(name, cam); scene.collection.objects.link(co)
    e = C @ Matrix.Translation(eye); t = C @ Matrix.Translation(target)
    co.location = e.to_translation()
    direction = t.to_translation() - e.to_translation()
    co.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = co
    scene.render.filepath = f"{outdir}/{name}.png"
    bpy.ops.render.render(write_still=True)
    print("SHOT", scene.render.filepath)

shot("01_entrada", (14, 9, 32), (0, 6, -10))
shot("02_corredor", (0, 7.5, -16), (0, 6, -80), 20)
shot("03_ponte", (0, 7, -50), (0, 4, -90), 20)
shot("04_salao_final", (0, 9, -114), (0, 7, -140), 18)
