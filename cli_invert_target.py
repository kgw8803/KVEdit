import os
import argparse
import numpy as np
from PIL import Image
import torch
from flux.util import load_ae

def preprocess_image(image_path, size=(512, 512)):
    image = Image.open(image_path).convert("RGB").resize(size)
    image = np.array(image).astype(np.float32) / 127.5 - 1.0
    image = torch.from_numpy(image).permute(2, 0, 1).unsqueeze(0)
    return image  # (1, 3, H, W)

def load_mask(mask_path, device="cuda"):
    #mask_img = Image.open(mask_path).convert("RGBA").resize((512, 512))
    mask_img = Image.open(mask_path).convert("RGBA").resize((64, 64))  # downsample
    alpha = np.array(mask_img)[:, :, 3]  # alpha channel
    mask_tensor = torch.from_numpy(alpha).unsqueeze(0).unsqueeze(0)
    return (mask_tensor > 128).to(torch.bool).to(device)

@torch.inference_mode()
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target_image", type=str, required=True, help="Target image with object to inject")
    parser.add_argument("--mask", type=str, required=True, help="Mask indicating foreground region (RGBA)")
    parser.add_argument("--device", type=str, default="cuda")
    parser.add_argument("--model_name", type=str, default="flux-dev")
    parser.add_argument("--save_dir", type=str, default="latents")
    args = parser.parse_args()

    device = args.device
    ae = load_ae(args.model_name, device=device)
    ae.eval().to(device)

    x_tgt = preprocess_image(args.target_image).to(device)
    mask = load_mask(args.mask, device)

    z_tgt = ae.encode(x_tgt).to(torch.bfloat16)

    # foreground token만 유지, 나머지는 0으로 마스킹
    z_fg = torch.zeros_like(z_tgt)
    z_fg[mask.expand_as(z_tgt)] = z_tgt[mask.expand_as(z_tgt)]

    os.makedirs(args.save_dir, exist_ok=True)
    fname = os.path.splitext(os.path.basename(args.target_image))[0]
    save_path = os.path.join(args.save_dir, f"z_fg_{fname}.pt")
    torch.save(z_fg, save_path)
    print(f"✅ Foreground-only z_fg saved to: {save_path}")

if __name__ == "__main__":
    main()