.PHONY: help setup install-deps clean build-apk build-apk-debug build-apk-split build-apk-all build-ios run test lint

# Auto-load .env file (silently skip if missing)
DART_DEFINE := $(shell [ -f .env ] && echo "--dart-define-from-file=.env" || echo "")

help:
	@echo "Study Progress Tracker - Flutter Build Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Install all required tools (Flutter, Java, Android SDK)"
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

setup:
	@echo "Installing required tools..."
	@chmod +x setup.sh 2>/dev/null || true
	@if command -v flutter >/dev/null 2>&1; then \
		echo "Flutter already installed"; \
	else \
		echo "Please install Flutter from https://flutter.dev"; \
	fi
	@if command -v java >/dev/null 2>&1; then \
		echo "Java already installed"; \
	else \
		echo "Please install Java 17+ from https://adoptium.net"; \
	fi
	@echo "Setup complete. Ensure ANDROID_HOME is set for Android builds."

install-deps:
	@echo "Installing Flutter dependencies..."
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
	@echo "Building split APKs per architecture..."
	@export PATH="/home/codespace/flutter/bin:$PATH" && export ANDROID_HOME=/home/codespace/android-sdk && export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx2g" && flutter build apk --release --split-per-abi --dart-define-from-file=.env
# 	GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx2g" \
# 	flutter build apk --release --split-per-abi $(DART_DEFINE)
	@echo ""
	@echo "✓ Split APKs built successfully!"
	@echo "Locations:"
	@echo "  - arm64-v8a:    build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
	@echo "  - armeabi-v7a:  build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
	@echo "  - x86_64:       build/app/outputs/flutter-apk/app-x86_64-release.apk"

build-apk-all: install-deps
	@echo "Building all APK variants..."
	@flutter build apk --release $(DART_DEFINE) && \
	flutter build apk --release --split-per-abi $(DART_DEFINE)
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
