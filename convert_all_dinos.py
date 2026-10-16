import bpy
import os
import sys
import json

sys.path.append("/tmp")
import io_scene_b3d
io_scene_b3d.register()

dinos_config = {
    "Apatosaurus.blend": "dinos_apatosaurus",
    "Parasaurolophus.blend": "dinos_parasaurolophus",
    "Stegosaurus.blend": "dinos_stegosaurus",
    "Trex.blend": "dinos_trex",
    "Triceratops.blend": "dinos_triceratops",
    "Velociraptor.blend": "dinos_velociraptor",
}

blends_dir = "models/Blends"
models_out_dir = "models"
textures_out_dir = "textures"

os.makedirs(models_out_dir, exist_ok=True)
os.makedirs(textures_out_dir, exist_ok=True)

animation_summary = {}

for blend_file, base_name in sorted(dinos_config.items()):
    print("==================================================")
    print("PROCESSING:", blend_file, "->", base_name)
    blend_path = os.path.join(blends_dir, blend_file)
    bpy.ops.wm.open_mainfile(filepath=blend_path)

    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    mesh_obj = [o for o in bpy.data.objects if o.type == "MESH"][0]

    # --- 1. Generate Texture & UV Map ---
    mat_slots = mesh_obj.material_slots
    num_mats = len(mat_slots)
    if num_mats == 0:
        num_mats = 1
        colors = [(0.5, 0.5, 0.5, 1.0)]
    else:
        colors = []
        for slot in mat_slots:
            mat = slot.material
            if mat and hasattr(mat, "diffuse_color"):
                col = tuple(mat.diffuse_color)
            else:
                col = (0.5, 0.5, 0.5, 1.0)
            colors.append(col)

    img_size = 256
    tex_filename = f"{base_name}.png"
    tex_path = os.path.join(textures_out_dir, tex_filename)

    if tex_filename in bpy.data.images:
        bpy.data.images.remove(bpy.data.images[tex_filename])
    img = bpy.data.images.new(name=tex_filename, width=img_size, height=img_size, alpha=False)

    pixels = [0.0] * (img_size * img_size * 4)
    block_width = img_size // num_mats

    for y in range(img_size):
        for x in range(img_size):
            mat_idx = min(x // block_width, num_mats - 1)
            col = colors[mat_idx]
            pixel_idx = (y * img_size + x) * 4
            pixels[pixel_idx] = col[0]
            pixels[pixel_idx + 1] = col[1]
            pixels[pixel_idx + 2] = col[2]
            pixels[pixel_idx + 3] = 1.0

    img.pixels = pixels
    img.filepath_raw = tex_path
    img.file_format = "PNG"
    img.save()
    print("Saved texture:", tex_path)

    # Material assignment
    new_mat = bpy.data.materials.new(name=f"{base_name}_mat")
    new_mat.use_nodes = True
    bsdf = new_mat.node_tree.nodes.get("Principled BSDF")
    tex_node = new_mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex_node.image = img
    new_mat.node_tree.links.new(bsdf.inputs["Base Color"], tex_node.outputs["Color"])

    mesh = mesh_obj.data
    if not mesh.uv_layers:
        uv_layer = mesh.uv_layers.new(name="UVMap")
    else:
        uv_layer = mesh.uv_layers.active

    for poly in mesh.polygons:
        mat_idx = min(poly.material_index, num_mats - 1)
        u_center = (mat_idx + 0.5) / num_mats
        v_center = 0.5
        for loop_idx in poly.loop_indices:
            uv_layer.data[loop_idx].uv = (u_center, v_center)

    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(new_mat)

    # --- 2. Master Action & Animations ---
    actions = [a for a in bpy.data.actions if len(a.fcurves) > 0]

    # Standard animation order
    desired_order = ["idle", "walk", "run", "attack", "death", "jump"]
    ordered_actions = []

    for key in desired_order:
        match = None
        for a in actions:
            a_lower = a.name.lower()
            if key in a_lower:
                match = a
                break
        if match and match not in ordered_actions:
            ordered_actions.append(match)

    # Catch any leftover actions
    for a in actions:
        if a not in ordered_actions:
            ordered_actions.append(a)

    master_action = bpy.data.actions.new(name=f"{base_name}_Master")
    if not arm.animation_data:
        arm.animation_data_create()
    arm.animation_data.action = master_action

    current_frame = 1
    anim_ranges = {}

    for act in ordered_actions:
        f_start = int(act.frame_range[0])
        f_end = int(act.frame_range[1])
        length = f_end - f_start

        range_start = current_frame
        range_end = current_frame + length

        for f in range(f_start, f_end + 1):
            target_f = current_frame + (f - f_start)
            arm.animation_data.action = act
            bpy.context.scene.frame_set(f)

            arm.animation_data.action = master_action
            for pb in arm.pose.bones:
                pb.keyframe_insert(data_path="location", frame=target_f)
                if pb.rotation_mode == "QUATERNION":
                    pb.keyframe_insert(data_path="rotation_quaternion", frame=target_f)
                else:
                    pb.keyframe_insert(data_path="rotation_euler", frame=target_f)
                pb.keyframe_insert(data_path="scale", frame=target_f)

        # Normalize key name
        act_key = act.name.lower()
        for k in desired_order:
            if k in act_key:
                act_key = k
                break

        anim_ranges[act_key] = {"x": range_start, "y": range_end}
        current_frame = range_end + 10

    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = current_frame - 10

    animation_summary[base_name] = anim_ranges

    # Export B3D
    out_b3d = os.path.join(models_out_dir, f"{base_name}.b3d")
    bpy.ops.export_scene.b3d(filepath=out_b3d, use_selection=False)
    print("Exported B3D:", out_b3d, "size:", os.path.getsize(out_b3d))

    # Export GLB
    out_glb = os.path.join(models_out_dir, f"{base_name}.glb")
    bpy.ops.export_scene.gltf(filepath=out_glb)
    print("Exported GLB:", out_glb, "size:", os.path.getsize(out_glb))

with open("dino_animations.json", "w") as f:
    json.dump(animation_summary, f, indent=2)

print("CONVERSION COMPLETE. Animation summary written to dino_animations.json")
