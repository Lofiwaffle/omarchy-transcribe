#!/bin/bash

# Installation script for Omarchy Transcribe
# This script will guide you through installing all dependencies

set -e  # Exit on error

WHISPER_DIR="$HOME/whisper.cpp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Omarchy Transcribe Installation ===${NC}\n"

# Check for pacman (Arch Linux)
if ! command -v pacman &> /dev/null; then
    echo -e "${RED}Error: This script is designed for Arch Linux (Omarchy)${NC}"
    echo "Please install dependencies manually. See README.md"
    exit 1
fi

# Step 1: Install system dependencies
echo -e "${BLUE}[1/5] Checking system dependencies...${NC}"

MISSING_PACKAGES=()

# Check for required packages
if ! pacman -Qq base-devel &> /dev/null; then
    MISSING_PACKAGES+=("base-devel")
fi

if ! command -v git &> /dev/null; then
    MISSING_PACKAGES+=("git")
fi

if ! command -v arecord &> /dev/null; then
    MISSING_PACKAGES+=("alsa-utils")
fi

if ! command -v wl-copy &> /dev/null; then
    MISSING_PACKAGES+=("wl-clipboard")
fi

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All system dependencies already installed${NC}\n"
else
    echo -e "${BLUE}Installing missing packages: ${MISSING_PACKAGES[*]}${NC}"
    sudo pacman -S --noconfirm "${MISSING_PACKAGES[@]}"
    echo -e "${GREEN}✓ System dependencies installed${NC}\n"
fi

# Step 2: Install whisper.cpp
echo -e "${BLUE}[2/5] Installing whisper.cpp...${NC}"

if [ -d "$WHISPER_DIR" ]; then
    echo -e "${YELLOW}whisper.cpp already exists at $WHISPER_DIR${NC}"
    read -p "Do you want to reinstall it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$WHISPER_DIR"
    else
        echo "Skipping whisper.cpp installation"
    fi
fi

if [ ! -d "$WHISPER_DIR" ]; then
    echo "Cloning whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp "$WHISPER_DIR"

    echo "Building whisper.cpp..."
    cd "$WHISPER_DIR"
    make

    echo -e "${GREEN}✓ whisper.cpp installed${NC}\n"
else
    echo -e "${GREEN}✓ Using existing whisper.cpp installation${NC}\n"
fi

# Step 3: Download Whisper model
echo -e "${BLUE}[3/5] Downloading Whisper model...${NC}"

MODEL_FILE="$WHISPER_DIR/models/ggml-small.en.bin"
if [ -f "$MODEL_FILE" ]; then
    echo -e "${YELLOW}Model already exists: $MODEL_FILE${NC}"
    read -p "Do you want to re-download it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping model download"
        echo -e "${GREEN}✓ Using existing model${NC}\n"
    else
        cd "$WHISPER_DIR"
        bash ./models/download-ggml-model.sh small.en
        echo -e "${GREEN}✓ Model downloaded${NC}\n"
    fi
else
    cd "$WHISPER_DIR"
    bash ./models/download-ggml-model.sh small.en
    echo -e "${GREEN}✓ Model downloaded${NC}\n"
fi

# Step 4: Install llm CLI
echo -e "${BLUE}[4/5] Installing llm CLI...${NC}"

if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
    PIP_CMD=$(command -v pip3 &> /dev/null && echo "pip3" || echo "pip")

    if command -v llm &> /dev/null; then
        echo -e "${GREEN}✓ llm CLI already installed${NC}"
    else
        echo "Installing llm..."
        $PIP_CMD install --user llm
        echo -e "${GREEN}✓ llm CLI installed${NC}"
    fi

    # Check if Anthropic plugin is installed
    if llm plugins 2>/dev/null | grep -q "llm-anthropic"; then
        echo -e "${GREEN}✓ llm-anthropic plugin already installed${NC}"
    else
        echo "Installing llm-anthropic plugin..."
        llm install llm-anthropic
        echo -e "${GREEN}✓ llm-anthropic plugin installed${NC}"
    fi

    # Check if API key is configured
    if llm keys get anthropic &> /dev/null; then
        echo -e "${GREEN}✓ Anthropic API key already configured${NC}"
    else
        echo -e "${YELLOW}Anthropic API key not configured${NC}"
        echo "You'll need an API key from https://console.anthropic.com/"
        read -p "Do you want to set your API key now? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            llm keys set anthropic
        else
            echo -e "${YELLOW}You can set it later with: llm keys set anthropic${NC}"
        fi
    fi

    echo -e "${GREEN}✓ llm CLI installed${NC}\n"
else
    echo -e "${RED}Error: pip not found${NC}"
    echo "Please install Python and pip first"
    exit 1
fi

# Step 5: Install transcribe script
echo -e "${BLUE}[5/5] Installing transcribe script and Hyprland config...${NC}"

mkdir -p ~/.local/bin

if [ -f ~/.local/bin/omarchy-transcribe ]; then
    echo -e "${YELLOW}omarchy-transcribe script already exists${NC}"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping script installation"
    else
        cp "$SCRIPT_DIR/transcribe.sh" ~/.local/bin/omarchy-transcribe
        chmod +x ~/.local/bin/omarchy-transcribe
        echo -e "${GREEN}✓ Script installed to ~/.local/bin/omarchy-transcribe${NC}"
    fi
else
    cp "$SCRIPT_DIR/transcribe.sh" ~/.local/bin/omarchy-transcribe
    chmod +x ~/.local/bin/omarchy-transcribe
    echo -e "${GREEN}✓ Script installed to ~/.local/bin/omarchy-transcribe${NC}"
fi

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}Warning: ~/.local/bin is not in your PATH${NC}"
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Install Hyprland config
mkdir -p ~/.config/hypr

if [ -f ~/.config/hypr/transcribe.conf ]; then
    echo -e "${YELLOW}Hyprland transcribe.conf already exists${NC}"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$SCRIPT_DIR/transcribe.conf" ~/.config/hypr/transcribe.conf
        echo -e "${GREEN}✓ Hyprland config copied to ~/.config/hypr/transcribe.conf${NC}"
    fi
else
    cp "$SCRIPT_DIR/transcribe.conf" ~/.config/hypr/transcribe.conf
    echo -e "${GREEN}✓ Hyprland config copied to ~/.config/hypr/transcribe.conf${NC}"
fi

# Add source line to hyprland.conf if not already present
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
SOURCE_LINE="source = ~/.config/hypr/transcribe.conf"

if [ -f "$HYPRLAND_CONF" ]; then
    if grep -qF "$SOURCE_LINE" "$HYPRLAND_CONF"; then
        echo -e "${GREEN}✓ Hyprland config already sources transcribe.conf${NC}"
    else
        echo -e "${BLUE}Adding source line to hyprland.conf...${NC}"
        echo "" >> "$HYPRLAND_CONF"
        echo "# Transcribe hotkey and window config" >> "$HYPRLAND_CONF"
        echo "$SOURCE_LINE" >> "$HYPRLAND_CONF"
        echo -e "${GREEN}✓ Added source line to hyprland.conf${NC}"
        echo -e "${YELLOW}Note: Reload Hyprland config with: hyprctl reload${NC}"
    fi
else
    echo -e "${YELLOW}Warning: ~/.config/hypr/hyprland.conf not found${NC}"
    echo "Create it and add this line:"
    echo "    $SOURCE_LINE"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Reload Hyprland config: hyprctl reload"
echo "2. Test the script by pressing SUPER+D"
echo ""
echo -e "${BLUE}Press SUPER+D to start transcribing!${NC}"
