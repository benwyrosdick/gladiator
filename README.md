# VESYL Shipper

A simple NES side-scroller written in 6502 assembly (cc65). Carry a package from the warehouse to the delivery truck.

- **Mapper 0 (NROM-128)**: 16KB PRG-ROM, CHR-RAM, vertical mirroring (horizontal scroll)

## Requirements

- **cc65** (`ca65`, `ld65`) on your PATH  
  - macOS: `brew install cc65`
- An NES emulator (Mesen, FCEUX, Nestopia UE, …)

## Build

```sh
make
```

Produces `build/vesyl_shipper.nes`.

```sh
make clean
```

## How to play

| Control | Action |
|---------|--------|
| **Start** | Begin from title / return from win |
| **D-pad ← →** | Walk left / right |
| **B** (hold) | Run |
| **A** | Jump (hold longer for higher jump, up to ~3×) |

1. Title screen: **VESYL SHIPPER** — press **Start**
2. Pick up the package in the warehouse (walk into it)
3. Head right (platforms optional), reach the delivery truck
4. **DELIVERED!** — press **Start** for the title again

## Layout

```
src/main.s              Game code, tiles, level, states
nrom128.cfg             Linker config
Makefile                Build → build/vesyl_shipper.nes
nes_assembly_guide.md   NES / 6502 reference
CLAUDE.md               Notes for AI coding agents
```
