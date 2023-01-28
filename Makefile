# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2023 Gaëtan Rivet

O ?= $(HOME)
O := $(abspath $(O))

ifeq ($(V),)
Q := @
else
Q := 
endif

EXCLUDED_FILES := . .. .git .gitignore .gitmodules
FILES := $(filter-out $(EXCLUDED_FILES),$(sort $(wildcard .*)))

LINKS := $(shell [ -d $O ] && find $O -maxdepth 1 -type l -exec readlink -f {} \; | grep '^$(CURDIR)')

# Files that exists in CURDIR but are missing from O
MISSING_FILES := $(filter-out $(patsubst $(CURDIR)/%,%,$(LINKS)), $(FILES))

# Files that exists in CURDIR and are linked from O
INSTALLED_FILES := $(filter-out $(MISSING_FILES), $(FILES))

# Files that do not exist in CURDIR anymore, but are linked from O
REMAINING_FILES := $(filter-out $(FILES), $(patsubst $(CURDIR)/%,%,$(LINKS)))

ADD_DOTFILES := $(addprefix $(O)/, $(MISSING_FILES))
RM_DOTFILES := $(addprefix rm-, $(REMAINING_FILES))

all: sync

sync: $(ADD_DOTFILES) $(RM_DOTFILES)

define dotrule
$(O)/$(1): $(1) | mkdir-O
	ln -sfn $(shell readlink -f $(1)) $(O)/$(1)
endef
$(foreach f, $(FILES), $(eval $(call dotrule,$f)))

mkdir-O:
	$Qmkdir -p $(O)

.PHONY: rm-%
rm-%:
	$Qrm -f $(O)/$(@:rm-%=%)

.PHONY: list
list:
	@printf "Dotfiles correctly linked:\n"
	@printf "$(addprefix "\\t", $(addsuffix "\\n", $(INSTALLED_FILES)))"
	@printf "Dotfiles not linked:\n"
	@printf "$(addprefix "\\t", $(addsuffix "\\n", $(MISSING_FILES)))"
	@printf "Dotfiles remaining:\n"
	@printf "$(addprefix "\\t", $(addsuffix "\\n", $(REMAINING_FILES)))"

.PHONY: clean
clean: $(RM_DOTFILES)
	$Qrm -f $(addprefix $(O)/, $(INSTALLED_FILES))
