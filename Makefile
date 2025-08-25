# Rosco Makefile
# Makes it easy to build and run Rosco from the command line

.PHONY: build run clean install help

# Default target
all: build

# Build the application
build:
	@echo "🔨 Building Rosco with code signing for macOS 15.4+ permissions..."
	@./build.sh

# Run the application
run:
	@echo "🚀 Running Rosco..."
	@./run.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf ./build
	@echo "✅ Clean completed"

# Install to Applications folder (optional)
install: build
	@echo "📦 Installing Rosco to Applications..."
	@cp -R ./build/Build/Products/Release/Rosco.app /Applications/
	@echo "✅ Installed to /Applications/Rosco.app"
	@echo "💡 You can now run Rosco from Spotlight or Launchpad"

# Show help
help:
	@echo "Rosco Build System"
	@echo ""
	@echo "Available commands:"
	@echo "  make build    - Build the application"
	@echo "  make run      - Run the application"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make install  - Install to Applications folder"
	@echo "  make help     - Show this help"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make build"
	@echo "  2. make run"