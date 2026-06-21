SHELL := /bin/bash
.ONESHELL:

.PHONY: help setup install-java install-flutter install-android-sdk accept-licenses install-deps clean build-apk build-apk-debug build-apk-split build-apk-all build-ios run test lint generate-icons

# Auto-load .env file (silently skip if missing)
DART_DEFINE := $(shell [ -f .env ] && echo "--dart-define-from-file=.env" || echo "")

FLUTTER_DIR := $(HOME)/flutter
ANDROID_SDK_DIR := $(HOME)/android-sdk

help:
	@echo "Study Progress Tracker - Flutter Build Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Install all required tools (Java, Flutter, Android SDK)"
	@echo "  make install-java   - Install Java 17 via SDKman"
	@echo "  make install-flutter - Install Flutter SDK"
	@echo "  make install-android-sdk - Install Android SDK + accept licenses"
	@echo "  make install-deps   - Install Flutter dependencies"
	@echo ""
	@echo "Build:"
	@echo "  make build-apk      - Build release APK for Android (universal)"
	@echo "  make build-apk-debug - Build debug APK for Android"
	@echo "  make build-apk-split - Build split APKs per architecture (arm64-v8a, armeabi-v7a, x86_64)"
	@echo "  make build-apk-all  - Build both universal and split APKs"
	@echo "  make build-ios      - Build iOS app (macOS only)"
	@echo ""
	@echo "Development:"
	@echo "  make run            - Run app in debug mode"
	@echo "  make test           - Run tests"
	@echo "  make lint           - Run Flutter analyze"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make generate-icons - Generate app icons from app_icon.png (1024×1024)"

setup: install-java install-flutter install-android-sdk accept-licenses install-deps
	@echo ""
	@echo "✓ Setup complete!"
	@echo "  Flutter:  $(FLUTTER_DIR)"
	@echo "  Android:  $(ANDROID_SDK_DIR)"
	@echo "  Java:     $$(java -version 2>&1 | head -1)"
	@echo ""
	@echo "Run 'source ~/.bashrc' or open a new shell to use Flutter."

install-java:
	@echo "==> Installing Java 17..."
	@if java -version 2>&1 | grep -q 'version "1[7-9]'; then \
		echo "Java 17+ already installed, skipping."; \
	elif command -v sdk >/dev/null 2>&1 || [ -f "$$SDKMAN_DIR/bin/sdkman-init.sh" ]; then \
		source "$${SDKMAN_DIR:-$$HOME/.sdkman}/bin/sdkman-init.sh" 2>/dev/null; \
		sdk install java 17.0.19-amzn || true; \
		sdk default java 17.0.19-amzn; \
	else \
		echo "Error: SDKman not found. Install it from https://sdkman.io"; \
		exit 1; \
	fi

install-flutter:
	@echo "==> Installing Flutter SDK..."
	@if [ -x "$(FLUTTER_DIR)/bin/flutter" ]; then \
		echo "Flutter already installed at $(FLUTTER_DIR)"; \
		export PATH="$(FLUTTER_DIR)/bin:$$PATH"; \
		flutter upgrade 2>/dev/null || true; \
	else \
		curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.2-stable.tar.xz \
			-o /tmp/flutter.tar.xz; \
		tar xf /tmp/flutter.tar.xz -C "$(HOME)"; \
		rm -f /tmp/flutter.tar.xz; \
	fi
	@# Add to PATH and set env vars
	@touch ~/.bashrc
	@grep -q "flutter/bin" ~/.bashrc 2>/dev/null || echo 'export PATH="$(FLUTTER_DIR)/bin:$$PATH"' >> ~/.bashrc
	@grep -q "ANDROID_HOME" ~/.bashrc 2>/dev/null || echo 'export ANDROID_HOME="$(ANDROID_SDK_DIR)"' >> ~/.bashrc
	@grep -q "platform-tools" ~/.bashrc 2>/dev/null || echo 'export PATH="$$ANDROID_HOME/platform-tools:$$PATH"' >> ~/.bashrc
	@export PATH="$(FLUTTER_DIR)/bin:$$PATH"
	flutter config --no-analytics 2>/dev/null || true

