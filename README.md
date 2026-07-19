# Gladiator

A small homebrew NES game written in 6502 assembly. Built as a learning project for NES development with the cc65 toolchain.

- **Mapper 0 (NROM-128)**: 16KB PRG-ROM, CHR-RAM
- Move a 16×16 gladiator around a simple arena with D-pad walk animation

## Requirements

- **cc65** (`ca65`, `ld65`) on your PATH  
  - macOS: `brew install cc65`  
  - Linux: package manager or [build from source](https://cc65.github.io/)
- An NES emulator (Mesen, FCEUX, Nestopia UE, …)

## Build

```sh
make
```

Produces `build/gladiator.nes`. Load that file in your emulator.

```sh
make clean   # remove build/
```

## Project layout

```
src/main.s              Game code, tiles, map, palettes
nrom128.cfg             Linker config (NROM-128 memory map)
Makefile                Assemble, link, write iNES header
nes_assembly_guide.md   General NES / 6502 reference
CLAUDE.md               Notes for AI coding agents
```

## Notes

- The iNES header is 1 PRG bank, 0 CHR banks (CHR-RAM). Common emulators handle this fine.
- For larger games you would step up to NROM-256 or mappers such as MMC1/MMC3.
