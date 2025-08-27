REPO_DIR := $(shell pwd)
BUILD_DIR := $(REPO_DIR)/build
DIST_DIR := $(REPO_DIR)/dist/bin
GO := go
CMAKE := cmake

# Get version from git if VERSION is not set
VERSION ?= $(shell git describe --tags --first-parent --abbrev=7 --long --dirty --always | sed -e "s/^v//g")

# Go ldflags
GO_LDFLAGS := -w -s \
	-X=github.com/ollama/ollama/version.Version=$(VERSION) \
	-X=github.com/ollama/ollama/server.mode=release

.PHONY: all cpu vulkan ollama clean

all: cpu vulkan ollama

cpu:
	@echo "Building CPU variant..."
	$(CMAKE) --preset CPU
	$(CMAKE) --build --parallel --preset CPU
	$(CMAKE) --install $(BUILD_DIR) --component CPU --strip

vulkan:
	@echo "Building Vulkan variant..."
	$(CMAKE) --preset Vulkan
	$(CMAKE) --build --parallel --preset Vulkan
	$(CMAKE) --install $(BUILD_DIR) --component Vulkan --strip

ollama:
	@echo "Building final Ollama binary (version $(VERSION))..."
	source scripts/env.sh || true
	mkdir -p $(DIST_DIR)
	$(GO) build -ldflags="$(GO_LDFLAGS)" -trimpath -buildmode=pie -o $(DIST_DIR)/ollama .
	sudo setcap cap_perfmon=ep "$(DIST_DIR)/ollama"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR) $(DIST_DIR)
