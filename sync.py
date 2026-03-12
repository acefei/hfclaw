"""HuggingFace dataset sync utility for OpenClaw Gateway backup/restore."""

import os
import sys
import tarfile
from datetime import datetime, timedelta

from huggingface_hub import HfApi, hf_hub_download

REPO_ID = os.getenv("HF_DATASET")
TOKEN = os.getenv("HF_TOKEN")
API = HfApi()
BACKUP_DIR = "/root/.openclaw"
BACKUP_TARGETS = ["sessions", "workspace", "agents", "memory", "openclaw.json"]
MAX_BACKUP_DAYS = 5


def log(message: str) -> None:
    print(f"--- [SYNC] {message} ---")


def get_backup_filename(date: datetime) -> str:
    return f"backup_{date.strftime('%Y-%m-%d')}.tar.gz"


def restore() -> bool:
    if not REPO_ID or not TOKEN:
        log("Skipping restore: HF_DATASET or HF_TOKEN not configured")
        return False

    log(f"Starting restore process, target repo: {REPO_ID}")

    try:
        files = API.list_repo_files(repo_id=REPO_ID, repo_type="dataset", token=TOKEN)
        now = datetime.now()

        for i in range(MAX_BACKUP_DAYS):
            backup_date = now - timedelta(days=i)
            filename = get_backup_filename(backup_date)

            if filename in files:
                log(f"Found backup: {filename}, downloading...")
                path = hf_hub_download(
                    repo_id=REPO_ID, filename=filename, repo_type="dataset", token=TOKEN
                )
                with tarfile.open(path, "r:gz") as tar:
                    tar.extractall(path=BACKUP_DIR)
                log(f"Restore successful! Data restored to {BACKUP_DIR}")
                return True

        log(f"No backup found in the last {MAX_BACKUP_DAYS} days")
        return False

    except Exception as e:
        log(f"Restore failed: {e}")
        return False


def backup() -> bool:
    if not REPO_ID or not TOKEN:
        log("Skipping backup: HF_DATASET or HF_TOKEN not configured")
        return False

    try:
        filename = get_backup_filename(datetime.now())
        log(f"Creating backup: {filename}")

        with tarfile.open(filename, "w:gz") as tar:
            for target in BACKUP_TARGETS:
                full_path = f"{BACKUP_DIR}/{target}"
                if os.path.exists(full_path):
                    tar.add(full_path, arcname=target)

        API.upload_file(
            path_or_fileobj=filename,
            path_in_repo=filename,
            repo_id=REPO_ID,
            repo_type="dataset",
            token=TOKEN,
        )
        log("Backup uploaded successfully")
        return True

    except Exception as e:
        log(f"Backup failed: {e}")
        return False


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "backup":
        backup()
    else:
        restore()


if __name__ == "__main__":
    main()