install-android-sdk:
	@echo "==> Installing Android SDK..."
	@if [ -x "$(ANDROID_SDK_DIR)/cmdline-tools/latest/bin/sdkmanager" ]; then \
		echo "Android SDK already installed at $(ANDROID_SDK_DIR)"; \
	else \
		mkdir -p "$(ANDROID_SDK_DIR)"; \
		curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
			-o /tmp/android-cmd.zip; \
		unzip -q /tmp/android-cmd.zip -d /tmp/android-cmd-tmp; \
		mkdir -p "$(ANDROID_SDK_DIR)/cmdline-tools"; \
		mv /tmp/android-cmd-tmp/cmdline-tools "$(ANDROID_SDK_DIR)/cmdline-tools/latest"; \
		rm -rf /tmp/android-cmd.zip /tmp/android-cmd-tmp; \
	fi
	@export ANDROID_HOME="$(ANDROID_SDK_DIR)"
	@export PATH="$(ANDROID_SDK_DIR)/cmdline-tools/latest/bin:$$PATH"
	@yes | sdkmanager --sdk_root="$(ANDROID_SDK_DIR)" \
		"platform-tools" \
		"platforms;android-35" \
		"build-tools;35.0.0" 2>/dev/null || true

accept-licenses:
	@echo "==> Accepting Android licenses..."
	@export PATH="$(FLUTTER_DIR)/bin:$(ANDROID_SDK_DIR)/cmdline-tools/latest/bin:$$PATH"
	@export ANDROID_HOME="$(ANDROID_SDK_DIR)"
	@yes | flutter doctor --android-licenses 2>/dev/null || true

install-deps:
	@echo "==> Installing Flutter dependencies..."
	@export PATH="$(FLUTTER_DIR)/bin:$$PATH"
	@export ANDROID_HOME="$(ANDROID_SDK_DIR)"
	@flutter pub get

clean:
	@echo "Cleaning build artifacts..."
	@flutter clean
	@rm -rf build/

lint:
	@echo "Running Flutter analyze..."
	@flutter analyze

build-apk: install-deps
	@echo "Building universal release APK..."
	@flutter build apk --release $(DART_DEFINE)
	@echo ""
	@echo "✓ Universal APK built successfully!"
	@echo "Location: build/app/outputs/flutter-apk/app-release.apk"

build-apk-debug: install-deps
	@echo "Building debug APK..."
	@flutter build apk --debug $(DART_DEFINE)
	@echo ""
	@echo "✓ Debug APK built successfully!"
	@echo "Location: build/app/outputs/flutter-apk/app-debug.apk"

build-apk-split: install-deps
	@echo "Building split APKs per architecture (one at a time to avoid OOM)..."
	@flutter build apk --release --split-per-abi --target-platform android-arm64 --no-tree-shake-icons $(DART_DEFINE)
	@flutter build apk --release --split-per-abi --target-platform android-arm --no-tree-shake-icons $(DART_DEFINE)
	@echo ""
	@echo "✓ Split APKs built successfully!"
	@echo "Locations:"
	@echo "  - arm64-v8a:    build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
	@echo "  - armeabi-v7a:  build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
	@echo "  - x86_64:       build/app/outputs/flutter-apk/app-x86_64-release.apk"

build-apk-all: install-deps
	@echo "Building all APK variants (one at a time to avoid OOM)..."
	@flutter build apk --release --no-tree-shake-icons $(DART_DEFINE)
	@flutter build apk --release --split-per-abi --target-platform android-arm64 --no-tree-shake-icons $(DART_DEFINE)
	@flutter build apk --release --split-per-abi --target-platform android-arm --no-tree-shake-icons $(DART_DEFINE)
	@flutter build apk --release --split-per-abi --target-platform android-x64 --no-tree-shake-icons $(DART_DEFINE)
	@echo ""
	@echo "✓ All APKs built successfully!"
	@echo ""
	@echo "Universal APK:"
	@echo "  - build/app/outputs/flutter-apk/app-release.apk"
	@echo ""
	@echo "Split APKs:"
	@echo "  - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
	@echo "  - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
	@echo "  - build/app/outputs/flutter-apk/app-x86_64-release.apk"

build-ios: install-deps
	@echo "Building iOS app..."
	@flutter build ios --release $(DART_DEFINE)
	@echo ""
	@echo "✓ iOS app built successfully!"

run: install-deps
	@echo "Running app in debug mode..."
	@flutter run $(DART_DEFINE)

test:
	@echo "Running tests..."
	@flutter test

generate-icons: install-deps
	@echo "Generating app icons from logo.png..."
	@if [ ! -f logo.png ]; then \
		echo "Error: logo.png not found in project root."; \
		echo "Place a PNG there and re-run."; \
		exit 1; \
	fi
	@dart run flutter_launcher_icons
	@echo ""
	@echo "✓ App icons generated for Android!"
