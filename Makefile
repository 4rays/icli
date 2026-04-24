BINARY := icli
APP_NAME := iCLI.app
SHARED_FRAMEWORK := Shared.framework
APP_PROCESS := iCLI
OLD_COMPANION_PROCESS := icliCompanion
SOCKET_FILE := $(HOME)/Library/Application Support/icli/companion.sock
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBEXECDIR ?= $(PREFIX)/lib/icli
DERIVED_DATA := .build/xcode
CONFIGURATION ?= Release
NATIVE_ARCH := $(shell uname -m)
XCODE_DESTINATION ?= platform=macOS,arch=$(NATIVE_ARCH)
PRODUCTS_DIR := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)
BUILT_CLI := $(PRODUCTS_DIR)/$(BINARY)
BUILT_APP := $(PRODUCTS_DIR)/$(APP_NAME)
BUILT_SHARED := $(PRODUCTS_DIR)/$(SHARED_FRAMEWORK)
INSTALL_APP := $(LIBEXECDIR)/$(APP_NAME)
INSTALL_SHARED := $(LIBEXECDIR)/$(SHARED_FRAMEWORK)

.PHONY: generate build install uninstall clean

generate:
	@echo "Generating Xcode workspace..."
	@tuist generate --no-open

build: generate
	@echo "Building iCLI app..."
	@xcodebuild -workspace iCLI.xcworkspace -scheme iCLI -configuration "$(CONFIGURATION)" -destination "$(XCODE_DESTINATION)" -derivedDataPath "$(DERIVED_DATA)" -quiet build
	@echo "Building icli CLI..."
	@xcodebuild -workspace iCLI.xcworkspace -scheme icli -configuration "$(CONFIGURATION)" -destination "$(XCODE_DESTINATION)" -derivedDataPath "$(DERIVED_DATA)" -quiet build

install: build
	@echo "Installing icli to $(LIBEXECDIR)..."
	@pkill -x "$(APP_PROCESS)" 2>/dev/null || true
	@pkill -x "$(OLD_COMPANION_PROCESS)" 2>/dev/null || true
	@rm -f "$(SOCKET_FILE)"
	@mkdir -p "$(BINDIR)" "$(LIBEXECDIR)"
	@test -x "$(BUILT_CLI)" || (echo "Missing built CLI: $(BUILT_CLI)" && exit 1)
	@test -d "$(BUILT_APP)" || (echo "Missing built app: $(BUILT_APP)" && exit 1)
	@test -d "$(BUILT_SHARED)" || (echo "Missing shared framework: $(BUILT_SHARED)" && exit 1)
	@install -m 755 "$(BUILT_CLI)" "$(LIBEXECDIR)/$(BINARY)"
	@rm -rf "$(INSTALL_APP)"
	@cp -R "$(BUILT_APP)" "$(INSTALL_APP)"
	@rm -rf "$(INSTALL_SHARED)"
	@cp -R "$(BUILT_SHARED)" "$(INSTALL_SHARED)"
	@ln -sf "$(LIBEXECDIR)/$(BINARY)" "$(BINDIR)/$(BINARY)"
	@echo "Installed $(BINARY), $(APP_NAME), and $(SHARED_FRAMEWORK)."

uninstall:
	@echo "Uninstalling icli..."
	@pkill -x "$(APP_PROCESS)" 2>/dev/null || true
	@pkill -x "$(OLD_COMPANION_PROCESS)" 2>/dev/null || true
	@rm -f "$(SOCKET_FILE)"
	@rm -f "$(BINDIR)/$(BINARY)"
	@rm -rf "$(LIBEXECDIR)"
	@echo "Uninstalled icli."

clean:
	@rm -rf .build
