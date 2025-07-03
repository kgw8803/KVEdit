#!/bin/bash

# KV-Edit CLI Quick Start Script
# Simple script for quick testing and getting started

echo "🚀 KV-Edit CLI Quick Start"
echo "========================="
echo ""

# Activate conda environment
echo "🔧 Activating conda environment 'KV-Edit'..."
source $(conda info --base)/etc/profile.d/conda.sh
conda activate KV-Edit

# Check if environment activation was successful
if [ "$CONDA_DEFAULT_ENV" != "KV-Edit" ]; then
    echo "❌ Error: Failed to activate conda environment 'KV-Edit'"
    echo "Please make sure the environment exists: conda env list"
    echo "Or create it with: conda create -n KV-Edit python=3.9"
    exit 1
fi

echo "✅ Conda environment 'KV-Edit' activated successfully"
echo ""

# Check if required arguments are provided
if [ $# -lt 4 ]; then
    echo "Usage: $0 <input_image> <mask_image> <source_prompt> <target_prompt> [options...]"
    echo ""
    echo "Example:"
    echo "  $0 photo.jpg mask.png \"a person in a garden\" \"a robot in a garden\""
    echo ""
    echo "Optional arguments will be passed directly to the CLI:"
    echo "  $0 photo.jpg mask.png \"source\" \"target\" --skip_step 2 --attn_mask"
    echo ""
    echo "For more examples and advanced usage:"
    echo "  ./run_cli_advanced.sh"
    echo ""
    exit 1
fi

INPUT_IMAGE="$1"
MASK_IMAGE="$2"
SOURCE_PROMPT="$3"
TARGET_PROMPT="$4"

# Shift the first 4 arguments so $@ contains remaining options
shift 4

# Validate input files
if [ ! -f "$INPUT_IMAGE" ]; then
    echo "❌ Error: Input image not found: $INPUT_IMAGE"
    exit 1
fi

if [ ! -f "$MASK_IMAGE" ]; then
    echo "❌ Error: Mask image not found: $MASK_IMAGE"
    exit 1
fi

echo "📝 Configuration:"
echo "  Input: $INPUT_IMAGE"
echo "  Mask: $MASK_IMAGE"
echo "  Source: '$SOURCE_PROMPT'"
echo "  Target: '$TARGET_PROMPT'"
if [ $# -gt 0 ]; then
    echo "  Extra options: $@"
fi
echo ""

echo "🎬 Starting KV-Edit..."

# Run the CLI with provided arguments
python cli_kv_edit.py \
    --input_image "$INPUT_IMAGE" \
    --mask_image "$MASK_IMAGE" \
    --source_prompt "$SOURCE_PROMPT" \
    --target_prompt "$TARGET_PROMPT" \
    "$@"

echo ""
echo "✅ KV-Edit completed! Check the 'regress_result' directory for output." 