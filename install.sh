#!/usr/bin/env bash

set -euo pipefail

OPENMED_REPO="${OPENMED_INSTALL_REPO:-openmed-labs/openmed-agent}"
OPENMED_INSTALL_DIR="${OPENMED_INSTALL_DIR:-$HOME/.local/bin}"
OPENMED_RELEASE_BASE_URL="${OPENMED_RELEASE_BASE_URL:-}"
REQUESTED_VERSION="${1:-latest}"


have_cmd() {
    command -v "$1" >/dev/null 2>&1
}


download_to_file() {
    local url="$1"
    local output="$2"

    if have_cmd curl; then
        curl -fsSL -o "$output" "$url"
        return
    fi

    if have_cmd wget; then
        wget -q -O "$output" "$url"
        return
    fi

    echo "Either curl or wget is required." >&2
    exit 1
}


download_to_stdout() {
    local url="$1"

    if have_cmd curl; then
        curl -fsSL "$url"
        return
    fi

    if have_cmd wget; then
        wget -q -O - "$url"
        return
    fi

    echo "Either curl or wget is required." >&2
    exit 1
}


normalize_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x64" ;;
        arm64|aarch64) echo "arm64" ;;
        *)
            echo "Unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}


detect_linux_libc() {
    if have_cmd ldd && ldd --version 2>&1 | grep -qi musl; then
        echo "musl"
        return
    fi

    if [ -e /lib/libc.musl-x86_64.so.1 ] || [ -e /lib/libc.musl-aarch64.so.1 ]; then
        echo "musl"
        return
    fi

    echo "gnu"
}


detect_target() {
    local os
    local arch

    os="$(uname -s)"
    arch="$(normalize_arch)"

    if [ "$os" = "Darwin" ] && [ "$arch" = "x64" ]; then
        if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
            arch="arm64"
        fi
    fi

    case "$os" in
        Darwin)
            echo "darwin-${arch}"
            ;;
        Linux)
            echo "linux-${arch}-$(detect_linux_libc)"
            ;;
        *)
            echo "Unsupported operating system: $os" >&2
            exit 1
            ;;
    esac
}


normalize_version_tag() {
    local value="$1"
    if [ -z "$value" ] || [ "$value" = "latest" ] || [ "$value" = "stable" ]; then
        echo ""
        return
    fi

    if [[ "$value" == v* ]]; then
        echo "$value"
        return
    fi

    echo "v${value}"
}


release_base_url() {
    local requested="$1"
    local tag

    if [ -n "$OPENMED_RELEASE_BASE_URL" ]; then
        echo "${OPENMED_RELEASE_BASE_URL%/}"
        return
    fi

    tag="$(normalize_version_tag "$requested")"
    if [ -z "$tag" ]; then
        echo "https://github.com/${OPENMED_REPO}/releases/latest/download"
        return
    fi

    echo "https://github.com/${OPENMED_REPO}/releases/download/${tag}"
}


extract_json_field() {
    local json="$1"
    local target="$2"
    local field="$3"

    if have_cmd jq; then
        printf '%s' "$json" | jq -r ".assets[\"${target}\"].${field} // empty"
        return
    fi

    local compact
    compact="$(printf '%s' "$json" | tr -d '\n\r\t ')"

    if [[ "$compact" =~ \"${target}\":\{([^}]*)\} ]]; then
        local block="${BASH_REMATCH[1]}"
        if [[ "$block" =~ \"${field}\":\"([^\"]+)\" ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    fi
}


extract_version() {
    local json="$1"

    if have_cmd jq; then
        printf '%s' "$json" | jq -r '.version // empty'
        return
    fi

    local compact
    compact="$(printf '%s' "$json" | tr -d '\n\r\t ')"
    if [[ "$compact" =~ \"version\":\"([^\"]+)\" ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}


compute_sha256() {
    local path="$1"

    if have_cmd sha256sum; then
        sha256sum "$path" | cut -d' ' -f1
        return
    fi

    if have_cmd shasum; then
        shasum -a 256 "$path" | cut -d' ' -f1
        return
    fi

    echo "sha256sum or shasum is required." >&2
    exit 1
}


path_contains_install_dir() {
    case ":$PATH:" in
        *":${OPENMED_INSTALL_DIR}:"*) return 0 ;;
        *) return 1 ;;
    esac
}


main() {
    local target
    local base_url
    local manifest_url
    local manifest_json
    local archive_name
    local expected_sha
    local version
    local tmp_dir
    local archive_path
    local extract_dir
    local installed_path
    local actual_sha

    target="$(detect_target)"
    base_url="$(release_base_url "$REQUESTED_VERSION")"
    manifest_url="${base_url}/openmed-manifest.json"

    echo "Resolving OpenMed release for ${target}..."
    manifest_json="$(download_to_stdout "$manifest_url")"

    archive_name="$(extract_json_field "$manifest_json" "$target" "archive")"
    expected_sha="$(extract_json_field "$manifest_json" "$target" "sha256")"
    version="$(extract_version "$manifest_json")"

    if [ -z "$archive_name" ] || [ -z "$expected_sha" ]; then
        echo "No release asset found for target ${target}." >&2
        exit 1
    fi

    tmp_dir="$(mktemp -d)"
    trap "rm -rf -- '$tmp_dir'" EXIT

    archive_path="${tmp_dir}/${archive_name}"
    extract_dir="${tmp_dir}/extract"
    mkdir -p "$extract_dir" "$OPENMED_INSTALL_DIR"

    download_to_file "${base_url}/${archive_name}" "$archive_path"

    actual_sha="$(compute_sha256 "$archive_path")"
    if [ "$actual_sha" != "$expected_sha" ]; then
        echo "Checksum verification failed for ${archive_name}." >&2
        exit 1
    fi

    tar -xzf "$archive_path" -C "$extract_dir"

    installed_path="${OPENMED_INSTALL_DIR}/openmed"
    install -m 0755 "${extract_dir}/openmed" "$installed_path"

    echo "Installed OpenMed ${version:-unknown} to ${installed_path}"
    "$installed_path" --version || true

    if ! path_contains_install_dir; then
        echo
        echo "Add ${OPENMED_INSTALL_DIR} to your PATH:"
        echo "  export PATH=\"${OPENMED_INSTALL_DIR}:\$PATH\""
    fi
}


main "$@"
