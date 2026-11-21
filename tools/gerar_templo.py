"""
Gera o cenário do protótipo (corredor do templo) como um arquivo de modelo do Rojo.

Uso:  python3 tools/gerar_templo.py
Saída: world/Temple.model.json

O cenário é feito só com Parts simples (sem malhas, sem texturas externas),
o que deixa tudo leve para celulares e fácil de editar depois no Roblox Studio.

Eixos: o jogador nasce perto de Z = +14 e anda para frente, no sentido de -Z.
"""

import json
import math
import os

# ---------------------------------------------------------------- paleta (anime)
C = {
    "grass": (0.40, 0.72, 0.48),
    "grass_dark": (0.27, 0.55, 0.40),
    "path": (0.86, 0.80, 0.70),
    "stone": (0.78, 0.76, 0.86),
    "stone_dark": (0.45, 0.43, 0.58),
    "stone_floor": (0.66, 0.64, 0.78),
    "plaster": (0.96, 0.91, 0.80),
    "vermilion": (0.88, 0.25, 0.22),
    "vermilion_dark": (0.62, 0.15, 0.17),
    "gold": (1.00, 0.80, 0.32),
    "wood": (0.33, 0.20, 0.22),
    "roof": (0.22, 0.30, 0.50),
    "carpet": (0.66, 0.13, 0.25),
    "teal": (0.35, 0.95, 0.95),
    "magenta": (1.00, 0.45, 0.85),
    "water": (0.30, 0.80, 0.95),
    "lantern": (1.00, 0.70, 0.35),
    "blossom": (1.00, 0.72, 0.85),
    "trunk": (0.40, 0.25, 0.25),
    "steel": (0.82, 0.90, 1.00),
    "leather": (0.45, 0.12, 0.18),
    "book_cover": (0.42, 0.22, 0.68),
    "paper": (0.98, 0.95, 0.86),
}


# ---------------------------------------------------------------- utilidades
def rot_matrix(rx=0.0, ry=0.0, rz=0.0):
    """Matriz de rotação igual a CFrame.Angles(rx, ry, rz) (graus). Retorna as 3 linhas."""
    rx, ry, rz = (math.radians(a) for a in (rx, ry, rz))
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    rxm = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    rym = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    rzm = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

    m = mul(mul(rxm, rym), rzm)
    return [[round(v, 6) for v in row] for row in m]


def cframe(pos, rot=(0, 0, 0)):
    return {"CFrame": {"position": [round(p, 4) for p in pos], "orientation": rot_matrix(*rot)}}


def color(name_or_rgb):
    rgb = C[name_or_rgb] if isinstance(name_or_rgb, str) else name_or_rgb
    return {"Color3": list(rgb)}


def part(name, size, pos, col, material="SmoothPlastic", rot=(0, 0, 0), cls="Part",
         shape=None, transparency=0, shadow=True, collide=True, children=None, attrs=None):
    props = {
        "Anchored": True,
        "Size": [round(s, 4) for s in size],
        "CFrame": cframe(pos, rot),
        "Color": color(col),
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
        "CastShadow": shadow,
        "CanCollide": collide,
    }
    if not collide:
        props["CanTouch"] = False
        props["CanQuery"] = False
    if transparency:
        props["Transparency"] = transparency
    if shape:
        props["Shape"] = shape
    node = {"Name": name, "ClassName": cls, "Properties": props}
    if children:
        node["Children"] = children
    if attrs:
        node["attributes"] = attrs
    return node


def model(name, children, attrs=None):
    node = {"Name": name, "ClassName": "Model", "Children": children}
    if attrs:
        node["attributes"] = attrs
    return node


def folder(name, children):
    return {"Name": name, "ClassName": "Folder", "Children": children}


def point_light(col, rng=14, brightness=1.2, shadows=False):
    return {
        "Name": "Light",
        "ClassName": "PointLight",
        "Properties": {"Color": color(col), "Range": rng, "Brightness": brightness, "Shadows": shadows},
    }


