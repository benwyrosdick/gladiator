# CLAUDE.md

Guidance for AI agents working on this repository.

## Project

Homebrew NES game in 6502 assembly (cc65). Learning project for NES development.

- **Mapper**: NROM-128 (Mapper 0) — 16KB PRG, CHR-RAM
- **Toolchain**: ca65 / ld65
- **Output**: `build/gladiator.nes`

## Commands

```bash
make              # build ROM
make clean && make
```

Run the ROM in Mesen, FCEUX, or Nestopia UE.

## Layout

| Path | Role |
|------|------|
| `src/main.s` | All game code, tiles, palettes, map, logic |
| `nrom128.cfg` | Linker memory map |
| `Makefile` | Build: assemble → link → iNES header → `.nes` |
| `nes_assembly_guide.md` | NES/6502 reference (not project-specific) |

## Memory

- **Zero page**: `frame_flag`, `pad1`, `sprite_x/y`, `anim_frame`, metasprite pointer
- **OAM shadow `$0200`**: 256-byte sprite buffer; NMI does DMA via `$4014`
- **PRG `$C000–$FFFF`**: code + RODATA (single 16KB bank)

## What exists today

- 16×16 player metasprite (4 hardware sprites), idle + two walk frames
- D-pad movement; walk anim advances every 8 frames while moving
- Arena background (walls, floor, pillars) loaded from `arena_map`
- CHR-RAM tiles uploaded at reset; Roman-ish palettes

### Tile indices (`src/main.s`)

Order in the `tiles:` … `tiles_end:` blob must match these constants:

- `BG_TILE_IDX`, `PLAYER_IDLE_0`–`3`, `PLAYER_WALK_2`–`3`
- `WALL_TILE`, `FLOOR_TILE`, `PILLAR_TILE`

### Metasprite format

Each entry is 4 bytes: **Y offset, X offset, tile, attributes**. Terminator: `$80`.

## Conventions when editing

**Graphics**

1. Append tile bytes inside `tiles:` … `tiles_end:`
2. Update tile index constants (and any hardcoded map bytes)
3. New metasprites: same 4-byte format + `$80` end marker

**Gameplay knobs** (search symbols, not line numbers)

- Movement: `inc`/`dec` of `sprite_x` / `sprite_y` on D-pad bits
- Anim rate: three `lsr` on `anim_frame` (÷8)
- Controller bits in `pad1` after `read_controller1`: bit7 Right, bit6 Left, bit5 Down, bit4 Up, bit3 Start, bit2 Select, bit1 B, bit0 A

**Build discipline**

- Prefer `make clean && make` after structural changes
- Keep OAM shadow at `$0200` (BSS must stay first so DMA page is `$02`)
- Do not break the NMI → `frame_flag` → main loop frame sync

## Out of scope / keep simple

Single-file codebase is intentional. Split files only if the project grows past a toy. Prefer NROM/CHR-RAM patterns already in use over introducing mappers early.
