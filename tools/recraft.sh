#!/bin/bash
# Recraft API from the Mac (Louis' API credits). The key lives in ~/.recraft_api_key (chmod 600, outside the repo); this
# script reads it into a header file descriptor and never prints it.
#
#   scripts/recraft.sh me                                          credits left
#   scripts/recraft.sh gen <out-prefix> <model> <size> <n> <prompt> [style-id]
#                                                                  text to image; writes <out-prefix>-1.png …
#   scripts/recraft.sh style <model> <prompt> <image> [image …]    custom style from references; prints its id
#   scripts/recraft.sh rmbg <in> <out.png>                         remove background
#   scripts/recraft.sh i2i <in> <out-prefix> <model> <strength> <n> <prompt> [style-id]
#   scripts/recraft.sh vector <in> <out.svg>                       vectorize
#   scripts/recraft.sh upscale <in> <out.png>                      crisp upscale
#   scripts/recraft.sh erase <in> <mask.png> <out.png>             erase the mask's white region (the painting runs on)
#   scripts/recraft.sh inpaint <in> <mask.png> <out-prefix> <model> <n> <prompt> [style-id]
#                                                                  repaint the mask's white region (also outpainting a padded canvas)
#
# Models: recraftv4_1 (default), recraftv4_1_pro, recraftv4_1_vector, recraftv4_styles, recraftv3 …
# Sizes: "1:1", "16:9", "2:1" … or WxH. Every call is logged (without the key) to build/recraft/log.jsonl.
set -euo pipefail
cd "$(dirname "$0")/.."
# python's downloader fails the TLS check on this Mac without it, after the image is already paid for (08.11.: 70 credits).
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/cert.pem}"
KEY_FILE="$HOME/.recraft_api_key"
API=https://external.api.recraft.ai/v1
LOG=build/recraft/log.jsonl
mkdir -p build/recraft
[ -s "$KEY_FILE" ] || { echo "no key in $KEY_FILE" >&2; exit 2; }

auth() { printf 'Authorization: Bearer %s' "$(cat "$KEY_FILE")"; }

call() { # method path [curl args…] → response body on stdout
    local method=$1 path=$2; shift 2
    curl -sS --fail-with-body -X "$method" -H @<(auth) "$@" "$API$path"
}

log() { python3 -c 'import json,sys,time; d=json.loads(sys.argv[2]); d.pop("data",None); print(json.dumps({"t":time.strftime("%Y-%m-%d %H:%M:%S"),"op":sys.argv[1],"resp":d}))' "$1" "$2" >> "$LOG" 2>/dev/null || true; }

download() { # json-with-data[].url out-prefix
    python3 - "$1" "$2" <<'EOF'
import json, sys, urllib.request
resp = json.loads(sys.argv[1]); prefix = sys.argv[2]
items = resp.get("data") or ([resp["image"]] if "image" in resp else [])
for n, item in enumerate(items, 1):
    url = item.get("url")
    if not url: continue
    ext = ".svg" if url.split("?")[0].endswith(".svg") else ".png"
    path = f"{prefix}-{n}{ext}" if len(items) > 1 or not prefix.endswith((".png", ".svg")) else prefix
    if not path.endswith((".png", ".svg")): path += ext
    with urllib.request.urlopen(url) as r, open(path, "wb") as f: f.write(r.read())
    print(path)
EOF
}

case "${1:-}" in
me)
    call GET /users/me | python3 -c 'import json,sys; d=json.load(sys.stdin); print("credits:", d.get("credits"))' ;;
gen)
    out=$2 model=$3 size=$4 n=$5 prompt=$6 style=${7:-}
    body=$(python3 -c 'import json,sys; d={"prompt":sys.argv[1],"model":sys.argv[2],"size":sys.argv[3],"n":int(sys.argv[4]),"response_format":"url","image_format":"png"}
if sys.argv[5]: d["style_id"]=sys.argv[5]
print(json.dumps(d))' "$prompt" "$model" "$size" "$n" "$style")
    resp=$(call POST /images/generations -H 'Content-Type: application/json' -d "$body") || { echo "$resp" >&2; exit 1; }
    log gen "$resp"; download "$resp" "$out" ;;
style)
    model=$2 prompt=$3; shift 3
    args=(-F "model=$model")
    [ -n "$prompt" ] && args+=(-F "prompt=$prompt")
    for f in "$@"; do args+=(-F "files=@$f"); done
    resp=$(call POST /styles "${args[@]}")
    log style "$resp"; echo "$resp" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("style id:", d.get("id"), "credits:", d.get("credits"))' ;;
rmbg)
    resp=$(call POST /images/removeBackground -F "file=@$2" -F response_format=url -F image_format=png)
    log rmbg "$resp"; download "$resp" "$3" ;;
i2i)
    in=$2 out=$3 model=$4 strength=$5 n=$6 prompt=$7 style=${8:-}
    args=(-F "image=@$in" -F "prompt=$prompt" -F "strength=$strength" -F "model=$model" -F "n=$n" -F response_format=url -F image_format=png)
    [ -n "$style" ] && args+=(-F "style_id=$style")
    resp=$(call POST /images/imageToImage "${args[@]}")
    log i2i "$resp"; download "$resp" "$out" ;;
upscale)
    resp=$(call POST /images/crispUpscale -F "file=@$2" -F response_format=url -F image_format=png)
    log upscale "$resp"; download "$resp" "$3" ;;
erase)
    resp=$(call POST /images/eraseRegion -F "image=@$2" -F "mask=@$3" -F response_format=url -F image_format=png) || { echo "$resp" >&2; exit 1; }
    log erase "$resp"; download "$resp" "$4" ;;
inpaint)
    in=$2 mask=$3 out=$4 model=$5 n=$6 prompt=$7 style=${8:-}
    args=(-F "image=@$in" -F "mask=@$mask" -F "prompt=$prompt" -F "model=$model" -F "n=$n" -F response_format=url -F image_format=png)
    [ -n "$style" ] && args+=(-F "style_id=$style")
    resp=$(call POST /images/inpaint "${args[@]}") || { echo "$resp" >&2; exit 1; }
    log inpaint "$resp"; download "$resp" "$out" ;;
vector)
    resp=$(call POST /images/vectorize -F "file=@$2" -F response_format=url)
    log vector "$resp"; download "$resp" "$3" ;;
*)
    sed -n '2,18p' "$0"; exit 2 ;;
esac
