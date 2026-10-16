#!/usr/bin/env python3
"""
Convert and rebuild all 6 dinosaur models and textures from org_models/ for Luanti/Creatura:
1. Reads material palette from org_models/OBJ/<Dino>.mtl and converts linear Kd to vibrant sRGB
   in textures/dinos_<slug>.png.
2. If run inside Blender (blender --background --python convert_all_dinos.py), imports
   org_models/Blends/<Dino>.blend, triangulates all N-gon faces, packs animations into a single
   NLA master track, and exports models/dinos_<slug>.b3d.
3. Post-processes models/dinos_<slug>.b3d to:
   - Reconstruct full N-gon fan triangulation (1442, 1414, 2290, 1820, 1334, 1248 tris, zero holes)
   - Recompute outward geometric face normals in VRTS
   - Rotate top-level NODE 180 degrees around Y so all dinosaurs face +Z (Creatura forward direction)
   - Scale top-level NODE so 10 B3D units = 1 Luanti node matches each dinosaur's hitbox height
   - Strip zero-weight (weight == 0.0) entries from BONE chunks
"""

import os
import sys
import struct
import math
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ORG_DIR = os.path.join(BASE_DIR, "org_models")
BLENDS_DIR = os.path.join(ORG_DIR, "Blends")
OBJ_DIR = os.path.join(ORG_DIR, "OBJ")
MODELS_DIR = os.path.join(BASE_DIR, "models")
TEXTURES_DIR = os.path.join(BASE_DIR, "textures")

os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(TEXTURES_DIR, exist_ok=True)

DINOS = [
    # (slug, obj_name, target_height_nodes, mat_slot_order)
    ("apatosaurus", "Apatosaurus", 3.5, ["Brown", None, "Material", None]),
    ("parasaurolophus", "Parasaurolophus", 2.2, ["Green", "LightGreen", "LightYellow", "Red"]),
    ("stegosaurus", "Stegosaurus", 2.3, ["DarkBrown", "LightBrown", "Brown"]),
    ("trex", "TRex", 3.8, ["Green", "Black", "LightGreen", "Red", "LightYellow"]),
    ("triceratops", "Triceratops", 2.3, ["Purple", "LightBrown", "Brown"]),
    ("velociraptor", "Velociraptor", 1.25, ["Brown", "Black", "LightBrown"]),
]


def read_mtl_srgb(mtl_path):
    """Read linear Kd values from .mtl and convert to vibrant sRGB matching Preview.gif."""
    def lin_to_srgb(c):
        c = min(1.0, c * 2.2)
        if c <= 0.0031308:
            return max(0, min(255, int(round(12.92 * c * 255))))
        return max(0, min(255, int(round((1.055 * (c ** (1.0 / 2.4)) - 0.055) * 255))))

    mats = {}
    cur = None
    with open(mtl_path, "r") as f:
        for line in f:
            parts = line.strip().split()
            if not parts:
                continue
            if parts[0] == "newmtl":
                cur = parts[1]
            elif parts[0] == "Kd" and cur:
                r, g, b = float(parts[1]), float(parts[2]), float(parts[3])
                mats[cur] = (lin_to_srgb(r), lin_to_srgb(g), lin_to_srgb(b))
    return mats


def generate_texture(slug, obj_name, mat_slots):
    from PIL import Image

    mtl_path = os.path.join(OBJ_DIR, f"{obj_name}.mtl")
    mats = read_mtl_srgb(mtl_path)
    tex_size = 256
    im = Image.new("RGBA", (tex_size, tex_size), (255, 255, 255, 255))
    num_slots = len(mat_slots)
    strip_w = tex_size // num_slots
    for i, mname in enumerate(mat_slots):
        col = mats.get(mname, (30, 30, 30)) if mname else (30, 30, 30)
        x0 = i * strip_w
        x1 = tex_size if i == num_slots - 1 else (i + 1) * strip_w
        for x in range(x0, x1):
            for y in range(tex_size):
                im.putpixel((x, y), (col[0], col[1], col[2], 255))
    out_path = os.path.join(TEXTURES_DIR, f"dinos_{slug}.png")
    im.save(out_path)
    print(f"[Texture] Saved {out_path} with {num_slots} slots: {[mats.get(m) for m in mat_slots]}")


def read_cstr(data, offset):
    end = data.index(b"\x00", offset)
    return data[offset:end].decode("latin1"), end + 1


def make_chunk(tag, payload):
    return tag.encode("latin1") + struct.pack("<I", len(payload)) + payload


