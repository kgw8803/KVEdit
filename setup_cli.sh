#!/bin/bash

# KV-Edit CLI Setup Script
# This script sets up the environment and dependencies for KV-Edit CLI

echo "🔧 KV-Edit CLI Environment Setup"
echo "================================"
echo ""

# Function to check if conda is installed
check_conda() {
    if ! command -v conda &> /dev/null; then
        echo "❌ Error: Conda is not installed or not in PATH"
        echo "Please install Miniconda or Anaconda first"
        echo "Download from: https://docs.conda.io/en/latest/miniconda.html"
        exit 1
    fi
    echo "✅ Conda found: $(conda --version)"
}

# Function to create conda environment
create_environment() {
    echo "📦 Creating conda environment 'KV-Edit'..."
    
    # Check if environment already exists
    if conda env list | grep -q "KV-Edit"; then
        echo "🔄 Environment 'KV-Edit' already exists"
        read -p "Do you want to recreate it? (y/N): " recreate
        if [[ $recreate =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing existing environment..."
            conda env remove -n KV-Edit -y
        else
            echo "📝 Skipping environment creation"
            return 0
        fi
    fi
    
    # Create new environment
    conda create -n KV-Edit python=3.9 -y
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to create conda environment"
        exit 1
    fi
    
    echo "✅ Environment 'KV-Edit' created successfully"
}

# Function to activate environment and install dependencies
install_dependencies() {
    echo "📚 Installing dependencies..."
    
    # Activate environment
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate KV-Edit
    
    if [ "$CONDA_DEFAULT_ENV" != "KV-Edit" ]; then
        echo "❌ Error: Failed to activate environment"
        exit 1
    fi
    
    # Install PyTorch with CUDA support
    echo "🔥 Installing PyTorch with CUDA support..."
    conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
    
    # Install other dependencies
    echo "📦 Installing other dependencies..."
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        echo "⚠️  Warning: requirements.txt not found"
        echo "Installing common dependencies..."
        pip install transformers diffusers accelerate
        pip install pillow numpy einops gradio
        pip install safetensors sentencepiece
    fi
    
    echo "✅ Dependencies installed successfully"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    
    # Activate environment
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate KV-Edit
    
    # Check key packages
    python -c "
import sys
packages = ['torch', 'transformers', 'diffusers', 'PIL', 'numpy', 'einops']
missing = []

for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg}: OK')
    except ImportError:
        print(f'❌ {pkg}: Missing')
        missing.append(pkg)

if missing:
    print(f'\\n❌ Missing packages: {missing}')
    sys.exit(1)
else:
    print('\\n✅ All packages verified successfully')
"
    
    # Check CUDA availability
    python -c "
import torch
if torch.cuda.is_available():
    print(f'✅ CUDA available: {torch.cuda.get_device_name(0)}')
    print(f'   CUDA version: {torch.version.cuda}')
    print(f'   GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB')
else:
    print('⚠️  CUDA not available - will use CPU')
"
}

# Function to make scripts executable
setup_scripts() {
    echo "🔨 Setting up execution scripts..."
    chmod +x *.sh
    echo "✅ All shell scripts are now executable"
}

# Function to create example files
create_examples() {
    echo "📝 Creating example files..."
    
    # Create a sample mask creation script
    cat > create_sample_mask.py << 'EOF'
#!/usr/bin/env python3
"""
Sample script to create a mask image for testing KV-Edit
"""

from PIL import Image, ImageDraw
import sys

def create_sample_mask(input_image_path, output_mask_path, mask_type="center"):
    """
    Create a sample mask for the input image
    
    Args:
        input_image_path: Path to input image
        output_mask_path: Path to save the mask
        mask_type: Type of mask ("center", "left", "right", "top", "bottom")
    """
    try:
        # Open input image to get dimensions
        img = Image.open(input_image_path)
        width, height = img.size
        
        # Create black mask
        mask = Image.new('L', (width, height), 0)
        draw = ImageDraw.Draw(mask)
        
        # Draw white area based on mask type
        if mask_type == "center":
            # Center rectangle
            x1, y1 = width//4, height//4
            x2, y2 = 3*width//4, 3*height//4
            draw.rectangle([x1, y1, x2, y2], fill=255)
        elif mask_type == "left":
            draw.rectangle([0, 0, width//2, height], fill=255)
        elif mask_type == "right":
            draw.rectangle([width//2, 0, width, height], fill=255)
        elif mask_type == "top":
            draw.rectangle([0, 0, width, height//2], fill=255)
        elif mask_type == "bottom":
            draw.rectangle([0, height//2, width, height], fill=255)
        
        # Save mask
        mask.save(output_mask_path)
        print(f"✅ Sample mask created: {output_mask_path}")
        
    except Exception as e:
        print(f"❌ Error creating mask: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python create_sample_mask.py <input_image> <output_mask> [mask_type]")
        print("Mask types: center, left, right, top, bottom")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    mask_type = sys.argv[3] if len(sys.argv) > 3 else "center"
    
    create_sample_mask(input_path, output_path, mask_type)
EOF
    
    chmod +x create_sample_mask.py
    echo "✅ Created create_sample_mask.py for testing"
}

# Function to display usage instructions
show_usage() {
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Prepare your images:"
    echo "   - Input image: The image you want to edit"
    echo "   - Mask image: White areas will be edited, black areas preserved"
    echo ""
    echo "2. Create a sample mask (optional):"
    echo "   python create_sample_mask.py your_image.jpg mask.png center"
    echo ""
    echo "3. Run KV-Edit CLI:"
    echo "   ./quick_start.sh your_image.jpg mask.png \"source prompt\" \"target prompt\""
    echo ""
    echo "4. Or use advanced options:"
    echo "   ./run_cli_advanced.sh"
    echo ""
    echo "5. For help:"
    echo "   python cli_kv_edit.py --help"
    echo ""
    echo "📚 Read CLI_README.md for detailed usage instructions"
    echo ""
}

# Main execution
main() {
    echo "Starting setup process..."
    echo ""
    
    # Check prerequisites
    check_conda
    
    # Setup conda environment
    create_environment
    
    # Install dependencies
    install_dependencies
    
    # Verify installation
    verify_installation
    
    # Setup scripts
    setup_scripts
    
    # Create examples
    create_examples
    
    # Show usage
    show_usage
}

# Run main function
main "$@" 