def particles(name, col, rate, size, speed, lifetime, spread, accel=(0, 0, 0), light_emission=0.6):
    return {
        "Name": name,
        "ClassName": "ParticleEmitter",
        "Properties": {
            "Color": {"ColorSequence": {"keypoints": [
                {"time": 0, "color": list(C[col])}, {"time": 1, "color": list(C[col])}]}},
            "Rate": rate,
            "Size": {"NumberSequence": {"keypoints": [
                {"time": 0, "value": size, "envelope": 0},
                {"time": 1, "value": size * 0.4, "envelope": 0}]}},
            "Transparency": {"NumberSequence": {"keypoints": [
                {"time": 0, "value": 0.2, "envelope": 0},
                {"time": 1, "value": 1, "envelope": 0}]}},
            "Speed": {"NumberRange": [speed * 0.5, speed]},
            "Lifetime": {"NumberRange": [lifetime * 0.6, lifetime]},
            "SpreadAngle": {"Vector2": [spread, spread]},
            "Acceleration": list(accel),
            "LightEmission": light_emission,
            "RotSpeed": {"NumberRange": [-60, 60]},
            "Rotation": {"NumberRange": [0, 360]},
        },
    }


# ---------------------------------------------------------------- dimensões
FLOOR_Y = 2.0          # altura do piso do templo (o pátio fica em Y = 0)
HALF_W = 10.0          # meia largura interna do corredor
WALL_H = 16.0          # altura das paredes do corredor
CORRIDOR_START = -12.0
CORRIDOR_END = -112.0
SEGMENT = 12.5         # distância entre pares de colunas
BRIDGE = (-56.0, -72.0)  # trecho com canais de água espiritual
HALL_START, HALL_END = CORRIDOR_END, -152.0
HALL_HALF = 20.0
HALL_H = 26.0


# ---------------------------------------------------------------- pátio de entrada
def build_courtyard():
    kids = []
    kids.append(part("Ground", (220, 2, 260), (0, -1, -60), "grass", "Grass", shadow=False))
    kids.append(part("Path", (12, 0.2, 30), (0, 0.1, 5), "path", "Sandstone", shadow=False))
    # Paredes invisíveis na borda do gramado (ninguém cai no vazio)
    for name, size, pos in (("BoundaryNorth", (220, 40, 2), (0, 20, 69)), ("BoundarySouth", (220, 40, 2), (0, 20, -189)),
                            ("BoundaryWest", (2, 40, 260), (-109, 20, -60)), ("BoundaryEast", (2, 40, 260), (109, 20, -60))):
        kids.append(part(name, size, pos, "grass", transparency=1, shadow=False))

    # Portal (estilo "torii") na entrada
    gate = []
    for side in (-1, 1):
        x = side * 8
        gate.append(part("Pillar", (1.8, 15, 1.8), (x, 7.5, 6), "vermilion"))
        gate.append(part("Base", (2.6, 1, 2.6), (x, 0.5, 6), "wood"))
    gate.append(part("TopBeam", (22, 1.4, 2.4), (0, 15.6, 6), "wood"))
    gate.append(part("TopBeamRed", (20, 1.2, 2.0), (0, 14.4, 6), "vermilion"))
    gate.append(part("LowerBeam", (18, 0.9, 1.4), (0, 12.2, 6), "vermilion"))
    gate.append(part("Plaque", (3, 2.4, 0.4), (0, 13.3, 6.8), "gold", "Metal"))
    kids.append(model("Gate", gate))

    # Lanternas de pedra
    for i, (x, z) in enumerate([(-9, 0), (9, 0), (-9, 12), (9, 12)]):
        lamp = [
            part("Foot", (2, 1, 2), (x, 0.5, z), "stone_dark", "Slate"),
            part("Post", (0.9, 3, 0.9), (x, 2.5, z), "stone", "Slate"),
            part("Box", (1.8, 1.6, 1.8), (x, 4.8, z), "lantern", "Neon", transparency=0.15, shadow=False,
                 children=[point_light("lantern", 14, 1.4)]),
            part("Roof", (2.6, 0.6, 2.6), (x, 5.9, z), "stone_dark", "Slate"),
            part("Cap", (0.8, 0.6, 0.8), (x, 6.5, z), "stone", "Slate"),
        ]
        kids.append(model(f"StoneLantern{i + 1}", lamp))

    # Árvores de cerejeira (blocos e esferas simples)
    for i, (x, z, s) in enumerate([(-24, 6, 1.0), (22, 10, 1.2), (-30, -20, 1.3), (28, -30, 1.1),
                                   (-28, -70, 1.2), (30, -90, 1.0), (-26, -125, 1.3), (32, -140, 1.1)]):
        tree = [part("Trunk", (1.6 * s, 10 * s, 1.6 * s), (x, 5 * s, z), "trunk", "Wood")]
        for j, (dx, dy, dz, r) in enumerate([(0, 11, 0, 6), (3, 9.5, 2, 4.5), (-3, 10, -1, 4.5), (1, 13, -2, 4)]):
            tree.append(part(f"Leaves{j + 1}", (r * 2 * s,) * 3, (x + dx * s, dy * s, z + dz * s), "blossom",
                             shape="Ball", shadow=j == 0))
        kids.append(model(f"BlossomTree{i + 1}", tree))

    # Escadaria até a entrada do templo
    for i in range(4):
        kids.append(part(f"Step{i + 1}", (20, 0.5 * (i + 1), 2), (0, 0.25 * (i + 1), -4 - i * 2), "stone", "Slate"))
    return model("Courtyard", kids)


