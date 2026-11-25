# Vanity onion key generator

`generate-vanity-onion.sh` generates Tor v3 onion service keys whose addresses
start with chosen prefixes. It uses [`honion`](https://github.com/Splinters-io/honion)
on an NVIDIA GPU, builds it from a pinned commit with Nix, and writes the Tor
key files without putting plaintext secrets in the Nix store or git.

## Requirements

- Linux with an NVIDIA GPU and working driver (`nvidia-smi` must work)
- `nix` with flake support
- `nix-secrets` only if using `--import`

The script starts a temporary `nix shell` containing Rust, Git, and CUDA
NVRTC. It automatically sets `NIXPKGS_ALLOW_UNFREE=1` for the CUDA runtime.

## Usage

Run from anywhere for generation; paths are relative to the current directory.
Use `--import` from the repository root so `nix-secrets` can find the flake:

```sh
# Print estimates only
./scripts/generate-vanity-onion.sh --dry-run

# Generate the three default prefixes: thatsillyman, anas, spacebar
./scripts/generate-vanity-onion.sh

# Include the very long prefix (requires explicit confirmation)
./scripts/generate-vanity-onion.sh --all

# Include it without prompting
./scripts/generate-vanity-onion.sh --all --yes

# Generate one prefix and import its secret key into nix-secrets
./scripts/generate-vanity-onion.sh --import --host kurisu spacebar
```

## Prefix difficulty

Each prefix character adds about 5 bits of work. Measured on a GTX 1660 Ti
at roughly `330-345M addresses/s`:

| Prefix | Characters | Expected keys | Expected time |
| --- | ---: | ---: | ---: |
| `anas` | 4 | ~1.05M | instant |
| `spacebar` | 8 | ~1.10T | ~55 minutes |
| `thatsillyman` | 12 | ~1.15e18 | ~110 years |

Because `thatsillyman` is impractical, the script skips any prefix whose
expected search exceeds 24 hours unless `--all` is given. With `--all`, it
still prompts unless `--yes` is also given.

The search is memoryless, so the expected time is a mean, not a deadline:
about 63% of searches finish by the estimate and 95% by three times it.

## Options

| Option | Description |
| --- | --- |
| `-o, --out DIR` | Output directory; default `./vanity-onion-keys` |
| `--host HOST` | Host name used in `nix-secrets` paths; default `kurisu` |
| `--rate RATE` | Search rate in addresses/sec; skips GPU calibration |
| `--import` | Pipe each secret key into `nix-secrets edit` |
| `--all` | Allow prefixes with an expected search over 24 hours |
| `-y, --yes` | Do not prompt before long searches |
| `--dry-run` | Print estimates and exit |
| `-h, --help` | Print help |

Prefixes are positional arguments. With no prefixes given, the script uses
`thatsillyman`, `anas`, and `spacebar`. Prefixes must be 4-12 characters from
the Tor v3 base32 alphabet: `a-z` and `2-7`. Digits `0`, `1`, `8`, and `9` do
not exist in onion addresses.

## Output

For each generated prefix, the script writes:

```text
vanity-onion-keys/
  <address>.onion/
    hostname
    hs_ed25519_public_key
    hs_ed25519_secret_key
```

The output directory is created with mode `0700` and secret keys are set to
`0600`. It also prints a suggested host configuration, for example:

```nix
sites.spacebar = {
  enable = true;
  port = 80;
  targetPort = 8080;
  keySecret = "tor/kurisu/sites/spacebar/keys";
};
```

Use that `keySecret` in `hosts/kurisu.nix` when enabling the onion service.
The `.onion` address is derived from `hs_ed25519_secret_key`, so back the key
up: replacing it changes the address.

If `--import` is used, each key is encrypted directly into `nix-secrets` at:

```text
tor/<host>/sites/<prefix>/keys
```

## Calibration and cache

On the first normal run, the script generates an `anas` key to measure the
GPU's real search rate. If `anas` is one of the requested prefixes, that
calibration result is kept as the final `anas` key. Pass `--rate` to skip
calibration.

The honion source and release binary are cached at:

```text
~/.cache/onion-vanity/honion-<commit>/
```

## Security

A vanity prefix is cosmetic, not authentication. An attacker can generate a
lookalike address with the same prefix. Always verify the full `.onion`
address out of band.

Generated private keys are sensitive. Do not commit the output directory or
copy `hs_ed25519_secret_key` into the Nix store. Prefer `--import`, or back up
the key file securely and remove the plaintext copy when finished.