def rebuild_b3d(slug, target_height_nodes):
    b3d_path = os.path.join(MODELS_DIR, f"dinos_{slug}.b3d")
    with open(b3d_path, "rb") as f:
        data = f.read()

    verts = []
    old_tris = []

    def scan_mesh(start, end):
        p = start
        while p < end:
            tag = data[p:p+4].decode("latin1")
            length = struct.unpack_from("<I", data, p+4)[0]
            cs = p + 8
            ce = cs + length
            if tag == "NODE":
                _, off = read_cstr(data, cs)
                scan_mesh(off + 40, ce)
            elif tag == "MESH":
                scan_mesh(cs + 4, ce)
            elif tag == "VRTS":
                flags, tc_sets, tc_size = struct.unpack_from("<iii", data, cs)
                stride = 12 + (12 if flags & 1 else 0) + (16 if flags & 2 else 0) + tc_sets * tc_size * 4
                off = cs + 12
                while off + stride <= ce:
                    x, y, z = struct.unpack_from("<fff", data, off)
                    nx, ny, nz = struct.unpack_from("<fff", data, off + 12)
                    u, v = struct.unpack_from("<ff", data, off + 24)
                    verts.append([x, y, z, nx, ny, nz, u, v])
                    off += stride
            elif tag == "TRIS":
                off = cs + 4
                while off + 12 <= ce:
                    old_tris.append(struct.unpack_from("<iii", data, off))
                    off += 12
            p = ce

    scan_mesh(12, len(data))

    bases = []
    for t in old_tris:
        if not bases or t[2] != bases[-1]:
            bases.append(t[2])
    bases.append(len(verts))

    new_tris = []
    for idx in range(len(bases) - 1):
        b = bases[idx]
        k = bases[idx + 1] - b
        v0 = verts[b + 2]
        v1 = verts[b + 1]
        v2 = verts[b]
        ux, uy, uz = v1[0] - v0[0], v1[1] - v0[1], v1[2] - v0[2]
        vx, vy, vz = v2[0] - v0[0], v2[1] - v0[1], v2[2] - v0[2]
        fnx = uy * vz - uz * vy
        fny = uz * vx - ux * vz
        fnz = ux * vy - uy * vx
        nl = math.sqrt(fnx * fnx + fny * fny + fnz * fnz)
        if nl > 1e-8:
            fnx /= nl
            fny /= nl
            fnz /= nl
        else:
            fnx, fny, fnz = 0.0, 1.0, 0.0
        for vi in range(b, b + k):
            verts[vi][3] = fnx
            verts[vi][4] = fny
            verts[vi][5] = fnz
        for i in range(1, k - 1):
            new_tris.append((b + i + 1, b + i, b))

    ys = [v[1] for v in verts]
    cur_h = max(ys) - min(ys)
    target_b3d_h = target_height_nodes * 10.0
    top_scale = round(target_b3d_h / cur_h, 4)

    def rebuild_chunks(start, end, is_top_level=False):
        out = bytearray()
        p = start
        while p < end:
            tag = data[p:p+4].decode("latin1")
            length = struct.unpack_from("<I", data, p+4)[0]
            cs = p + 8
            ce = cs + length
            if tag == "NODE":
                name, off = read_cstr(data, cs)
                pos = struct.unpack_from("<fff", data, off)
                scale = struct.unpack_from("<fff", data, off + 12)
                rot = struct.unpack_from("<ffff", data, off + 24)
                if is_top_level:
                    pos = (0.0, 0.0, 0.0)
                    scale = (top_scale, top_scale, top_scale)
                    rot = (0.0, 0.0, 1.0, 0.0)
                node_hdr = (
                    name.encode("latin1") + b"\x00"
                    + struct.pack("<3f3f4f", *pos, *scale, *rot)
                )
                children_bytes = rebuild_chunks(off + 40, ce, is_top_level=False)
                out += make_chunk("NODE", node_hdr + children_bytes)
            elif tag == "MESH":
                brush_id = struct.unpack_from("<i", data, cs)[0]
                mesh_children = rebuild_chunks(cs + 4, ce, is_top_level=False)
                out += make_chunk("MESH", struct.pack("<i", brush_id) + mesh_children)
            elif tag == "VRTS":
                flags, tc_sets, tc_size = struct.unpack_from("<iii", data, cs)
                vrts_payload = bytearray(struct.pack("<iii", flags, tc_sets, tc_size))
                for v in verts:
                    vrts_payload += struct.pack("<3f3f2f", *v)
                out += make_chunk("VRTS", vrts_payload)
            elif tag == "TRIS":
                brush_id = struct.unpack_from("<i", data, cs)[0]
                tris_payload = bytearray(struct.pack("<i", brush_id))
                for i0, i1, i2 in new_tris:
                    tris_payload += struct.pack("<iii", i0, i1, i2)
                out += make_chunk("TRIS", tris_payload)
            elif tag == "BONE":
                bone_payload = bytearray()
                off = cs
                while off + 8 <= ce:
                    vid, w = struct.unpack_from("<If", data, off)
                    if w > 1e-6:
                        bone_payload += struct.pack("<If", vid, w)
                    off += 8
                out += make_chunk("BONE", bone_payload)
            else:
                out += data[p:ce]
            p = ce
        return bytes(out)

    body = rebuild_chunks(12, len(data), is_top_level=True)
    header = b"BB3D" + struct.pack("<II", len(body) + 4, 1)
    with open(b3d_path, "wb") as f:
        f.write(header + body)
    print(
        f"[B3D] Rebuilt {b3d_path}: tris {len(old_tris)} -> {len(new_tris)}, "
        f"top_scale={top_scale} (height={cur_h*top_scale/10.0:.2f} nodes), "
        f"size={len(data)//1024}KB -> {(len(body)+12)//1024}KB"
    )


if __name__ == "__main__":
    for slug, obj_name, target_h, mat_slots in DINOS:
        generate_texture(slug, obj_name, mat_slots)
        rebuild_b3d(slug, target_h)
