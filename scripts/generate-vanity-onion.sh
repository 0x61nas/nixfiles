#!/usr/bin/env bash
# Generate Tor v3 vanity onion keys with honion (NVIDIA GPU).
#
# Examples:
#   ./scripts/generate-vanity-onion.sh --dry-run
#   ./scripts/generate-vanity-onion.sh anas spacebar
#   ./scripts/generate-vanity-onion.sh --all --yes
#   ./scripts/generate-vanity-onion.sh --import --host kurisu spacebar

set -euo pipefail

HONION_REPO="https://github.com/Splinters-io/honion.git"
HONION_COMMIT="0d915f80485e66924f64f440c67821705b5593f0"
DEFAULT_PREFIXES=(thatsillyman anas spacebar)
LONG_SEARCH_SECONDS=$((24 * 60 * 60))

usage() {
  cat <<'EOF'
Usage: generate-vanity-onion.sh [options] [prefix ...]

Default prefixes: thatsillyman anas spacebar

Options:
  -o, --out DIR       Result directory (default: ./vanity-onion-keys)
      --host HOST     Host name used for nix-secrets paths (default: kurisu)
      --rate RATE     Search rate in addresses/sec; skips calibration
      --import        Import each secret key with `nix-secrets edit`
      --all           Allow prefixes whose expected search exceeds 24 hours
  -y, --yes           Do not prompt before long searches
      --dry-run       Print estimates only
  -h, --help          Show this help

Notes:
  - Prefixes must be 4-12 lowercase base32 chars: a-z or 2-7.
  - The private keys never leave the result directory unless --import is used.
  - A vanity prefix is cosmetic; it does not authenticate the service.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

if [[ -z "${_ONION_VANITY_IN_NIX_SHELL:-}" ]]; then
  script_path=$(readlink -f "$0")
  export _ONION_VANITY_IN_NIX_SHELL=1
  exec env NIXPKGS_ALLOW_UNFREE=1 nix shell --impure \
    nixpkgs#rustc nixpkgs#cargo nixpkgs#git nixpkgs#cudaPackages.cuda_nvrtc^lib \
    -c "$script_path" "$@"
fi

out_dir="$PWD/vanity-onion-keys"
host="kurisu"
rate=""
do_import=false
assume_yes=false
allow_all=false
dry_run=false
prefixes=()

while (($#)); do
  case "$1" in
    -o|--out)
      out_dir=$2
      shift 2
      ;;
    --host)
      host=$2
      shift 2
      ;;
    --rate)
      rate=$2
      shift 2
      ;;
    --import)
      do_import=true
      shift
      ;;
    --all)
      allow_all=true
      shift
      ;;
    -y|--yes)
      assume_yes=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      prefixes+=("$@")
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      prefixes+=("$1")
      shift
      ;;
  esac
done

if ((${#prefixes[@]} == 0)); then
  prefixes=("${DEFAULT_PREFIXES[@]}")
fi

for prefix in "${prefixes[@]}"; do
  [[ "$prefix" =~ ^[a-z2-7]{4,12}$ ]] ||
    die "invalid prefix '$prefix': use 4-12 lowercase base32 chars (a-z, 2-7)"
done

[[ "$host" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid host name: $host"

command -v nvidia-smi >/dev/null 2>&1 ||
  die "nvidia-smi not found; this script currently requires an NVIDIA GPU"

gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
printf 'GPU: %s\n' "$gpu_name"

nvrtc_out=$(nix eval --impure --raw 'nixpkgs#cudaPackages.cuda_nvrtc.lib.outPath')
export LD_LIBRARY_PATH="/run/opengl-driver/lib:${nvrtc_out}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

expected_seconds() {
  local prefix=$1
  awk -v n="$((32 ** ${#prefix}))" -v r="$rate" \
    'BEGIN { printf "%.0f", n / r }'
}

human_duration() {
  awk -v s="$1" 'BEGIN {
    if (s < 60) printf "%.1fs", s
    else if (s < 3600) printf "%.1fm", s / 60
    else if (s < 86400) printf "%.1fh", s / 3600
    else if (s < 31536000) printf "%.1fd", s / 86400
    else printf "%.1fy", s / 31536000
  }'
}

build_honion() {
  local cache="$HOME/.cache/onion-vanity/honion-$HONION_COMMIT"
  local src="$cache/src"
  local bin="$cache/honion"

  if [[ ! -x "$bin" ]]; then
    printf 'Building honion from %s\n' "$HONION_COMMIT" >&2
    mkdir -p "$cache"
    if [[ ! -d "$src/.git" ]]; then
      git clone --quiet "$HONION_REPO" "$src" || {
        rm -rf "$src"
        die "failed to clone honion from $HONION_REPO"
      }
    fi
    (
      cd "$src"
      git fetch --quiet origin main || true
      git checkout --quiet "$HONION_COMMIT"
      CARGO_TARGET_DIR="$cache/target" cargo build --release
    )
    cp "$cache/target/release/honion" "$bin"
  fi

  printf '%s\n' "$bin"
}

parse_rate() {
  local log=$1
  local token num unit mult

  token=$(grep -oE '[0-9]+(\.[0-9]+)?[KMGT]?/s' "$log" | tail -n1 || true)
  [[ -n "$token" ]] || return 1

  num=${token%/s}
  unit=$(printf '%s' "$num" | tr -cd 'KMGT')
  num=${num%"$unit"}

  case "$unit" in
    '') mult=1 ;;
    K) mult=1000 ;;
    M) mult=1000000 ;;
    G) mult=1000000000 ;;
    T) mult=1000000000000 ;;
    *) return 1 ;;
  esac

  awk -v n="$num" -v m="$mult" 'BEGIN { printf "%.0f", n * m }'
}

