# various directories
BUILDDIR ?= build
# port for local http server
PORT ?= 2026

# default target
TARGET ?= $(BUILDDIR)/bcard.pdf
SRC += $(TARGET:$(BUILDDIR)/%.pdf=%.tex)
SRC += littlefs-ico.tex
SRC += littlefs-ico-back.tex
SRC += littlefs-ico-back-2.tex


# fix timestamps to try to preserve current page in pdf viewers
#
# https://github.com/mozilla/pdf.js/issues/11359#issuecomment-558841393
#
export SOURCE_DATE_EPOCH ?= 0

# pdflatex
PDFLATEX ?= pdflatex
PDFLATEXFLAGS += -output-directory=$(BUILDDIR)
PDFLATEXFLAGS += -file-line-error
PDFLATEXFLAGS += -interaction=nonstopmode
PDFLATEXFLAGS += -halt-on-error

# bibtex
BIBTEX ?= bibtex

# wristwatch script
WRISTWATCH ?= ./scripts/wristwatch.py
WRISTWATCHFLAGS += -I$(BUILDDIR)
WRISTWATCHFLAGS += -I$(BENCHMARKSDIR)
WRISTWATCHFLAGS += -w0.5
ifdef VERBOSE
WRISTWATCHFLAGS += -v
endif


# this is a bit of a hack, but we want to make sure BUILDDIR exists
# before running any commands
ifneq ($(BUILDDIR),.)
$(if $(findstring n,$(MAKEFLAGS)),, $(shell mkdir -p $(BUILDDIR)))
endif


## Build things, may need to build ~3x to resolve refs!
.PHONY: all build
all build: $(TARGET)

## Find word counts
.PHONY: count
count:
	texcount $(SRC)

## Edit the main document
# this is really just an example of explicitly loading the .vimrc
.PHONY: vim
vim:
	vim -S .vimrc $(firstword $(SRC))

# build .pdf from .tex
$(TARGET): $(TARGET:$(BUILDDIR)/%.pdf=%.tex) $(SRC)
	$(PDFLATEX) $(PDFLATEXFLAGS) $<

## Run a local server
.PHONY: serve server
serve server:
	python -m http.server $(PORT)

## Rebuild on changes
.PHONY: watch
watch:
	$(WRISTWATCH) $(WRISTWATCHFLAGS) make

## Run a local server and rebuild on changes
.PHONY: watch-serve watch-server
watch-serve watch-server:
	$(WRISTWATCH) $(WRISTWATCHFLAGS) -s:$(PORT) make

## Show this help text
.PHONY: help
help:
	@$(strip awk '/^## / { \
			sub(/^## /,""); \
			getline rule; \
			while (rule ~ /^(#|\.PHONY|ifdef|ifndef)/) getline rule; \
			gsub(/:.*/, "", rule); \
			if (length(rule) <= 21) { \
			    printf "%2s%-21s %s\n", "", rule, $$0; \
			} else { \
			    printf "%2s%s\n", "", rule; \
			    printf "%24s%s\n", "", $$0; \
			} \
		}' $(MAKEFILE_LIST))


## Clean everything
.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

