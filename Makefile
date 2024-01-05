# Makefile for Isolate
# (c) 2015--2023 Martin Mares <mj@ucw.cz>
# (c) 2017 Bernard Blackham <bernard@blackham.com.au>

all: isolate isolate.1 isolate.1.html isolate-check-environment

CC=gcc
CFLAGS=-std=gnu99 -Wall -Wextra -Wno-parentheses -Wno-unused-result -Wno-missing-field-initializers -Wstrict-prototypes -Wmissing-prototypes -D_GNU_SOURCE
LIBS=-lcap

VERSION=1.10.1
YEAR=2023
BUILD_DATE:=$(shell date '+%Y-%m-%d')
BUILD_COMMIT:=$(shell if git rev-parse >/dev/null 2>/dev/null ; then git describe --always --tags ; else echo '<unknown>' ; fi)

PREFIX = $(DESTDIR)/usr/local
VARPREFIX = $(DESTDIR)/var/local
CONFIGDIR = $(PREFIX)/etc
CONFIG = $(CONFIGDIR)/isolate
BINDIR = $(PREFIX)/bin
DATAROOTDIR = $(PREFIX)/share
DATADIR = $(DATAROOTDIR)
MANDIR = $(DATADIR)/man
MAN1DIR = $(MANDIR)/man1
BOXDIR = $(VARPREFIX)/lib/isolate

LDFLAGS += -g
CFLAGS += -g

isolate: isolate.o util.o rules.o cg.o config.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

%.o: %.c isolate.h
	$(CC) $(CFLAGS) -c -o $@ $<

isolate.o: CFLAGS += -DVERSION='"$(VERSION)"' -DYEAR='"$(YEAR)"' -DBUILD_DATE='"$(BUILD_DATE)"' -DBUILD_COMMIT='"$(BUILD_COMMIT)"'

# -DCONFIG_FILE='"$(CONFIG)"': define macro in compiling
config.o: CFLAGS += -DCONFIG_FILE='"$(CONFIG)"'

isolate.1: isolate.1.txt
	a2x -f manpage $<

# The dependency on isolate.1 is there to serialize both calls of asciidoc,
# which does not name temporary files safely.
isolate.1.html: isolate.1.txt isolate.1
	a2x -f xhtml -D . $<

clean:
	rm -f *.o
	rm -f isolate isolate.1 isolate.1.html
	rm -f docbook-xsl.css

install: isolate isolate-check-environment
	install -d $(BINDIR) $(BOXDIR) $(CONFIGDIR)
	install isolate-check-environment $(BINDIR)
	# 前导数字（4）：这是一个特殊的权限设置，称为“Set-User-ID”（SUID）位。当这个位被设置在可执行文件上时，无论谁运行该文件，该文件都会以文件所有者的权限运行。这对于需要临时提升权限以执行特定操作的程序（如密码更改工具）很有用。
	install -m 4755 isolate $(BINDIR)
	install -m 644 default.cf $(CONFIG)

install-doc: isolate.1
	install -d $(MAN1DIR)
	install -m 644 $< $(MAN1DIR)/$<

release: isolate.1.html
	git tag v$(VERSION)
	git push --tags
	git archive --format=tar --prefix=isolate-$(VERSION)/ HEAD | gzip >isolate-$(VERSION).tar.gz
	rsync isolate-$(VERSION).tar.gz jw:/home/ftp/pub/mj/isolate/
	rsync isolate.1.html jw:/var/www/moe/
	ssh jw 'cd web && bin/release-prog isolate $(VERSION)'

.PHONY: all clean install install-doc release