# ---------------------------------------------------------------- corredor
def build_corridor():
    kids = []
    length = CORRIDOR_START - CORRIDOR_END
    mid_z = (CORRIDOR_START + CORRIDOR_END) / 2

    # Piso (dividido para abrir os canais de água na ponte)
    def floor_piece(name, z0, z1, half_w=HALF_W + 2):
        return part(name, (half_w * 2, FLOOR_Y, z0 - z1), (0, FLOOR_Y / 2, (z0 + z1) / 2), "stone_floor",
                    "Slate", shadow=False)

    kids.append(floor_piece("FloorA", CORRIDOR_START, BRIDGE[0]))
    kids.append(floor_piece("FloorB", BRIDGE[1], CORRIDOR_END))
    # Tapete central com bordas douradas
    for name, z0, z1 in (("CarpetA", CORRIDOR_START, BRIDGE[0]), ("CarpetB", BRIDGE[1], CORRIDOR_END)):
        zc, ln = (z0 + z1) / 2, z0 - z1
        kids.append(part(name, (5, 0.1, ln), (0, FLOOR_Y + 0.05, zc), "carpet", "Fabric", shadow=False, collide=False))
        for side in (-1, 1):
            kids.append(part(name + "Trim", (0.4, 0.12, ln), (side * 2.7, FLOOR_Y + 0.06, zc), "gold", "Metal",
                             shadow=False, collide=False))

    # Paredes laterais (base escura + reboco claro + friso vermelho)
    for side, label in ((-1, "Left"), (1, "Right")):
        x = side * (HALF_W + 1)
        kids.append(part(f"Wall{label}", (2, WALL_H, length), (x, FLOOR_Y + WALL_H / 2, mid_z), "plaster", shadow=False))
        kids.append(part(f"WallBase{label}", (2.4, 2, length), (x, FLOOR_Y + 1, mid_z), "stone_dark", "Slate", shadow=False))
        kids.append(part(f"WallFrieze{label}", (2.3, 1.2, length), (x, FLOOR_Y + WALL_H - 2, mid_z), "vermilion", shadow=False))
        kids.append(part(f"WallGoldLine{label}", (2.35, 0.3, length), (x, FLOOR_Y + WALL_H - 3, mid_z), "gold", "Metal", shadow=False))

    # Teto: telhado azul com faixas abertas para entrar luz
    kids.append(part("RoofEdgeLeft", (6, 1.5, length), (-HALF_W + 1, FLOOR_Y + WALL_H + 0.75, mid_z), "roof", "Slate"))
    kids.append(part("RoofEdgeRight", (6, 1.5, length), (HALF_W - 1, FLOOR_Y + WALL_H + 0.75, mid_z), "roof", "Slate"))

    # Colunas, vigas, painéis com runas e lanternas penduradas
    n = int(length // SEGMENT) + 1
    for i in range(n):
        z = CORRIDOR_START - 2 - i * SEGMENT
        if z < CORRIDOR_END + 1:
            break
        seg = []
        for side in (-1, 1):
            x = side * (HALF_W - 1.2)
            seg.append(part("PillarBase", (2.8, 1.2, 2.8), (x, FLOOR_Y + 0.6, z), "stone_dark", "Slate"))
            seg.append(part("Pillar", (WALL_H - 1.2, 1.9, 1.9), (x, FLOOR_Y + 1.2 + (WALL_H - 1.2) / 2, z),
                            "vermilion", shape="Cylinder", rot=(0, 0, 90)))
            seg.append(part("PillarRing", (0.5, 2.3, 2.3), (x, FLOOR_Y + 3, z), "gold", "Metal",
                            shape="Cylinder", rot=(0, 0, 90), shadow=False))
            seg.append(part("PillarCap", (3, 1, 3), (x, FLOOR_Y + WALL_H - 0.5, z), "gold", "Metal", shadow=False))
        # Viga transversal
        seg.append(part("Beam", (HALF_W * 2 + 2, 1.4, 1.6), (0, FLOOR_Y + WALL_H + 0.2, z), "wood"))

        # Lanterna pendurada no meio do segmento (exceto em cima da ponte, que tem água brilhante)
        lz = z - SEGMENT / 2
        if lz > CORRIDOR_END + 2 and not (BRIDGE[1] - 2 < lz < BRIDGE[0] + 2) and i % 2 == 0:
            seg.append(part("LanternCord", (0.15, 3, 0.15), (0, FLOOR_Y + WALL_H - 1.5, lz), "wood", shadow=False, collide=False))
            seg.append(part("Lantern", (2.4, 3, 2.4), (0, FLOOR_Y + WALL_H - 4.5, lz), "lantern", "Neon",
                            shape="Ball", transparency=0.05, shadow=False, collide=False,
                            children=[point_light("lantern", 22, 1.6, shadows=True)]))
            seg.append(part("LanternCapTop", (1.4, 0.4, 1.4), (0, FLOOR_Y + WALL_H - 2.9, lz), "wood", shadow=False, collide=False))
            seg.append(part("LanternCapBottom", (1.2, 0.4, 1.2), (0, FLOOR_Y + WALL_H - 6.1, lz), "wood", shadow=False, collide=False))

        # Painel com runa brilhante entre colunas
        if lz > CORRIDOR_END + 2:
            for side in (-1, 1):
                x = side * (HALF_W - 0.05)
                seg.append(part("RunePanel", (0.2, 6, 5), (x, FLOOR_Y + 7, lz), "vermilion_dark", shadow=False, collide=False))
                # Runa circular: anel brilhante + losango no centro
                seg.append(part("RuneRing", (0.12, 3.4, 3.4), (side * (HALF_W - 0.2), FLOOR_Y + 7, lz), "teal", "Neon",
                                shape="Cylinder", shadow=False, collide=False))
                seg.append(part("RuneRingInner", (0.12, 2.7, 2.7), (side * (HALF_W - 0.27), FLOOR_Y + 7, lz),
                                "vermilion_dark", shape="Cylinder", shadow=False, collide=False))
                seg.append(part("RuneDiamond", (0.1, 1.1, 1.1), (side * (HALF_W - 0.32), FLOOR_Y + 7, lz), "teal", "Neon",
                                rot=(45, 0, 0), shadow=False, collide=False))
                # Cristais na base da parede
                seg.append(part("Crystal", (0.9, 2.2, 0.9), (side * (HALF_W - 0.8), FLOOR_Y + 1.1, lz + 1.5), "teal",
                                "Neon", rot=(15 * side, 30, 10), shadow=False, collide=False))
        kids.append(model(f"Segment{i + 1:02d}", seg))

    # Trecho da ponte: canais de água espiritual nas laterais
    bz0, bz1 = BRIDGE
    bl, bc = bz0 - bz1, (bz0 + bz1) / 2
    bridge = [
        part("BridgeDeck", (7, FLOOR_Y, bl), (0, FLOOR_Y / 2, bc), "wood", "WoodPlanks"),
        part("Carpet", (5, 0.1, bl), (0, FLOOR_Y + 0.05, bc), "carpet", "Fabric", shadow=False, collide=False),
    ]
    for side in (-1, 1):
        bridge.append(part("ChannelBed", (HALF_W - 3.5 + 2, 1, bl), (side * (3.5 + (HALF_W - 1.5) / 2), -2.5, bc),
                           "stone_dark", "Slate", shadow=False))
        bridge.append(part("SpiritWater", (HALF_W - 3.5 + 2, 0.4, bl), (side * (3.5 + (HALF_W - 1.5) / 2), -0.6, bc),
                           "water", "Neon", transparency=0.35, shadow=False, collide=False))
        bridge.append(part("Rail", (0.6, 0.5, bl), (side * 3.4, FLOOR_Y + 2.6, bc), "vermilion"))
        for k in range(5):
            bridge.append(part("RailPost", (0.6, 2.6, 0.6), (side * 3.4, FLOOR_Y + 1.3, bz0 - 1 - k * (bl - 2) / 4),
                               "vermilion"))
        # Paredes do canal (para ninguém sair do mapa por baixo)
        bridge.append(part("ChannelWall", (0.5, FLOOR_Y + 3.5, bl), (side * (HALF_W + 0.25), FLOOR_Y / 2 - 1.75 + 1.75, bc),
                           "stone_dark", "Slate", shadow=False))
    bridge.append(part("WaterMist", (HALF_W * 2, 0.2, bl), (0, -0.3, bc), "water", "SmoothPlastic", transparency=1,
                       shadow=False, collide=False,
                       children=[particles("Sparkles", "teal", 14, 0.35, 1.5, 4, 40, (0, 0.6, 0))]))
    # Barreiras invisíveis sobre a água (evitam queda acidental)
    for side in (-1, 1):
        bridge.append(part("InvisibleRail", (0.5, 8, bl), (side * 3.6, FLOOR_Y + 4, bc), "steel", transparency=1,
                           shadow=False))
    kids.append(model("SpiritBridge", bridge))

    # Pétalas caindo pelo corredor (aberturas do teto)
    kids.append(part("PetalEmitter", (HALF_W * 1.6, 0.2, length * 0.9), (0, FLOOR_Y + WALL_H + 1, mid_z), "blossom",
                     transparency=1, shadow=False, collide=False,
                     children=[particles("Petals", "blossom", 10, 0.3, 1, 9, 30, (0.4, -0.8, 0), 0.1)]))
    return model("Corridor", kids)


# ---------------------------------------------------------------- salão final
def build_hall():
    kids = []
    z0, z1 = HALL_START, HALL_END
    zc, ln = (z0 + z1) / 2, z0 - z1
    kids.append(part("Floor", (HALL_HALF * 2 + 4, FLOOR_Y, ln), (0, FLOOR_Y / 2, zc), "stone_floor", "Slate", shadow=False))
    # Paredes (as da frente têm uma abertura para o corredor)
    for side in (-1, 1):
        kids.append(part("SideWall", (2, HALL_H, ln), (side * (HALL_HALF + 1), FLOOR_Y + HALL_H / 2, zc), "plaster", shadow=False))
        kids.append(part("SideWallBase", (2.4, 2, ln), (side * (HALL_HALF + 1), FLOOR_Y + 1, zc), "stone_dark", "Slate", shadow=False))
        kids.append(part("SideFrieze", (2.3, 1.5, ln), (side * (HALL_HALF + 1), FLOOR_Y + HALL_H - 3, zc), "vermilion", shadow=False))
        w = HALL_HALF - HALF_W
        kids.append(part("FrontWall", (w, HALL_H, 2), (side * (HALF_W + w / 2 + 1), FLOOR_Y + HALL_H / 2, z0 - 1), "plaster", shadow=False))
    kids.append(part("FrontWallTop", (HALF_W * 2 + 2, HALL_H - WALL_H, 2), (0, FLOOR_Y + WALL_H + (HALL_H - WALL_H) / 2, z0 - 1),
                     "plaster", shadow=False))
    kids.append(part("BackWall", (HALL_HALF * 2 + 4, HALL_H, 2), (0, FLOOR_Y + HALL_H / 2, z1 - 1), "plaster", shadow=False))
    kids.append(part("Ceiling", (HALL_HALF * 2 + 4, 2, ln + 2), (0, FLOOR_Y + HALL_H + 1, zc), "roof", "Slate"))
    # Óculo no teto (anel dourado) — só decorativo
    kids.append(part("CeilingRing", (0.6, 14, 14), (0, FLOOR_Y + HALL_H - 0.2, zc), "gold", "Metal", shape="Cylinder",
                     rot=(0, 0, 90), shadow=False, collide=False))

    # Colunas nos cantos e ao longo das paredes
    for i, (x, z) in enumerate([(-HALL_HALF + 2, z0 - 4), (HALL_HALF - 2, z0 - 4), (-HALL_HALF + 2, z1 + 4),
                                (HALL_HALF - 2, z1 + 4), (-HALL_HALF + 2, zc), (HALL_HALF - 2, zc)]):
        kids.append(model(f"HallPillar{i + 1}", [
            part("Base", (3.4, 1.4, 3.4), (x, FLOOR_Y + 0.7, z), "stone_dark", "Slate"),
            part("Shaft", (HALL_H - 1.4, 2.4, 2.4), (x, FLOOR_Y + 1.4 + (HALL_H - 1.4) / 2, z), "vermilion",
                 shape="Cylinder", rot=(0, 0, 90)),
            part("Ring", (0.6, 2.8, 2.8), (x, FLOOR_Y + 4, z), "gold", "Metal", shape="Cylinder", rot=(0, 0, 90), shadow=False),
            part("Brazier", (1.6, 1.2, 1.6), (x, FLOOR_Y + 9, z), "magenta", "Neon",
                 shadow=False, collide=False, children=[point_light("magenta", 18, 1.2)]),
        ]))

    # Círculo mágico no chão
    for i, (d, col) in enumerate([(22, "teal"), (19, "magenta"), (12, "teal")]):
        kids.append(part(f"MagicCircle{i + 1}", (0.08 + i * 0.01, d, d), (0, FLOOR_Y + 0.02 + i * 0.01, zc), col, "Neon",
                         shape="Cylinder", rot=(0, 0, 90), shadow=False, collide=False))
        kids.append(part(f"MagicCircleInner{i + 1}", (0.09 + i * 0.01, d - 0.8, d - 0.8), (0, FLOOR_Y + 0.025 + i * 0.01, zc),
                         "stone_floor", "Slate", shape="Cylinder", rot=(0, 0, 90), shadow=False, collide=False))

    # Grande cristal flutuante no centro (o "Despertar")
    kids.append(model("AwakeningCrystal", [
        part("Crystal", (5, 5, 5), (0, FLOOR_Y + 11, zc - 4), "magenta", "Neon", rot=(45, 0, 35.26), shadow=False,
             collide=False, children=[point_light("magenta", 30, 2.2),
                                      particles("Motes", "magenta", 12, 0.4, 2, 3, 180, (0, 0.5, 0))],
             attrs={"Spin": True}),
        part("Pedestal", (4, 2, 4), (0, FLOOR_Y + 1, zc - 4), "stone", "Slate"),
        part("PedestalGold", (4.4, 0.5, 4.4), (0, FLOOR_Y + 2.1, zc - 4), "gold", "Metal"),
    ]))

    # Porta selada ao fundo
    kids.append(model("SealedDoor", [
        part("DoorFrame", (16, 18, 1.4), (0, FLOOR_Y + 9, z1 + 0.3), "vermilion"),
        part("Door", (13, 16, 1.6), (0, FLOOR_Y + 8, z1 + 0.4), "wood", "Wood"),
        part("Emblem", (0.4, 6, 6), (0, FLOOR_Y + 9, z1 + 1.3), "gold", "Metal", shape="Cylinder", rot=(0, 90, 0), shadow=False),
        part("EmblemGlow", (0.45, 3.5, 3.5), (0, FLOOR_Y + 9, z1 + 1.35), "teal", "Neon", shape="Cylinder", rot=(0, 90, 0), shadow=False),
        part("SealBarH", (14, 0.6, 0.3), (0, FLOOR_Y + 9, z1 + 1.3), "teal", "Neon", shadow=False, collide=False),
        part("SealBarV", (0.6, 16, 0.3), (0, FLOOR_Y + 8, z1 + 1.3), "teal", "Neon", shadow=False, collide=False),
    ]))
    return model("FinalHall", kids)


# ---------------------------------------------------------------- objetos interativos
def pedestal(x, z, glow):
    return [
        part("PedestalBase", (4, 1, 4), (x, FLOOR_Y + 0.5, z), "stone_dark", "Slate"),
        part("PedestalColumn", (2.6, 3, 2.6), (x, FLOOR_Y + 2.5, z), "stone", "Slate"),
        part("PedestalTop", (3.4, 0.6, 3.4), (x, FLOOR_Y + 4.3, z), "gold", "Metal"),
        part("PedestalGlow", (0.1, 3, 3), (x, FLOOR_Y + 4.62, z), glow, "Neon", shape="Cylinder", rot=(0, 0, 90),
             shadow=False, collide=False),
    ]


def prompt(object_text):
    return {
        "Name": "InspectPrompt",
        "ClassName": "ProximityPrompt",
        "Properties": {
            "ActionText": "Examinar",
            "ObjectText": object_text,
            "HoldDuration": 0,
            "MaxActivationDistance": 9,
            "RequiresLineOfSight": False,
            "KeyboardKeyCode": "E",
            "GamepadKeyCode": "ButtonX",
        },
    }


def build_items():
    zc = (HALL_START + HALL_END) / 2 + 4
    sx, bx = -9.0, 9.0
    y = FLOOR_Y + 7.2  # altura em que os itens flutuam

    sword_parts = [
        part("Handle", (0.45, 1.8, 0.45), (sx, y - 2.2, zc), "leather", "Fabric", shadow=False, collide=False,
             children=[prompt("Espada Antiga")]),
        part("Pommel", (0.7, 0.7, 0.7), (sx, y - 3.25, zc), "gold", "Metal", shape="Ball", shadow=False, collide=False),
        part("Guard", (2.6, 0.4, 0.6), (sx, y - 1.15, zc), "gold", "Metal", shadow=False, collide=False),
        part("GuardGem", (0.5, 0.5, 0.7), (sx, y - 1.15, zc), "teal", "Neon", shadow=False, collide=False),
        part("Blade", (0.5, 4.6, 0.12), (sx, y + 1.35, zc), "steel", "Metal", shadow=False, collide=False),
        part("BladeEdge", (0.14, 4.6, 0.14), (sx, y + 1.35, zc), "teal", "Neon", shadow=False, collide=False,
             children=[point_light("teal", 10, 1.0)]),
        part("BladeTip", (0.36, 0.36, 0.12), (sx, y + 3.75, zc), "steel", "Metal", rot=(0, 0, 45), shadow=False, collide=False),
    ]
    # Livro inclinado na direção de quem chega pelo corredor (+Z)
    tilt = (25, 0, 0)
    m = rot_matrix(*tilt)

    def at(dx, dy, dz):
        return (bx + m[0][0] * dx + m[0][1] * dy + m[0][2] * dz,
                y + m[1][0] * dx + m[1][1] * dy + m[1][2] * dz,
                zc + m[2][0] * dx + m[2][1] * dy + m[2][2] * dz)

    book_parts = [
        part("CoverBottom", (3, 0.2, 2.4), at(0, -0.35, 0), "book_cover", "Fabric", rot=tilt, shadow=False,
             collide=False, children=[prompt("Grimório Arcano")]),
        part("Pages", (2.8, 0.5, 2.2), at(0.05, 0, 0), "paper", rot=tilt, shadow=False, collide=False),
        part("CoverTop", (3, 0.2, 2.4), at(0, 0.35, 0), "book_cover", "Fabric", rot=tilt, shadow=False, collide=False),
        part("Spine", (0.25, 0.9, 2.4), at(-1.5, 0, 0), "gold", "Metal", rot=tilt, shadow=False, collide=False),
        part("CornerA", (0.4, 0.24, 0.4), at(1.35, 0.37, 1.05), "gold", "Metal", rot=tilt, shadow=False, collide=False),
        part("CornerB", (0.4, 0.24, 0.4), at(1.35, 0.37, -1.05), "gold", "Metal", rot=tilt, shadow=False, collide=False),
        part("Rune", (0.05, 1.5, 1.5), at(0.1, 0.47, 0), "magenta", "Neon", shape="Cylinder", rot=(25, 0, 90),
             shadow=False, collide=False, children=[point_light("magenta", 10, 1.0),
                                                    particles("Sparks", "magenta", 6, 0.25, 1, 2, 180, (0, 1, 0))]),
    ]
    return folder("Interactables", [
        model("SwordPedestal", pedestal(sx, zc, "teal")),
        model("BookPedestal", pedestal(bx, zc, "magenta")),
        model("AncientSword", sword_parts, attrs={"ItemId": "AncientSword", "Float": True}),
        model("ArcaneGrimoire", book_parts, attrs={"ItemId": "ArcaneGrimoire", "Float": True}),
    ])


# ---------------------------------------------------------------- ponto de nascimento
def build_spawn():
    return {
        "Name": "SpawnLocation",
        "ClassName": "SpawnLocation",
        "Properties": {
            "Anchored": True,
            "Size": [8, 0.4, 8],
            "CFrame": cframe((0, 0.2, 14)),
            "Color": color("path"),
            "Material": "Sandstone",
            "Transparency": 0,
            "Duration": 0,
            "Neutral": True,
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        },
        "Children": [{
            "Name": "SpawnMark",
            "ClassName": "Decal",
            "Properties": {"Transparency": 1},
        }],
    }


def main():
    root = {
        "ClassName": "Model",
        "Children": [
            build_spawn(),
            build_courtyard(),
            build_corridor(),
            build_hall(),
            build_items(),
            {
                "Name": "MenuCamera",
                "ClassName": "Part",
                "Properties": {
                    "Anchored": True, "Transparency": 1, "CanCollide": False, "CanQuery": False, "CanTouch": False,
                    "Size": [1, 1, 1],
                    # Vista do pátio olhando para o portal, usada na tela de escolha de personagem
                    "CFrame": cframe((14, 9, 32), (-8, 25, 0)),
                },
            },
        ],
    }
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "..", "world", "Temple.model.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(root, f, ensure_ascii=False, indent=1)

    def count(n):
        return (1 if n.get("ClassName") in ("Part", "SpawnLocation") else 0) + sum(count(c) for c in n.get("Children", []))

    print(f"Gerado {os.path.normpath(out)} com {count(root)} peças.")


if __name__ == "__main__":
    main()