declare -A found_dir=()

if [[ "$dry_run" == false ]]; then
  honion_bin=$(build_honion)
  mkdir -p "$out_dir"
  chmod 700 "$out_dir"

  if [[ -z "$rate" ]]; then
    calib_dir=$(mktemp -d "$out_dir/.calibrate.XXXXXX")
    printf 'Calibrating with prefix anas...\n'
    "$honion_bin" search --prefix anas --out "$calib_dir" --count 1 2>&1 |
      tee "$calib_dir/search.log"
    rate=$(parse_rate "$calib_dir/search.log") ||
      die "could not determine search rate; pass --rate explicitly"

    calib_result=$(find "$calib_dir" -mindepth 1 -maxdepth 1 -type d -name '*.onion' | head -n1 || true)
    if [[ -n "$calib_result" ]]; then
      for prefix in "${prefixes[@]}"; do
        if [[ "$prefix" == "anas" ]]; then
          mv "$calib_result" "$out_dir"/
          found_dir[anas]="$out_dir/$(basename "$calib_result")"
          break
        fi
      done
    fi
    rm -rf "$calib_dir"
  fi

  [[ "$rate" =~ ^[1-9][0-9]*$ ]] || die "invalid search rate: $rate"
  printf 'Search rate: %s addresses/sec\n' "$rate"
fi

if [[ "$dry_run" == true ]]; then
  rate=${rate:-12514000000}
  printf 'Using assumed rate %s/s (pass --rate for your GPU)\n' "$rate"
fi

for prefix in "${prefixes[@]}"; do
  seconds=$(expected_seconds "$prefix")
  printf '%-14s %2d chars  %20s  %s expected trials\n' \
    "$prefix" "${#prefix}" "$(human_duration "$seconds")" "$((32 ** ${#prefix}))"

  if [[ "$dry_run" == true ]]; then
    continue
  fi

  if [[ -n "${found_dir[$prefix]:-}" ]]; then
    continue
  fi

  if ((seconds > LONG_SEARCH_SECONDS)); then
    if [[ "$allow_all" == false ]]; then
      printf 'Skipping %s: expected search exceeds 24 hours. Re-run with --all to include it.\n' \
        "$prefix" >&2
      continue
    fi
    if [[ "$assume_yes" == false ]]; then
      read -r -p "Generate $prefix anyway? [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]] || continue
    fi
  fi

  search_dir="$out_dir/.search-$prefix"
  rm -rf "$search_dir"
  mkdir -p "$search_dir"
  printf 'Searching for prefix %s...\n' "$prefix"
  "$honion_bin" search --prefix "$prefix" --out "$search_dir" --count 1 2>&1 |
    tee "$search_dir/search.log"

  result=$(find "$search_dir" -mindepth 1 -maxdepth 1 -type d -name '*.onion' | head -n1 || true)
  [[ -n "$result" ]] || die "no key directory produced for $prefix"
  mv "$result" "$out_dir"/
  found_dir[$prefix]="$out_dir/$(basename "$result")"
  rm -rf "$search_dir"
done

if [[ "$dry_run" == true ]]; then
  exit 0
fi

printf '\nResults:\n'
for prefix in "${prefixes[@]}"; do
  dir=${found_dir[$prefix]:-}
  if [[ -z "$dir" ]]; then
    printf '  %-14s SKIPPED\n' "$prefix"
    continue
  fi

  address=$(cat "$dir/hostname")
  [[ "$address" == "$prefix"* && "$address" == *.onion ]] ||
    die "generated address '$address' does not match prefix '$prefix'"

  chmod 700 "$dir"
  chmod 600 "$dir/hs_ed25519_secret_key"

  secret="tor/$host/sites/$prefix/keys"
  printf '  %-14s %s\n' "$prefix" "$address"
  printf '    secret key: %s\n' "$dir/hs_ed25519_secret_key"
  printf '    keySecret:  %s\n' "$secret"

  if [[ "$do_import" == true ]]; then
    printf '    importing into nix-secrets...\n'
    EDITOR=- nix-secrets -f "git+file://$PWD#$host" edit "$secret" \
      < "$dir/hs_ed25519_secret_key"
  fi
done

printf '\nHost config example for the generated site:\n'
for prefix in "${prefixes[@]}"; do
  [[ -n "${found_dir[$prefix]:-}" ]] || continue
  cat <<EOF
  sites.$prefix = {
    enable = true;
    port = 80;
    targetPort = 8080;
    keySecret = "tor/$host/sites/$prefix/keys";
  };
EOF
done
