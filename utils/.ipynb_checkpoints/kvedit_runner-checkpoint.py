import os
from PIL import Image
import numpy as np
import torch
from collections import defaultdict
from einops import rearrange
from flux.util import load_ae, load_clip, load_t5
from flux.sampling import prepare
from models.kv_edit import Flux_kv_edit
import torch.nn.functional as F

def preprocess_image(image_path):
    image = Image.open(image_path).convert("RGB").resize((512, 512))
    image = np.array(image).astype(np.float32) / 127.5 - 1.0
    image = torch.from_numpy(image).permute(2, 0, 1).unsqueeze(0)
    return image

def load_mask(mask_path, device="cuda"):
    mask_img = Image.open(mask_path).convert("RGBA").resize((64, 64))  # Latent size
    alpha = np.array(mask_img)[:, :, 3]
    mask_tensor = torch.from_numpy(alpha).unsqueeze(0).unsqueeze(0)
    return (mask_tensor > 128).to(torch.bool).to(device)

@torch.inference_mode()
def run_edit_from_latent(
    src_image_path,
    z_fg_path,
    mask_path,
    opts: SamplingOptions,
    save_path,
    device="cuda",
    model_name="flux-dev",
    t_step: int = 0
):
    # 1. 모델 로드
    ae = load_ae(model_name, device=device)
    clip = load_clip(device)
    t5 = load_t5(device)
    model = Flux_kv_edit(device=device, name=model_name)

    ae.eval(), clip.eval(), t5.eval(), model.eval()

    # 2. 이미지 및 마스크 불러오기
    x_src = preprocess_image(src_image_path).to(device)
    z_bg = ae.encode(x_src).to(torch.float32)
    z_fg = torch.load(z_fg_path).to(torch.float32)
    mask = load_mask(mask_path, device)

    # 3. Prompt → Cross-attention conditioning
    inp_target = prepare(t5, clip, z_bg, prompt=opts.target_prompt)

    # 4. Feature dictionary 초기화
    feature_dict = defaultdict(lambda _: torch.zeros_like(z_bg))

    info = {
        "t": t_step,
        "feature": feature_dict
    }

    # 5. denoise 실행
    result = model.denoise(z_bg, z_fg, inp_target, mask, opts, info)

    # 6. 디코딩 및 저장
    x = ae.decode(result.to(ae.decoder.weight.device)).clamp(-1, 1).float().cpu()
    x = rearrange(x[0], "c h w -> h w c")
    out = Image.fromarray(((x + 1.0) * 127.5).numpy().astype(np.uint8))
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    out.save(save_path)
    print(f"✅ Saved: {save_path}")