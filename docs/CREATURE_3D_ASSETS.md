# NEXORA · Activos 3D de criaturas

**Estado de todos los activos de esta tabla: `Proposal` (v01).**
- Producidos con `tools/sculpt` (ver `CREATURE_DESIGN_PIPELINE.md`).
- **Sin aprobación humana** y **sin importar en Roblox Studio**.
- Ningún `rbxassetid` existe todavía.
- El juego en Roblox sigue usando los blockouts de Parts hasta que un modelo importado exista en `ReplicatedStorage.CreatureModels` (`Client/Creatures/MeshCreature.luau`).

## 1. Biblioteca (`assets/`)

```
assets/
└── Creatures/
    └── Initials/
        ├── Kuachi/    ├── Ascuacho/
        ├── Xolumi/    ├── Xolossus/
        └── Teselo/    └── Mitlaxis/
            ├── CR_<Nombre>_<Forma>_v01.glb       LOD0 · PBR 1024² · tangentes · esqueleto con piel
            ├── CR_<Nombre>_<Forma>_v01_LOD1.glb  LOD1 · PBR 512²
            ├── CR_<Nombre>_<Forma>_v01.obj/.mtl  LOD0 estático (alternativa de importación)
            ├── textures/…_color|normal|roughness|metalness|emissive.png   mapas para SurfaceAppearance
            ├── web/…web.glb                      versión ligera (JPEG 512²) para la vista previa web
            └── asset.json                        metadatos (abajo)
```

**Otras carpetas:**
- **Mundo, VFX, audio, animaciones y cinemáticas:** viven en código y datos (`Server/World`, `Shared/Config/*`, `Client/*`). Por ahora no tienen archivos binarios.
- **Seres Sagrados y resto de especies:** el árbol sigue la misma estructura (`assets/Creatures/SacredBeings/`, `assets/Creatures/Species/`) y se creará cuando se aprueben los iniciales.

**Metadatos por activo** (`asset.json`), como pide el encargo:
- id interno, nombre y versión;
- procedencia y estado (aprobación);
- especie, forma, rareza y elementos;
- bioma, familia y presupuesto;
- huesos con su pivote y LODs (triángulos, vértices, textura, cobertura UV, tamaño en studs);
- mapas, archivos, dependencias, `robloxAssetId` y notas.

`tools/sculpt/registry.py` genera `Shared/Config/CreatureAssets.luau` a partir de esos archivos. `tests/Unit/CreatureAssets.spec.luau` comprueba que coinciden.

## 2. Inventario v01 (medido)

| Activo | Forma | LOD0 tri | Presupuesto (Biblia p. 120) | LOD1 tri | Huesos | Malla de alta | Tamaño (x×y×z studs) | Cobertura UV | Disco | Web |
|---|---|---|---|---|---|---|---|---|---|---|
| Kuachi | Brote | 3 757 | 2 500–4 000 ✅ | 1 687 | 12 / 18 | 157 934 | 0,97 × 1,68 × 2,33 | 57 % | 3,9 MB | 406 KB |
| Ascuacho | Tallado | 6 108 | 4 000–6 500 ✅ | 2 748 | 19 / 30 | 240 592 | 1,22 × 2,61 × 4,62 | 55 % | 5,6 MB | 639 KB |
| Xolumi | Brote | 3 758 | 2 500–4 000 ✅ | 1 692 | 9 / 18 | 158 750 | 1,80 × 1,26 × 2,48 | 57 % | 4,3 MB | 424 KB |
| Xolossus | Tallado | 6 104 | 4 000–6 500 ✅ | 2 744 | 14 / 30 | 282 784 | 2,57 × 2,95 × 4,44 | 50 % | 5,2 MB | 594 KB |
| Teselo | Brote | 3 754 | 2 500–4 000 ✅ | 1 688 | 8 / 18 | 296 976 | 1,98 × 1,77 × 3,18 | 53 % | 5,4 MB | 445 KB |
| Mitlaxis | Tallado | 6 108 | 4 000–6 500 ✅ | 4 028 | 12 / 30 | 496 130 | 4,48 × 3,48 × 4,82 | 45 % | 6,1 MB | 660 KB |

**Notas sobre las medidas:**
- **Escala Tallado/Brote** (media geométrica de la caja): Ascuacho ×1,57, Xolossus ×1,81 y Mitlaxis ×1,89. Los dos últimos incluyen la corona de branquias y los anillos y el disco. La regla y su aclaración están en `ART_BIBLE_GENESIS.md` §2 (D-034).
- **LOD1 de Mitlaxis:** se queda en 4 028 triángulos porque la simplificación conserva los anillos y el disco, que son piezas sueltas. Si el perfilado lo pide, la solución es un LOD1 sin las marcas del astrolabio.
- **Cobertura UV** del 45–57 %: es el empaquetado automático de xatlas. Un empaquetado manual en Blender subiría la resolución efectiva.

