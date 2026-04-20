BINARY := icli
BINDIR ?= $(HOME)/.local/bin

.PHONY: build install clean

build:
	swift build -c release

install: build
	mkdir -p "$(BINDIR)"
	install -m 755 .build/release/$(BINARY) "$(BINDIR)/$(BINARY)"
	codesign --force --sign "Apple Development: reda@4rays.net (27HKAKXURP)" --options runtime --entitlements icli.entitlements "$(BINDIR)/$(BINARY)"

clean:
	rm -rf .build
