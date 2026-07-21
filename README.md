# VESYL Shipper

A simple NES side-scroller written in 6502 assembly (cc65). Carry a package from the warehouse to the delivery truck.

- **Mapper 0 (NROM-128)**: 16KB PRG-ROM, CHR-RAM, vertical mirroring (horizontal scroll)

## Requirements

- **cc65** (`ca65`, `ld65`) on your PATH  
  - macOS: `brew install cc65`
- An NES emulator (RetroArch + Nestopia/Mesen, or Mesen / FCEUX / Nestopia UE standalone)

## Build

```sh
make
```

Produces `build/vesyl_shipper.nes` and symlinks it into RetroArch’s content folder:

`~/Games/roms/nes/vesyl_shipper.nes`

(that path matches `rgui_browser_directory` in `~/.config/retroarch/retroarch.cfg`).

```sh
make install   # symlink only (also runs as part of make)
make run       # build + launch in RetroArch (Nestopia)
make run RA_CORE=mesen_libretro   # use Mesen instead
make clean
```

### RetroArch UI

1. **Load Content** → open `Games/roms/nes` → `vesyl_shipper.nes`
2. Pick core **Nestopia** or **Mesen** if prompted
## How to play

| Control | Action |
|---------|--------|
| **Start** | Begin from title / return from win |
| **D-pad ← →** | Walk left / right (accelerates / coasts like Mario) |
| **B** (hold) | Run (higher top speed) |
| **A** | Jump (hold longer for higher jump) |
| **Down + A** | Drop through a shelf/platform |
| **Select** | Drop package (while carrying) |

1. Title screen: **VESYL SHIPPER** — press **Start**
2. Pick up the package in the warehouse (walk into it)
3. Head right (platforms optional), reach the delivery truck
4. **Select** drops the box where you stand (walk into it to pick up again)
5. **DELIVERED!** — press **Start** for the title again

## Layout

```
src/main.s              Game code, tiles, level, states
nrom128.cfg             Linker config
Makefile                Build → build/vesyl_shipper.nes
nes_assembly_guide.md   NES / 6502 reference
CLAUDE.md               Notes for AI coding agents
```
