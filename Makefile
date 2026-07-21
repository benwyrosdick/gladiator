# VESYL Shipper NES — requires cc65 (ca65, ld65) and python3
# make / make clean / make install / make run

NAME  = vesyl_shipper
CC65 ?= ca65
LD65 ?= ld65

SRC   = src/main.s
BUILD = build
OBJ   = $(BUILD)/main.o
PRG   = $(BUILD)/$(NAME).prg
NES   = $(BUILD)/$(NAME).nes
CFG   = nrom128.cfg
HDR   = $(BUILD)/header.bin

# Absolute path so install symlink works on macOS (no ln -r) and RetroArch gets a real path
NES_ABS := $(abspath $(NES))

# RetroArch content dir (optional convenience for Load Content)
RA_ROMS ?= $(HOME)/Games/roms
RA_NES  = $(RA_ROMS)/nes
RA_CORE ?= nestopia_libretro

# --- RetroArch binary (Linux CLI vs macOS Homebrew cask app) ---
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
  # brew install --cask retroarch → /Applications/RetroArch.app
  RA_APP  ?= /Applications/RetroArch.app
  RA_BIN  ?= $(RA_APP)/Contents/MacOS/RetroArch
  # Fallback: Caskroom path if app not linked into /Applications
  ifeq ($(wildcard $(RA_BIN)),)
    RA_BIN := $(shell ls -d /opt/homebrew/Caskroom/retroarch/*/RetroArch.app/Contents/MacOS/RetroArch 2>/dev/null | tail -1)
  endif
  ifeq ($(wildcard $(RA_BIN)),)
    RA_BIN := $(shell ls -d /usr/local/Caskroom/retroarch/*/RetroArch.app/Contents/MacOS/RetroArch 2>/dev/null | tail -1)
  endif
else
  RA_BIN ?= retroarch
endif

all: $(NES) install

$(OBJ): $(SRC)
	mkdir -p $(BUILD)
	$(CC65) $(SRC) -o $(OBJ)

$(PRG): $(OBJ) $(CFG)
	$(LD65) -C $(CFG) $(OBJ) -o $(PRG)

# iNES: 1 PRG, 0 CHR (CHR-RAM), mapper 0, vertical mirroring (horizontal scroll)
$(HDR):
	mkdir -p $(BUILD)
	python3 -c "open('$(HDR)','wb').write(b'NES\x1a'+bytes([1,0,1,0])+bytes(8))"

$(NES): $(PRG) $(HDR)
	cat $(HDR) $(PRG) > $(NES)
	@echo "Built $(NES)"

# Symlink into a roms folder (absolute link — portable BSD/GNU ln)
install: $(NES)
	mkdir -p $(RA_NES)
	ln -sfn $(NES_ABS) $(RA_NES)/$(NAME).nes
	@echo "Available in RetroArch: $(RA_NES)/$(NAME).nes"

# Build and launch with Nestopia (override: make run RA_CORE=fceumm_libretro)
run: $(NES)
	@if [ ! -x "$(RA_BIN)" ] && ! command -v "$(RA_BIN)" >/dev/null 2>&1; then \
		echo "error: RetroArch not found."; \
		echo "  macOS: brew install --cask retroarch"; \
		echo "  Linux: install the retroarch package (CLI on PATH)"; \
		exit 1; \
	fi
	@echo "Launching: $(RA_BIN) -L $(RA_CORE) $(NES_ABS)"
	@echo "Tip: if the core is missing, in RetroArch use Online Updater → Core Downloader → Nestopia"
	"$(RA_BIN)" -L $(RA_CORE) "$(NES_ABS)"

clean:
	rm -rf $(BUILD)
	rm -f $(RA_NES)/$(NAME).nes

.PHONY: all install run clean
