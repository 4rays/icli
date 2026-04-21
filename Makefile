BINARY := icli
COMPANION_BINARY := icliCompanion
COMPANION_APP_NAME := iCLI Companion.app
COMPANION_INFO_PLIST := Sources/icliCompanion/Resources/Info.plist
SOCKET_FILE := $(HOME)/Library/Application Support/icli/companion.sock
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBEXECDIR ?= $(PREFIX)/lib/icli
SIGN_IDENTITY ?= Apple Development: reda@4rays.net (27HKAKXURP)
BUILD_COMPANION_APP := .build/release/$(COMPANION_APP_NAME)
INSTALL_COMPANION_APP := $(LIBEXECDIR)/$(COMPANION_APP_NAME)

.PHONY: build package-companion install uninstall clean

build:
	@echo "Building icli..."
	@swift build -c release
	@$(MAKE) --no-print-directory package-companion

package-companion:
	@echo "Packaging companion app..."
	@rm -rf "$(BUILD_COMPANION_APP)"
	@mkdir -p "$(BUILD_COMPANION_APP)/Contents/MacOS"
	@install -m 755 ".build/release/$(COMPANION_BINARY)" "$(BUILD_COMPANION_APP)/Contents/MacOS/$(COMPANION_BINARY)"
	@install -m 644 "$(COMPANION_INFO_PLIST)" "$(BUILD_COMPANION_APP)/Contents/Info.plist"

install: build
	@echo "Installing icli to $(LIBEXECDIR)..."
	@pkill -x "$(COMPANION_BINARY)" 2>/dev/null || true
	@rm -f "$(SOCKET_FILE)"
	@mkdir -p "$(BINDIR)" "$(LIBEXECDIR)"
	@install -m 755 ".build/release/$(BINARY)" "$(LIBEXECDIR)/$(BINARY)"
	@rm -rf "$(INSTALL_COMPANION_APP)"
	@mkdir -p "$(INSTALL_COMPANION_APP)"
	@cp -R "$(BUILD_COMPANION_APP)/." "$(INSTALL_COMPANION_APP)/"
	@ln -sf "$(LIBEXECDIR)/$(BINARY)" "$(BINDIR)/$(BINARY)"
	@codesign --force --sign "$(SIGN_IDENTITY)" --options runtime "$(LIBEXECDIR)/$(BINARY)" >/dev/null
	@codesign --force --deep --sign "$(SIGN_IDENTITY)" --options runtime "$(INSTALL_COMPANION_APP)" >/dev/null
	@echo "Installed $(BINARY) and $(COMPANION_APP_NAME)."

uninstall:
	@echo "Uninstalling icli..."
	@pkill -x "$(COMPANION_BINARY)" 2>/dev/null || true
	@rm -f "$(SOCKET_FILE)"
	@rm -f "$(BINDIR)/$(BINARY)"
	@rm -rf "$(LIBEXECDIR)"
	@echo "Uninstalled icli."

clean:
	@rm -rf .build
