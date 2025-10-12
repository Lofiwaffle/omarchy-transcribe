# Omarchy Transcribe

A simple bash script for quick voice-to-text transcription using whisper.cpp. Press a hotkey to start recording, then choose how to transform the text - it copies directly to your clipboard.

## Features

- **Quick recording**: Start with a hotkey, stop with any key press
- **Multiple transformation modes**:
  - Raw text (mode `d`)
  - Structured document with headings and bullet points (mode `s`)
  - Clean/format text with proper punctuation (mode `c`)
- **Clipboard integration**: Transcribed text automatically copies to clipboard
- **LLM-powered transformations**: Uses Claude via the `llm` CLI for text processing

## What This Does

1. Starts audio recording when you run the script
2. Stops recording when you press a key (d/s/c/ESC)
3. Transcribes the audio using whisper.cpp
4. Applies the selected transformation using Claude
5. Copies the result to your clipboard
6. Displays the transcribed text

## Installation

### Quick Install (Recommended)

Run the automated installation script:

```bash
bash install.sh
```

This will install all dependencies and set up the transcription script.

### Manual Installation

#### 1. Install whisper.cpp

```bash
# Clone whisper.cpp
cd ~
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp

# Build
make

# Download the small.en model (recommended for dictation)
bash ./models/download-ggml-model.sh small.en
```

#### 2. Install llm CLI

```bash
# Install llm CLI tool
pip install llm

# Install Anthropic plugin
llm install llm-anthropic

# Set your Anthropic API key
llm keys set anthropic
# Enter your API key when prompted
```

Get your API key from https://console.anthropic.com/

#### 3. Install audio and clipboard tools

```bash
# On Arch Linux (Omarchy)
sudo pacman -S alsa-utils wl-clipboard
```

### Install the script

```bash
# Copy the script to your local bin
mkdir -p ~/.local/bin
cp transcribe.sh ~/.local/bin/transcribe
chmod +x ~/.local/bin/transcribe
```

## Usage

### Run manually

```bash
transcribe
```

### Set up Hyprland hotkey

The install script automatically configures Hyprland. If you need to do it manually:

1. Copy the config file:
```bash
cp transcribe.conf ~/.config/hypr/transcribe.conf
```

2. Add this line to your `~/.config/hypr/hyprland.conf`:
```conf
# Transcribe hotkey and window config
source = ~/.config/hypr/transcribe.conf
```

3. Reload Hyprland config:
```bash
hyprctl reload
```

Now press `SUPER + D` to start transcribing!

## Transformation Modes

When you stop recording, press one of these keys:

- **d**: Raw text - No transformation, just the transcription
- **s**: Structured document - Adds headings, bullet points, and clear sections
- **c**: Clean/format - Fixes punctuation and formatting without adding content
- **ESC**: Cancel - Discards the recording

## Adding New Transformation Modes

You can easily add your own transformation modes by editing the script:

1. Add a description variable:
```bash
MODE_X_DESC="Your mode description"
```

2. Add the prompt for Claude:
```bash
MODE_X_PROMPT="Your instructions for Claude to transform the text..."
```

3. Update the menu display (around line 83):
```bash
echo "  [d] $MODE_D_DESC  [s] $MODE_S_DESC  [c] $MODE_C_DESC  [x] $MODE_X_DESC"
```

### Example: Add a "summarize" mode

```bash
MODE_M_DESC="Summarize"
MODE_M_PROMPT="Summarize this transcription into a concise paragraph highlighting the key points."
```

Then users can press `m` to use the summarize mode.

## Configuration

Edit these variables at the top of `transcribe.sh` to customize:

- `WHISPER_DIR`: Location of whisper.cpp (default: `$HOME/whisper.cpp`)
- `MODEL`: Which Whisper model to use (default: `ggml-small.en.bin`)
- `LLM_MODEL`: Which LLM model to use (default: `claude-sonnet-4.5`)

### Choosing a Whisper model

The script uses `small.en` by default, which provides a good balance of accuracy and speed for dictation.

For a full list of available models and their specifications, see the [whisper.cpp models documentation](https://github.com/ggerganov/whisper.cpp/tree/master/models).

**To switch models:**

```bash
# Download a different model
cd ~/whisper.cpp
bash ./models/download-ggml-model.sh medium.en

# Update the MODEL variable in transcribe.sh (line 7)
MODEL="$WHISPER_DIR/models/ggml-medium.en.bin"
```

**Note:** The `.en` suffix indicates English-only models, which are more accurate for English than multilingual versions.

## Troubleshooting

### "whisper.cpp not found"
Make sure whisper.cpp is installed in `~/whisper.cpp` or update the `WHISPER_DIR` variable.

### "Model not found"
Download the model with: `bash ~/whisper.cpp/models/download-ggml-model.sh small.en`

### "llm not found"
Install the llm CLI with: `pip install llm` and `llm install llm-anthropic`

### "No clipboard tool found"
Install `wl-clipboard` (Wayland) or `xclip` (X11)

### Recording doesn't work
Make sure `arecord` is installed (part of alsa-utils package)

## License

MIT
