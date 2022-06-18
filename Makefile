DESTDIR ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

all:
	@echo "Rs is a shell script, so there is nothing to do. Try \"make install\" instead."

install:
	install -v -d "$(DESTDIR)$(BINDIR)/" && install -m 0755 -v rsync-script.sh "$(DESTDIR)$(BINDIR)/rs"
