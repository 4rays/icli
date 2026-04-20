BINARY := icli
COMPANION_BINARY := icliCompanion
COMPANION_APP_NAME := iCLI Companion.app
COMPANION_INFO_PLIST := Sources/icliCompanion/Resources/Info.plist
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBEXECDIR ?= $(PREFIX)/lib/icli
SIGN_IDENTITY ?= Apple Development: reda@4rays.net (27HKAKXURP)
BUILD_COMPANION_APP := .build/release/$(COMPANION_APP_NAME)
INSTALL_COMPANION_APP := $(LIBEXECDIR)/$(COMPANION_APP_NAME)

.PHONY: build package-companion install clean

build:
	swift build -c release
	$(MAKE) package-companion

package-companion:
	rm -rf "$(BUILD_COMPANION_APP)"
	mkdir -p "$(BUILD_COMPANION_APP)/Contents/MacOS"
	install -m 755 ".build/release/$(COMPANION_BINARY)" "$(BUILD_COMPANION_APP)/Contents/MacOS/$(COMPANION_BINARY)"
	install -m 644 "$(COMPANION_INFO_PLIST)" "$(BUILD_COMPANION_APP)/Contents/Info.plist"

install: build
	mkdir -p "$(BINDIR)" "$(LIBEXECDIR)"
	install -m 755 ".build/release/$(BINARY)" "$(LIBEXECDIR)/$(BINARY)"
	rm -rf "$(INSTALL_COMPANION_APP)"
	mkdir -p "$(INSTALL_COMPANION_APP)"
	cp -R "$(BUILD_COMPANION_APP)/." "$(INSTALL_COMPANION_APP)/"
	ln -sf "$(LIBEXECDIR)/$(BINARY)" "$(BINDIR)/$(BINARY)"
	codesign --force --sign "$(SIGN_IDENTITY)" --options runtime "$(LIBEXECDIR)/$(BINARY)"
	codesign --force --deep --sign "$(SIGN_IDENTITY)" --options runtime --entitlements icli.entitlements "$(INSTALL_COMPANION_APP)"

clean:
	rm -rf .build
