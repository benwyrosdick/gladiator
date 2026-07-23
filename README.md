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
| **B** (hold) | Run; also **hold package** when touching it (like a Mario shell) |
| **B** (release) | Drop package (hold **Up** to toss it up + forward) |
| **A** | Jump (hold longer for higher jump) |
| **Down + A** | Drop through a shelf/platform |

1. Title screen: **VESYL SHIPPER** — press **Start** (**20s** timer starts)
2. Climb shelves, hold **B** near the package to pick it up (keep holding)
3. Exit the warehouse door and reach the truck while carrying → **DELIVERED!**
4. If the clock hits **00**, the camera pans to the exit, the truck pulls away → **TIME UP!**

SFX: jump, pickup, drop, win jingle, timeout rumble (pulse + noise via the APU).

## Layout

```
src/main.s              Game code, tiles, level, states
nrom128.cfg             Linker config
Makefile                Build → build/vesyl_shipper.nes
nes_assembly_guide.md   NES / 6502 reference
CLAUDE.md               Notes for AI coding agents
```
