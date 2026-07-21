# CLAUDE.md

Guidance for AI agents working on this repository.

## Project

**VESYL Shipper** — homebrew NES side-scroller in 6502 assembly (cc65).

- **Mapper**: NROM-128 (Mapper 0), 16KB PRG, CHR-RAM, **vertical mirroring** (horizontal scroll)
- **Output**: `build/vesyl_shipper.nes`
- **Toolchain**: ca65 / ld65, python3 (iNES header)

## Commands

```bash
make
make clean && make
```

## Game flow

`TITLE` → Start → `PLAY` → deliver package → `WIN` → Start → `TITLE`

| Control | Action |
|---------|--------|
| Start | Title/Win transitions |
| D-pad L/R | Move |
| A | Jump |

Controller bit masks after `read_controller` (ROL serial):  
`A=$80 B=$40 Select=$20 Start=$10 Up=$08 Down=$04 Left=$02 Right=$01`

**Objective**: Pick up package near warehouse start, carry to truck at right end of level.

## Layout

| Path | Role |
|------|------|
| `src/main.s` | All code, CHR tiles, strings, level draw |
| `nrom128.cfg` | Memory map |
| `Makefile` | `NAME = vesyl_shipper`; header flags vertical mirror |

## Architecture

### States (`game_state`)

- `STATE_TITLE` (0) — box art, “VESYL SHIPPER”, “PRESS START”
- `STATE_PLAY` (1) — side-scroll level
- `STATE_WIN` (2) — “DELIVERED!”

### Play systems

- **World X**: 16-bit `player_x_lo/hi` (level ~512 px / 2 nametables)
- **Scroll**: `scroll_lo/hi`; NMI writes `PPUCTRL` + `PPUSCROLL`
- **Physics**: gravity, jump (`JUMP_V`), ground at `GROUND_TOP_Y` (168), two platforms
- **Package**: `has_package`; world sprite until pickup, then carried sprite
- **Truck zone**: world X ≈ 400–480 with package → win
- **Player**: original 16×16 metasprites (idle/walk, optional flip)

### Zero page highlights

`game_state`, `pad1` / `pad1_prev` / `pad1_edge`, `scroll_*`, `player_x_*`, `player_y`, `screen_x`, `vel_y`, `on_ground`, `has_package`, `oam_idx`

### CHR tiles

Order in `tiles:` … `tiles_end:` must match constants `T_*` (sky, player, ground, brick, platform, box, truck, font).

Font: `T_FONT + 0` = space, `+1` = A … `+26` = Z, `+27` = `!`. Strings are font-relative indices ending in `$FF`.

### Metasprite format

Y-off, X-off, tile, attr; terminator `$80`. Drawn at `player_y` / `screen_x`.

## Conventions

- Change scroll / PPUCTRL nametable bits only in a way NMI applies every frame
- Keep `oam_shadow` first in BSS at `$0200` for OAM DMA
- Prefer `make clean && make` after large edits
- iNES header must keep **vertical mirroring** (`flags6` bit 0 = 1) for dual-nametable horizontal scroll

## Out of scope (v1)

Enemies, sound, multi-level, vertical scroll, mapper upgrades.
