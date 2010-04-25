PACKAGE = slide

PROJECT = $(PACKAGE)
TARGETS = $(PROJECT)

PROJECT_OBJS = \
	index.html \
	logo.png

OBJS = $(PROJECT_OBJS)
SRCS = $(OBJS:.html=.txt)

.PHONY: all clean

MKSLIDE := bin/mkslide.pl
MKSLIDE_LOGO := bin/mkslide-logo.pl

all: $(TARGETS)

clean:
	rm -rf *~ $(PROJECT_OBJS)

%.html: %.txt $(MKSLIDE)
	$(MKSLIDE) $< > $@

$(PROJECT): $(PROJECT_OBJS)

logo.png: slide.conf $(MKSLIDE_LOGO)
	$(MKSLIDE_LOGO) > $@
