#!/usr/bin/env python3
"""
HeartMuLa AI Model Downloader

Downloads required AI models from HuggingFace:
  - HeartMuLaGen (base generator)
  - HeartMuLa-oss-3B (3B parameter model)
  - HeartCodec-oss (audio codec)

Total size: approximately 6GB
"""

import sys
import os
import time
from pathlib import Path
from typing import Optional

try:
    from huggingface_hub import snapshot_download, hf_hub_download
    from tqdm import tqdm
except ImportError:
    print("Error: Required packages not installed.")
    print("Please run: pip install huggingface_hub tqdm")
    sys.exit(1)


# Model configuration
MODELS = [
    {
        "repo_id": "HeartMuLa/HeartMuLaGen",
        "local_dir_name": "",  # Root of model directory
        "description": "HeartMuLaGen (Base Generator)",
    },
    {
        "repo_id": "HeartMuLa/HeartMuLa-oss-3B",
        "local_dir_name": "HeartMuLa-oss-3B",
        "description": "HeartMuLa-oss-3B (3B Parameter Model)",
    },
    {
        "repo_id": "HeartMuLa/HeartCodec-oss",
        "local_dir_name": "HeartCodec-oss",
        "description": "HeartCodec-oss (Audio Codec)",
    },
]


def get_default_model_dir() -> Path:
    """Get default model directory based on OS"""
    if sys.platform == "win32":
        # Windows: %USERPROFILE%\.mulastudio\models
        base = os.environ.get("USERPROFILE", os.path.expanduser("~"))
    else:
        # macOS/Linux: ~/.mulastudio/models
        base = os.path.expanduser("~")
    return Path(base) / ".mulastudio" / "models"


def check_disk_space(path: Path, required_gb: float = 15.0) -> bool:
    """Check if there's enough disk space"""
    try:
        import shutil
        total, used, free = shutil.disk_usage(path.parent if not path.exists() else path)
        free_gb = free / (1024 ** 3)
        if free_gb < required_gb:
            print(f"Warning: Only {free_gb:.1f}GB free, {required_gb}GB recommended.")
            return False
        return True
    except Exception:
        return True  # Proceed anyway if check fails


def download_model(
    repo_id: str,
    local_dir: Path,
    description: str,
    max_retries: int = 3,
    timeout: float = 120.0
) -> bool:
    """
    Download a single model from HuggingFace

    Args:
        repo_id: HuggingFace repository ID
        local_dir: Local directory to save model
        description: Human-readable description
        max_retries: Maximum number of retry attempts
        timeout: Download timeout in seconds

    Returns:
        True if successful, False otherwise
    """
    print(f"\nDownloading {description}...")
    print(f"  Repository: {repo_id}")
    print(f"  Target: {local_dir}")

    local_dir.mkdir(parents=True, exist_ok=True)

    for attempt in range(1, max_retries + 1):
        try:
            snapshot_download(
                repo_id=repo_id,
                local_dir=str(local_dir),
                local_dir_use_symlinks=False,
                resume_download=True,  # Resume if interrupted
            )
            print(f"  [OK] {description} downloaded successfully!")
            return True

        except KeyboardInterrupt:
            print("\n  [!] Download interrupted by user.")
            raise

        except Exception as e:
            print(f"  [!] Attempt {attempt}/{max_retries} failed: {e}")
            if attempt < max_retries:
                wait_time = attempt * 10  # Exponential backoff
                print(f"  Retrying in {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                print(f"  [ERROR] Failed to download {description}")
                return False

    return False


def download_all_models(model_dir: Optional[Path] = None) -> bool:
    """
    Download all required models

    Args:
        model_dir: Target directory for models

    Returns:
        True if all models downloaded successfully
    """
    if model_dir is None:
        model_dir = get_default_model_dir()

    model_dir = Path(model_dir)
    print("=" * 60)
    print("HeartMuLa AI Model Downloader")
    print("=" * 60)
    print(f"\nModel directory: {model_dir}")
    print(f"Total download size: approximately 6GB")
    print(f"Estimated time: 10-30 minutes (depends on connection)")
    print()

    # Check disk space
    if not check_disk_space(model_dir, 15.0):
        response = input("Continue anyway? [y/N] ").strip().lower()
        if response != 'y':
            print("Download cancelled.")
            return False

    # Download each model
    success_count = 0
    for i, model in enumerate(MODELS, 1):
        print(f"\n[{i}/{len(MODELS)}] ", end="")

        if model["local_dir_name"]:
            target_dir = model_dir / model["local_dir_name"]
        else:
            target_dir = model_dir

        if download_model(
            repo_id=model["repo_id"],
            local_dir=target_dir,
            description=model["description"]
        ):
            success_count += 1

    # Summary
    print("\n" + "=" * 60)
    if success_count == len(MODELS):
        print("All models downloaded successfully!")
        print(f"Models are ready at: {model_dir}")
        return True
    else:
        print(f"Warning: {len(MODELS) - success_count} model(s) failed to download.")
        print("Please check your internet connection and try again.")
        return False


def verify_models(model_dir: Optional[Path] = None) -> bool:
    """
    Verify that all required models are present

    Args:
        model_dir: Model directory to check

    Returns:
        True if all models are present
    """
    if model_dir is None:
        model_dir = get_default_model_dir()

    model_dir = Path(model_dir)
    print(f"Verifying models in: {model_dir}")

    missing = []
    for model in MODELS:
        if model["local_dir_name"]:
            target = model_dir / model["local_dir_name"]
        else:
            target = model_dir

        if not target.exists():
            missing.append(model["description"])
            print(f"  [!] Missing: {model['description']}")
        else:
            print(f"  [OK] {model['description']}")

    if missing:
        print(f"\n{len(missing)} model(s) missing. Run download again.")
        return False
    else:
        print("\nAll models verified!")
        return True


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Download HeartMuLa AI models from HuggingFace"
    )
    parser.add_argument(
        "model_dir",
        nargs="?",
        default=None,
        help="Target directory for models (default: ~/.mulastudio/models)"
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Verify existing models instead of downloading"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-download even if models exist"
    )

    args = parser.parse_args()

    model_dir = Path(args.model_dir) if args.model_dir else None

    if args.verify:
        success = verify_models(model_dir)
    else:
        if model_dir and args.force:
            import shutil
            if model_dir.exists():
                print(f"Removing existing models in {model_dir}...")
                shutil.rmtree(model_dir)

        success = download_all_models(model_dir)

        if success:
            verify_models(model_dir)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
