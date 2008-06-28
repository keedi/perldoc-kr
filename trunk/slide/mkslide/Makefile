PACKAGE = slide

PROJECT = $(PACKAGE)
TARGETS = $(PROJECT)

PROJECT_OBJS = \
	index.html \

OBJS = $(PROJECT_OBJS)
SRCS = $(OBJS:.html=.txt)

.PHONY: all clean

MKSLIDE := bin/mkslide.pl

all: $(TARGETS)

clean:
	rm -rf *~ $(PROJECT_OBJS)

ifeq ($(V),1)
MSG_G=
MSG_C=
MSG_L=
PREFIX=
else
MSG_G=@echo "[G] $@ ..."
MSG_C=@echo "[C] $@ ..."
MSG_L=@echo "[L] $@ ..."
PREFIX=@
endif

%.html: %.txt
	$(MSG_C)
	$(MKSLIDE) $< > $@

$(PROJECT): $(PROJECT_OBJS)
