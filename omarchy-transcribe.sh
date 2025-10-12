#!/bin/bash

# Omarchy Transcribe
# Press Enter to start/stop recording, transcription copies to clipboard

WHISPER_DIR="$HOME/whisper.cpp"
MODEL="$WHISPER_DIR/models/ggml-small.en.bin"
TEMP_AUDIO="/tmp/whisper_recording.wav"
LLM_EXECUTABLE="$HOME/.local/bin/llm"
LLM_MODEL="claude-sonnet-4.5"

# Transformation modes
# Add more modes by creating MODE_X_DESC and MODE_X_PROMPT variables
MODE_D_DESC="Raw text"
MODE_D_PROMPT=""

MODE_S_DESC="Structured document"
MODE_S_PROMPT="Convert this transcription into a well-structured document with headings, bullet points, and clear sections where appropriate.

Requirements:
- Use ONLY information explicitly stated in the transcription
- Do not add any new examples, context, or explanatory content
- Do not expand on ideas beyond what was said
- Keep the output concise - remove filler words but preserve all substantive points
- If something is mentioned briefly, keep it brief in the output"

MODE_C_DESC="Clean/format text"
MODE_C_PROMPT="Please clean up and format the following dictated text. Add proper punctuation, fix any transcription errors, and organize it into clear paragraphs. Do not add any new information or content—only clean up and format the text that is already there. Do not add headings or titles."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to apply transformation based on selected mode
apply_transformation() {
    local text="$1"
    local mode_key="$2"

    # Convert mode key to uppercase for variable name
    local mode_upper=$(echo "$mode_key" | tr '[:lower:]' '[:upper:]')
    local prompt_var="MODE_${mode_upper}_PROMPT"
    local prompt="${!prompt_var}"

    # If there's a prompt, apply the transformation
    if [ -n "$prompt" ]; then
        # Check if llm executable exists
        if [ ! -f "$LLM_EXECUTABLE" ]; then
            echo -e "${RED}Warning: llm not found at $LLM_EXECUTABLE${NC}" >&2
            echo -e "${BLUE}Copying raw transcription instead...${NC}" >&2
            echo "$text"
            return
        fi

        echo -e "${BLUE}Applying transformation...${NC}" >&2
        echo "$text" | "$LLM_EXECUTABLE" -m "$LLM_MODEL" -s "$prompt"
    else
        echo "$text"
    fi
}

# Check if whisper.cpp is installed
if [ ! -f "$WHISPER_DIR/build/bin/whisper-cli" ]; then
    echo -e "${RED}Error: whisper.cpp not found at $WHISPER_DIR${NC}"
    echo "Please install it first. See script comments for instructions."
    echo ""
    echo "Press Enter to exit..."
    read
    exit 1
fi

# Check if model exists
if [ ! -f "$MODEL" ]; then
    echo -e "${RED}Error: Model not found at $MODEL${NC}"
    echo "Download it with: bash $WHISPER_DIR/models/download-ggml-model.sh base.en"
    echo ""
    echo "Press Enter to exit..."
    read
    exit 1
fi

clear
echo -e "${BLUE}=== Omarchy Transcribe ===${NC}"
echo ""

# Start recording
echo -e "${RED}● Recording...${NC}"
echo "Press key to stop and select mode:"
echo "  [d] $MODE_D_DESC  [s] $MODE_S_DESC  [c] $MODE_C_DESC"
echo "  [ESC] Cancel"
echo ""
arecord -f cd -t wav "$TEMP_AUDIO" 2>/dev/null &
RECORD_PID=$!

# Wait for key press to stop (accepts any single character or Enter)
read -n 1 SELECTED_MODE

# Stop recording
kill $RECORD_PID 2>/dev/null
wait $RECORD_PID 2>/dev/null

# Check if ESC key was pressed (ESC is ASCII 27, appears as ^[ or empty in some terminals)
if [[ "$SELECTED_MODE" == $'\x1b' ]]; then
    echo ""
    echo -e "${RED}Cancelled${NC}"
    rm -f "$TEMP_AUDIO"
    exit 0
fi

echo ""
echo -e "${BLUE}Processing transcription...${NC}"

# Transcribe
TRANSCRIPTION=$("$WHISPER_DIR/build/bin/whisper-cli" \
    -m "$MODEL" \
    -f "$TEMP_AUDIO" \
    --no-timestamps \
    --output-txt \
    --output-file /tmp/whisper_output 2>/dev/null)

# Get the transcribed text
TEXT=$(cat /tmp/whisper_output.txt 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$TEXT" ]; then
    echo -e "${RED}No transcription generated${NC}"
    rm -f "$TEMP_AUDIO" /tmp/whisper_output.txt
    echo ""
    echo "Press Enter to exit..."
    read
    exit 1
fi

# Apply transformation if a mode was selected
# Default to 'd' if no key was pressed (just Enter)
if [ -z "$SELECTED_MODE" ]; then
    SELECTED_MODE="d"
fi

TEXT=$(apply_transformation "$TEXT" "$SELECTED_MODE")

# Copy to clipboard (try multiple clipboard tools)
if command -v wl-copy &> /dev/null; then
    echo -n "$TEXT" | wl-copy
elif command -v xclip &> /dev/null; then
    echo -n "$TEXT" | xclip -selection clipboard
else
    echo -e "${RED}Warning: No clipboard tool found (install wl-clipboard or xclip)${NC}"
fi

# Display result
echo ""
echo -e "${GREEN}Transcribed text:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$TEXT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}✓ Copied to clipboard!${NC}"

# Cleanup
rm -f "$TEMP_AUDIO" /tmp/whisper_output.txt

# Wait 1 second before closing
sleep 1