## 3. Qué tiene cada modelo (rasgos en geometría, no pintados)

| Activo | Anatomía y rasgos firma en geometría | Relieve horneado | Emisivo (solo en surcos) |
|---|---|---|---|
| **Kuachi** | Hocico largo con nariz y fosas; orejas redondas desnudas con concha interior tallada; manos de cinco dedos y pie con pulgar; cola prensil enroscada en espiral; bolsa con abertura; mechones de mejilla en lóbulo de llama | Masas de pelaje; máscara oscura del tlacuache | Abertura de la bolsa, punta de la cola chamuscada |
| **Ascuacho** | Cuerpo de acecho largo y bajo; cabeza adelantada con ceja feroz y ojo almendrado; colmillos y garras; gola de pelo; **horno de comal** en el vientre con boca, aro, rejilla de hierro y tres respiraderos por lado; **látigo de ceniza en S** sobre el lomo con seis anillos tallados | Pelaje; lóbulos de llama tallados en los costados | Iris, boca del horno, respiraderos, anillos de la cola, surcos de los costados, brasas de la punta |
| **Xolumi** | Cabeza muy ancha; ojos en los bordes; sonrisa ancha tallada; **tres pares de branquias** con tallo y plumas; aleta dorsal y caudal; patitas de cuatro dedos | Barro negro bruñido con moteado | Puntas de las branquias (≤ 5 %) |
| **Xolossus** | **Seis patas** de anfibio con codos abiertos (las delanteras más largas); torso erguido 30°; cabeza ancha con colmillos pequeños en la misma sonrisa; **corona de branquias de humo de copal** (volutas de bocanadas); aleta dorsal y caudal con borde de oro | **Vetas de oro de reparación** (kintsugi) talladas | Iris turquesa, puntas de las volutas |
| **Teselo** | Caparazón alto de **teselas** (Voronoi) con juntas hundidas; borde y plastrón; patas columnares con uñas; cabeza curiosa con pico suave | Teselas abombadas, juntas, piel escamada | — |
| **Mitlaxis** | Fortaleza de **tres terrazas** con cornisas; **grecas de Mitla talladas** en cada terraza; cúpula de teselas de jade; **dos anillos de astrolabio** con marcas (huesos propios); **disco de cielo nocturno flotante** con aro de oro (hueso propio); pico córneo con gancho; placas de jade; patas-columna con banda de oro | Grecas, teselas, piel escamada | Surcos de las grecas, estrellas del disco, iris |

## 4. Esqueletos

Cada `Bone` tiene nombre, padre y pivote en `asset.json → bones`. El `CreatureAnimator` (`ANIMATION_SYSTEM.md`) usa los mismos nombres.

| Familia | Huesos |
|---|---|
| Cuadrúpedo ágil (Kuachi, Ascuacho) | `root, spine, chest, (neck), head, jaw, legF_L/R, legB_L/R, (pawF_L/R, pawB_L/R), tail1…tail3/5` |
| Anfibio (Xolumi, Xolossus) | `root, spine, (chest, neck), head, (jaw), legF_L/R, (legM_L/R), legB_L/R, tail1, tail2` |
| Reptil acorazado (Teselo, Mitlaxis) | `root, body, neck, head, (jaw), legF_L/R, legB_L/R, (ringA, ringB, skyDisc)` |

**Pesos:** se calculan por cercanía a las piezas de cada hueso (4 influencias como máximo por vértice, normalizadas).

**Prueba del rig:** un ciclo de paso procedural sobre el GLB en `docs/phase3/creatures/<especie>-rig-walk.jpg` y en la vista previa web (los iniciales caminan con sus huesos).

**Pesos más finos:** pintar los pesos a mano en Blender mejoraría los hombros y la base de la cola. Queda como tarea para cuando haya un artista técnico.

## 5. Pendiente para pasar de `Proposal` a `Final`

1. Revisión artística humana de las hojas de `docs/phase3/creatures/` (silueta, parecido y cultura): pasa a `InReview`/`Approved`.
2. Importación en Studio siguiendo `CREATURE_DESIGN_PIPELINE.md` §6:
   - `SurfaceAppearance`;
   - escala;
   - orientación;
   - huesos;
   - `ReplicatedStorage.CreatureModels`.
3. Prueba en dispositivo: 8 criaturas a 30 fps en el teléfono base y memoria de texturas.
4. Registrar el `rbxassetid` real en `asset.json` y regenerar el registro.
