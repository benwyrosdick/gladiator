# VESYL Shipper NES — requires cc65 (ca65, ld65) and python3
# make / make clean

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

all: $(NES)

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

clean:
	rm -rf $(BUILD)

.PHONY: all clean
