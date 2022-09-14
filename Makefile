DESTDIR ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

ifndef MANPREFIX
  MANPREFIX = $(PREFIX)/share/man
endif

all:
	@echo "Rs is a shell script, so there is nothing to do. Try \"make install\" instead."

install:
	install -v -d "$(DESTDIR)$(BINDIR)/" && install -m 0755 -v rsync-script.sh "$(DESTDIR)$(BINDIR)/rs"
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	cp -f rs.1 $(DESTDIR)$(MANPREFIX)/man1/rs.1
