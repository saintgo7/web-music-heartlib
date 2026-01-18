#!/usr/bin/env python3
"""
MuLa Studio - HeartMuLa AI Music Generator UI
"""

import gradio as gr
import torch
import os
from pathlib import Path
from datetime import datetime
import sys

# Setup paths
MODEL_DIR = Path.home() / ".mulastudio" / "models"
OUTPUT_DIR = Path.home() / "Documents" / "MuLaStudio_Outputs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Detect device
if torch.backends.mps.is_available():
    DEVICE = "mps"
    DEVICE_NAME = "Apple Silicon (MPS)"
elif torch.cuda.is_available():
    DEVICE = "cuda"
    DEVICE_NAME = torch.cuda.get_device_name(0)
else:
    DEVICE = "cpu"
    DEVICE_NAME = "CPU"

model = None


def load_model():
    """Load HeartMuLa model"""
    global model
    if model is None:
        try:
            from heartlib import HeartMuLaInfer
            model = HeartMuLaInfer(model_path=str(MODEL_DIR), version="3B")
        except Exception as e:
            return None, f"Error loading model: {str(e)}"
    return model, None


def generate(lyrics, tags, length, temp, cfg, progress=gr.Progress()):
    """Generate music based on lyrics and tags"""
    try:
        progress(0.1, "Loading model...")
        m, error = load_model()
        if error:
            return None, error

        progress(0.2, "Generating music...")
        output_path = OUTPUT_DIR / f"music_{datetime.now():%Y%m%d_%H%M%S}.mp3"

        m.generate(
            lyrics=lyrics,
            tags=tags,
            max_audio_length_ms=int(length * 1000),
            temperature=temp,
            cfg_scale=cfg,
            save_path=str(output_path)
        )

        progress(1.0, "Complete!")
        return str(output_path), f"✓ Saved: {output_path.name}"
    except Exception as e:
        return None, f"Error: {str(e)}"


# Example content
SAMPLE_LYRICS = """[Verse]
The morning light comes through the window
A brand new day is here

[Chorus]
We rise again, we start again
Every day is a new begin"""

SAMPLE_TAGS = "piano,happy,pop"

# Create Gradio interface
with gr.Blocks(title="MuLa Studio", theme=gr.themes.Soft()) as app:
    gr.Markdown(f"# ♪ MuLa Studio\n**Device**: {DEVICE_NAME}")

    with gr.Row():
        with gr.Column(scale=2):
            lyrics = gr.Textbox(
                label="Lyrics",
                lines=12,
                value=SAMPLE_LYRICS,
                placeholder="Enter lyrics in [Verse], [Chorus] format..."
            )
            tags = gr.Textbox(
                label="Style Tags (comma-separated)",
                value=SAMPLE_TAGS,
                placeholder="e.g., piano,happy,pop,acoustic"
            )

        with gr.Column(scale=1):
            gr.Markdown("### Settings")
            length = gr.Slider(
                30, 240, 120,
                step=10,
                label="Length (seconds)"
            )
            temp = gr.Slider(
                0.5, 1.5, 1.0,
                step=0.1,
                label="Temperature"
            )
            cfg = gr.Slider(
                1.0, 3.0, 1.5,
                step=0.1,
                label="CFG Scale"
            )
            btn = gr.Button("♪ Generate Music", variant="primary", size="lg")

    status = gr.Textbox(label="Status", interactive=False)
    audio = gr.Audio(label="Generated Music", type="filepath")

    btn.click(
        generate,
        [lyrics, tags, length, temp, cfg],
        [audio, status]
    )

    gr.Markdown("---\n*Powered by HeartMuLa (CC BY-NC 4.0)*")


if __name__ == "__main__":
    app.launch(
        server_name="127.0.0.1",
        server_port=7860,
        inbrowser=True,
        show_error=True
    )
