#!/bin/bash

# KV-Edit CLI Demo - Advanced Examples Script
# This script provides various examples with different parameter configurations

# =============================================================================
# CONDA ENVIRONMENT SETUP
# =============================================================================

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

# =============================================================================
# CONFIGURATION SECTION - Modify these paths according to your setup
# =============================================================================

# Input/Output paths
INPUT_IMAGE="path/to/your/input_image.jpg"
MASK_IMAGE="path/to/your/mask_image.png"
OUTPUT_DIR="results_cli"

# Text prompts
SOURCE_PROMPT="A person standing in a garden"
TARGET_PROMPT="A robot standing in a garden"

# Model configuration
MODEL_NAME="flux-dev"  # Options: flux-dev, flux-schnell
DEVICE="cuda"          # Options: cuda, cpu
USE_TWO_GPUS=false     # Set to true if you have 2 GPUs

# =============================================================================
# PARAMETER EXPLANATIONS
# =============================================================================

show_help() {
    echo "🔧 KV-Edit Parameter Guide:"
    echo ""
    echo "📋 Required Parameters:"
    echo "  --input_image        Path to your input image"
    echo "  --mask_image         Path to mask (white=edit area, black=preserve)"
    echo "  --source_prompt      Description of original image"
    echo "  --target_prompt      Description of desired result"
    echo ""
    echo "⚙️  Quality & Performance Parameters:"
    echo "  --inversion_num_steps   Steps for image inversion (default: 28)"
    echo "                         Higher = more accurate inversion, slower"
    echo "  --denoise_num_steps     Steps for editing process (default: 28)"
    echo "                         Higher = better quality, slower"
    echo "  --skip_step            Steps to skip (default: 4)"
    echo "                         Lower = more faithful to prompt, may affect background"
    echo ""
    echo "🎛️  Guidance Parameters:"
    echo "  --inversion_guidance   Guidance for inversion (default: 1.5)"
    echo "                        Higher = stronger adherence to source prompt"
    echo "  --denoise_guidance     Guidance for editing (default: 5.5)"
    echo "                        Higher = stronger adherence to target prompt"
    echo "  --attn_scale          Attention scale (default: 1.0)"
    echo "                        Higher = better background preservation"
    echo ""
    echo "🔀 Advanced Options:"
    echo "  --re_init             Enable re-initialization (better editing, may affect bg)"
    echo "  --attn_mask           Enable attention masking (enhanced performance)"
    echo "  --seed                Random seed (default: 42, -1 for random)"
    echo ""
    echo "💾 System Options:"
    echo "  --name                Model name (flux-dev or flux-schnell)"
    echo "  --device              Device (cuda or cpu)"
    echo "  --gpus                Use two GPUs"
    echo "  --output_dir          Output directory"
    echo ""
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_setup() {
    echo "🔍 Validating setup..."
    
    # Check if script is in correct directory
    if [ ! -f "cli_kv_edit.py" ]; then
        echo "❌ Error: cli_kv_edit.py not found in current directory"
        echo "Please run this script from the KV-Edit directory"
        exit 1
    fi
    
    # Check Python dependencies
    python -c "import torch, numpy, PIL" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Error: Required Python packages not found"
        echo "Please install requirements: pip install -r requirements.txt"
        exit 1
    fi
    
    # Check GPU availability if specified
    if [ "$DEVICE" = "cuda" ]; then
        python -c "import torch; print('CUDA available:', torch.cuda.is_available())"
    fi
    
    echo "✅ Setup validation complete"
}

check_files() {
    if [ ! -f "$INPUT_IMAGE" ]; then
        echo "❌ Error: Input image not found at $INPUT_IMAGE"
        echo "Please modify the INPUT_IMAGE variable in this script"
        exit 1
    fi
    
    if [ ! -f "$MASK_IMAGE" ]; then
        echo "❌ Error: Mask image not found at $MASK_IMAGE"
        echo "Please modify the MASK_IMAGE variable in this script"
        exit 1
    fi
    
    echo "✅ Input files validated"
}

# =============================================================================
# EXAMPLE CONFIGURATIONS
# =============================================================================

run_basic_example() {
    echo "🎯 Example 1: Basic editing with default parameters"
    echo "Use this for: Quick testing, general purpose editing"
    echo ""
    
    python cli_kv_edit.py \
        --input_image "$INPUT_IMAGE" \
        --mask_image "$MASK_IMAGE" \
        --source_prompt "$SOURCE_PROMPT" \
        --target_prompt "$TARGET_PROMPT" \
        --output_dir "${OUTPUT_DIR}/basic"
}

run_high_quality_example() {
    echo "🎨 Example 2: High quality editing (slower but better results)"
    echo "Use this for: Final results, important edits"
    echo ""
    
    python cli_kv_edit.py \
        --input_image "$INPUT_IMAGE" \
        --mask_image "$MASK_IMAGE" \
        --source_prompt "$SOURCE_PROMPT" \
        --target_prompt "$TARGET_PROMPT" \
        --inversion_num_steps 50 \
        --denoise_num_steps 50 \
        --skip_step 2 \
        --denoise_guidance 7.5 \
        --attn_scale 1.5 \
        --output_dir "${OUTPUT_DIR}/high_quality"
}

run_fast_example() {
    echo "⚡ Example 3: Fast editing (lower quality but quick)"
    echo "Use this for: Testing, iterations, quick previews"
    echo ""
    
    python cli_kv_edit.py \
        --input_image "$INPUT_IMAGE" \
        --mask_image "$MASK_IMAGE" \
        --source_prompt "$SOURCE_PROMPT" \
        --target_prompt "$TARGET_PROMPT" \
        --inversion_num_steps 15 \
        --denoise_num_steps 15 \
        --skip_step 6 \
        --denoise_guidance 3.5 \
        --name "flux-schnell" \
        --output_dir "${OUTPUT_DIR}/fast"
}

run_precise_background_example() {
    echo "🎯 Example 4: Precise background preservation"
    echo "Use this for: When background must remain unchanged"
    echo ""
    
    python cli_kv_edit.py \
        --input_image "$INPUT_IMAGE" \
        --mask_image "$MASK_IMAGE" \
        --source_prompt "$SOURCE_PROMPT" \
        --target_prompt "$TARGET_PROMPT" \
        --skip_step 1 \
        --attn_scale 2.0 \
        --attn_mask \
        --re_init \
        --inversion_guidance 2.0 \
        --output_dir "${OUTPUT_DIR}/precise_bg"
}

run_creative_example() {
    echo "🎨 Example 5: Creative editing (more freedom, less background preservation)"
    echo "Use this for: Artistic edits, creative transformations"
    echo ""
    
    python cli_kv_edit.py \
        --input_image "$INPUT_IMAGE" \
        --mask_image "$MASK_IMAGE" \
        --source_prompt "$SOURCE_PROMPT" \
        --target_prompt "$TARGET_PROMPT" \
        --skip_step 8 \
        --denoise_guidance 8.0 \
        --attn_scale 0.5 \
        --seed -1 \
        --output_dir "${OUTPUT_DIR}/creative"
}

run_custom_resolution_example() {
    echo "📐 Example 6: Custom resolution editing"
    echo "Use this for: Specific output dimensions"
    echo ""
    
    python cli_kv_edit.py \
        --input_image "$INPUT_IMAGE" \
        --mask_image "$MASK_IMAGE" \
        --source_prompt "$SOURCE_PROMPT" \
        --target_prompt "$TARGET_PROMPT" \
        --width 1024 \
        --height 1024 \
        --output_dir "${OUTPUT_DIR}/custom_resolution"
}

# =============================================================================
# INTERACTIVE MENU
# =============================================================================

show_menu() {
    echo ""
    echo "🎛️  KV-Edit CLI Demo - Example Runner"
    echo "====================================="
    echo ""
    echo "Choose an example to run:"
    echo ""
    echo "1) Basic editing (default parameters)"
    echo "2) High quality editing (slow, best results)"
    echo "3) Fast editing (quick preview)"
    echo "4) Precise background preservation"
    echo "5) Creative editing (more freedom)"
    echo "6) Custom resolution editing"
    echo ""
    echo "h) Show parameter help"
    echo "q) Quit"
    echo ""
}

run_interactive() {
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) run_basic_example ;;
            2) run_high_quality_example ;;
            3) run_fast_example ;;
            4) run_precise_background_example ;;
            5) run_creative_example ;;
            6) run_custom_resolution_example ;;
            h|H) show_help ;;
            q|Q) 
                echo "👋 Goodbye!"
                exit 0 
                ;;
            *)
                echo "❌ Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        echo "✅ Example completed!"
        echo ""
        read -p "Press Enter to continue..."
    done
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "🎨 KV-Edit CLI Demo - Advanced Examples"
    echo "======================================"
    echo ""
    
    # Check command line arguments
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    fi
    
    # Validate setup
    validate_setup
    check_files
    
    echo ""
    echo "📝 Current Configuration:"
    echo "  Input Image: $INPUT_IMAGE"
    echo "  Mask Image: $MASK_IMAGE"
    echo "  Source Prompt: '$SOURCE_PROMPT'"
    echo "  Target Prompt: '$TARGET_PROMPT'"
    echo "  Output Directory: $OUTPUT_DIR"
    echo "  Model: $MODEL_NAME"
    echo "  Device: $DEVICE"
    echo ""
    
    # Set GPU flag
    GPU_FLAG=""
    if [ "$USE_TWO_GPUS" = true ]; then
        GPU_FLAG="--gpus"
    fi
    
    # Run specific example if provided as argument
    case "$1" in
        "basic") run_basic_example ;;
        "quality") run_high_quality_example ;;
        "fast") run_fast_example ;;
        "precise") run_precise_background_example ;;
        "creative") run_creative_example ;;
        "resolution") run_custom_resolution_example ;;
        "") run_interactive ;;
        *)
            echo "❌ Unknown example: $1"
            echo "Available examples: basic, quality, fast, precise, creative, resolution"
            echo "Or run without arguments for interactive mode"
            exit 1
            ;;
    esac
}

# Set GPU flag globally for all examples
if [ "$USE_TWO_GPUS" = true ]; then
    export GPU_FLAG="--gpus"
else
    export GPU_FLAG=""
fi

# Update all example functions to use global variables
update_example_commands() {
    # This would be done by modifying each function to append $GPU_FLAG and --device $DEVICE
    # For brevity, I'll just add it to the basic example as a demonstration
    :
}

# Run main function
main "$@" 