import requests
import random
from pathlib import Path

API_BASE = "https://freesound.org/apiv2"

# Встроенный API-ключ
DEFAULT_API_KEY = "op3Zzn8R3XZdMmFfUxnayEYcFrx7A6Z4w1tmjZvH"

_api_key = None


def init_client(api_key: str):
    global _api_key
    _api_key = api_key
    return True


def ensure_client():
    global _api_key
    if _api_key is None:
        _api_key = DEFAULT_API_KEY


def _check_key():
    ensure_client()


def search_samples(query: str, limit: int = 20, min_duration: float = 1.0,
                   max_duration: float = 30.0, page: int = 1) -> list:
    _check_key()

    params = {
        "query": query,
        "filter": f"duration:[{min_duration} TO {max_duration}]",
        "fields": "id,name,duration,previews,license,username,tags",
        "page_size": limit,
        "page": page,
        "token": _api_key,
        "sort": "score",
    }

    r = requests.get(f"{API_BASE}/search/text/", params=params, timeout=15)
    if r.status_code == 401:
        raise RuntimeError("Freesound: неверный API-ключ.")
    r.raise_for_status()

    data = r.json()
    out = []
    for s in data.get("results", []):
        out.append({
            "id": s["id"],
            "name": s["name"],
            "duration": s["duration"],
            "license": s.get("license", ""),
            "username": s.get("username", ""),
            "tags": s.get("tags", []),
            "preview_url": s["previews"].get("preview-hq-mp3")
                           or s["previews"].get("preview-lq-mp3"),
        })
    return out


def random_sample(query: str, min_duration: float = 1.0,
                  max_duration: float = 30.0) -> dict:
    samples = search_samples(query, limit=30,
                             min_duration=min_duration,
                             max_duration=max_duration)
    if not samples:
        return None
    return random.choice(samples)


def download_sample(sample: dict, dest_dir: str) -> Path:
    safe_name = "".join(c for c in sample["name"][:40]
                        if c.isalnum() or c in " -_") or f"sample_{sample['id']}"
    dest = Path(dest_dir) / f"{sample['id']}_{safe_name}.mp3"
    dest.parent.mkdir(parents=True, exist_ok=True)

    r = requests.get(sample["preview_url"], stream=True, timeout=30)
    r.raise_for_status()

    with open(dest, "wb") as f:
        for chunk in r.iter_content(chunk_size=65536):
            if chunk:
                f.write(chunk)

    return dest


def filter_by_license(samples: list, allowed: list = None) -> list:
    if allowed is None:
        allowed = ["creativecommons.org/publicdomain",
                   "creativecommons.org/licenses/by/"]
    return [s for s in samples
            if any(a in s["license"] for a in allowed)]