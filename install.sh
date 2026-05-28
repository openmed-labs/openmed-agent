#!/usr/bin/env bash

set -euo pipefail

OPENMED_REPO="${OPENMED_INSTALL_REPO:-${OPENMED_RELEASE_REPO:-openmed-labs/openmed-agents}}"
OPENMED_INSTALL_DIR="${OPENMED_INSTALL_DIR:-$HOME/.local/bin}"
OPENMED_SHARE_DIR="${OPENMED_SHARE_DIR:-$HOME/.local/share/openmed}"
OPENMED_RELEASE_BASE_URL="${OPENMED_RELEASE_BASE_URL:-}"
REQUESTED_VERSION="${1:-latest}"
TELEMETRY_ENDPOINT=""
TELEMETRY_TARGET=""
TELEMETRY_REQUESTED_VERSION="$REQUESTED_VERSION"
TELEMETRY_RESOLVED_VERSION=""
TELEMETRY_RELEASE_SLUG=""
TELEMETRY_ARTIFACT=""


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
        if [[ "$block" =~ \"${field}\":([0-9]+) ]]; then
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


validate_archive_name() {
    local value="$1"
    local version="$2"
    local target="$3"
    local expected="openmed-${version}-${target}.tar.gz"

    if [ "$value" != "$expected" ]; then
        echo "Release manifest has invalid archive name for ${target}: ${value}" >&2
        exit 1
    fi
}


validate_release_component() {
    local value="$1"
    local label="$2"

    if [[ ! "$value" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]]; then
        echo "Release manifest has invalid ${label}: ${value}" >&2
        exit 1
    fi
}


validate_sha256() {
    local value="$1"

    if [[ ! "$value" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo "Release manifest has invalid sha256 checksum." >&2
        exit 1
    fi
}


validate_positive_size() {
    local value="$1"

    if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "Release manifest has invalid archive size." >&2
        exit 1
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

verify_linux_signature() {
    local archive="$1"
    local sig_url="$2"

    if [ "${OPENMED_SKIP_SIG_VERIFY:-}" = "1" ]; then
        echo "warning: OPENMED_SKIP_SIG_VERIFY=1; skipping Linux signature verification." >&2
        return 0
    fi

    if ! have_cmd gpg; then
        echo "warning: gpg not installed; cannot verify signature. Continuing." >&2
        return 0
    fi

    local sig_path="${archive}.asc"
    if ! download_to_file "$sig_url" "$sig_path"; then
        echo "error: signature download failed; cannot verify Linux signature." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        exit 1
    fi

    local key_tmp
    if ! key_tmp="$(mktemp "${TMPDIR:-/tmp}/openmed-release.pubkey.XXXXXX")"; then
        echo "error: public release key temp file creation failed; cannot verify Linux signature." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        exit 1
    fi
    if ! download_to_file "https://install.openmed.life/openmed-release.pubkey.asc" "$key_tmp"; then
        echo "error: public release key download failed; cannot verify Linux signature." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        rm -f "$key_tmp"
        exit 1
    fi
    local key_text
    key_text="$(tr -d '\r' < "$key_tmp")"
    local begin_marker="-----BEGIN PGP PUBLIC KEY BLOCK-----"
    local end_marker="-----END PGP PUBLIC KEY BLOCK-----"
    local begin_count
    local end_count
    begin_count="$(grep -Fxc -- "$begin_marker" <<< "$key_text" || true)"
    end_count="$(grep -Fxc -- "$end_marker" <<< "$key_text" || true)"
    if [[ "$begin_count" -eq 0 ]]; then
        echo "error: public release key is not an ASCII-armored PGP public key." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        rm -f "$key_tmp"
        exit 1
    fi
    if [[ "$begin_count" -ne 1 || "$end_count" -ne 1 ]]; then
        echo "error: public release key must contain exactly one ASCII-armored PGP public key block." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        rm -f "$key_tmp"
        exit 1
    fi

    local key_dir
    if ! key_dir="$(mktemp -d "${TMPDIR:-/tmp}/openmed-release-keyring.XXXXXX")"; then
        echo "error: public release keyring temp directory creation failed; cannot verify Linux signature." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        rm -f "$key_tmp"
        exit 1
    fi
    chmod 700 "$key_dir"
    local keyring="$key_dir/openmed-release.gpg"
    if ! gpg --batch --homedir "$key_dir" --no-default-keyring --keyring "$keyring" --import "$key_tmp"; then
        echo "error: public release key import failed; cannot verify Linux signature." >&2
        echo "       set OPENMED_SKIP_SIG_VERIFY=1 only for an emergency or air-gapped install." >&2
        rm -rf "$key_dir" "$key_tmp"
        exit 1
    fi
    rm -f "$key_tmp"

    if ! gpg --batch --homedir "$key_dir" --no-default-keyring --keyring "$keyring" --verify "$sig_path" "$archive" 2>/dev/null; then
        echo "error: signature verification failed for $archive" >&2
        echo "       refusing to install a modified tarball" >&2
        rm -rf "$key_dir"
        exit 1
    fi
    rm -rf "$key_dir"
    echo "Linux signature verified."
}


file_size_bytes() {
    local path="$1"

    if stat -c%s "$path" >/dev/null 2>&1; then
        stat -c%s "$path"
        return
    fi

    if stat -f%z "$path" >/dev/null 2>&1; then
        stat -f%z "$path"
        return
    fi

    echo "stat is required to verify release archive size." >&2
    exit 1
}


path_contains_install_dir() {
    case ":$PATH:" in
        *":${OPENMED_INSTALL_DIR}:"*) return 0 ;;
        *) return 1 ;;
    esac
}


clear_macos_quarantine() {
    local path="$1"

    if [ "$(uname -s)" != "Darwin" ]; then
        return
    fi
    if ! have_cmd xattr; then
        return
    fi

    xattr -dr com.apple.quarantine "$path" >/dev/null 2>&1 || true
}


install_linux_onefile() {
    local archive_path="$1"
    local expected_binary_name="$2"
    local extract_dir="$3"
    local installed_path="$4"
    local archive_members="$5"

    if [ "$archive_members" != "$expected_binary_name" ]; then
        echo "Release archive must contain exactly ${expected_binary_name}." >&2
        exit 1
    fi

    tar -xzf "$archive_path" -C "$extract_dir" "$expected_binary_name"
    install -m 0755 "${extract_dir}/${expected_binary_name}" "$installed_path"
    clear_macos_quarantine "$installed_path"
}


install_macos_standalone() {
    local archive_path="$1"
    local version="$2"
    local extract_dir="$3"
    local installed_path="$4"
    local archive_members="$5"
    local versioned_dir="${OPENMED_SHARE_DIR}/openmed-${version}"
    local invalid_members

    invalid_members="$(printf '%s\n' "$archive_members" | grep -Ev '^openmed\.dist(/|$)' || true)"
    if [ -n "$invalid_members" ]; then
        echo "Release archive must contain only openmed.dist/ for macOS." >&2
        echo "$invalid_members" >&2
        exit 1
    fi

    tar -xzf "$archive_path" -C "$extract_dir"
    if [ ! -f "${extract_dir}/openmed.dist/openmed" ]; then
        echo "Release archive did not contain openmed.dist/openmed." >&2
        exit 1
    fi

    mkdir -p "$OPENMED_SHARE_DIR" "$OPENMED_INSTALL_DIR"
    find "$OPENMED_SHARE_DIR" -maxdepth 1 -type d -name 'openmed-[0-9]*' -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$versioned_dir"
    mv "${extract_dir}/openmed.dist" "$versioned_dir"
    chmod 0755 "${versioned_dir}/openmed"
    clear_macos_quarantine "$versioned_dir"

    rm -f "$installed_path"
    ln -s "${versioned_dir}/openmed" "$installed_path"
}


telemetry_endpoint_for_base_url() {
    local base_url="$1"

    case "$base_url" in
        http://*/r/*|https://*/r/*)
            echo "${base_url%%/r/*}/v1/install-events"
            ;;
        *)
            echo ""
            ;;
    esac
}


telemetry_release_slug_for_base_url() {
    local base_url="$1"

    case "$base_url" in
        http://*/r/*|https://*/r/*)
            echo "${base_url##*/}"
            ;;
        *)
            echo ""
            ;;
    esac
}


telemetry_safe_json_value() {
    local value="$1"

    if [[ "$value" =~ ^[A-Za-z0-9._+-]+$ ]]; then
        echo "$value"
        return
    fi
    echo ""
}


send_install_telemetry() {
    local event_type="$1"
    local payload

    if [ -z "$TELEMETRY_ENDPOINT" ]; then
        return 0
    fi

    payload="$(printf '{"event_type":"%s","installer":"install.sh","platform_family":"unix","target":"%s","requested_version":"%s","resolved_version":"%s","release_slug":"%s","artifact":"%s"}' \
        "$event_type" \
        "$(telemetry_safe_json_value "$TELEMETRY_TARGET")" \
        "$(telemetry_safe_json_value "$TELEMETRY_REQUESTED_VERSION")" \
        "$(telemetry_safe_json_value "$TELEMETRY_RESOLVED_VERSION")" \
        "$(telemetry_safe_json_value "$TELEMETRY_RELEASE_SLUG")" \
        "$(telemetry_safe_json_value "$TELEMETRY_ARTIFACT")")"

    if have_cmd curl; then
        curl -fsS -m 2 -o /dev/null \
            -H "Content-Type: application/json" \
            -X POST \
            --data "$payload" \
            "$TELEMETRY_ENDPOINT" >/dev/null 2>&1 || true
        return 0
    fi

    if have_cmd wget; then
        wget -q -O /dev/null \
            --timeout=2 \
            --header="Content-Type: application/json" \
            --post-data="$payload" \
            "$TELEMETRY_ENDPOINT" >/dev/null 2>&1 || true
    fi
}


main() {
    local target
    local base_url
    local manifest_url
    local manifest_json
    local archive_name
    local binary_name
    local expected_binary_name
    local expected_sha
    local expected_size
    local version
    local tmp_dir
    local archive_path
    local extract_dir
    local installed_path
    local actual_sha
    local actual_size
    local archive_members

    target="$(detect_target)"
    base_url="$(release_base_url "$REQUESTED_VERSION")"
    manifest_url="${base_url}/openmed-manifest.json"
    TELEMETRY_TARGET="$target"
    TELEMETRY_ENDPOINT="$(telemetry_endpoint_for_base_url "$base_url")"
    TELEMETRY_RELEASE_SLUG="$(telemetry_release_slug_for_base_url "$base_url")"
    tmp_dir=""
    trap 'status=$?; if [ "$status" -ne 0 ]; then send_install_telemetry "install_failure"; fi; if [ -n "$tmp_dir" ]; then rm -rf -- "$tmp_dir"; fi' EXIT

    echo "Resolving OpenMed release for ${target}..."
    manifest_json="$(download_to_stdout "$manifest_url")"

    archive_name="$(extract_json_field "$manifest_json" "$target" "archive")"
    binary_name="$(extract_json_field "$manifest_json" "$target" "binary")"
    expected_sha="$(extract_json_field "$manifest_json" "$target" "sha256")"
    expected_size="$(extract_json_field "$manifest_json" "$target" "size")"
    version="$(extract_version "$manifest_json")"

    if [ -z "$archive_name" ] || [ -z "$expected_sha" ] || [ -z "$expected_size" ]; then
        echo "No complete release asset found for target ${target}." >&2
        exit 1
    fi
    if [ -z "$version" ]; then
        echo "Release manifest is missing version." >&2
        exit 1
    fi
    validate_release_component "$version" "version"
    validate_release_component "$target" "target"
    validate_archive_name "$archive_name" "$version" "$target"
    validate_sha256 "$expected_sha"
    validate_positive_size "$expected_size"
    if [ -z "$binary_name" ]; then
        binary_name="openmed"
    fi
    TELEMETRY_RESOLVED_VERSION="$version"
    TELEMETRY_ARTIFACT="$archive_name"
    send_install_telemetry "install_resolved"
    expected_binary_name="openmed"
    if [ "$binary_name" != "$expected_binary_name" ]; then
        echo "Release manifest has invalid binary name for ${target}: ${binary_name}" >&2
        exit 1
    fi

    tmp_dir="$(mktemp -d)"

    archive_path="${tmp_dir}/${archive_name}"
    extract_dir="${tmp_dir}/extract"
    mkdir -p "$extract_dir" "$OPENMED_INSTALL_DIR"

    download_to_file "${base_url}/${archive_name}" "$archive_path"

    actual_size="$(file_size_bytes "$archive_path")"
    if [ "$actual_size" != "$expected_size" ]; then
        echo "Size verification failed for ${archive_name}: expected ${expected_size}, got ${actual_size}." >&2
        exit 1
    fi

    if [[ "$target" == linux-* ]]; then
        verify_linux_signature "$archive_path" "${base_url}/${archive_name}.asc"
    fi

    actual_sha="$(compute_sha256 "$archive_path")"
    if [ "$actual_sha" != "$expected_sha" ]; then
        echo "Checksum verification failed for ${archive_name}." >&2
        exit 1
    fi

    installed_path="${OPENMED_INSTALL_DIR}/openmed"
    archive_members="$(tar -tzf "$archive_path")"
    case "$target" in
        darwin-*)
            install_macos_standalone "$archive_path" "$version" "$extract_dir" "$installed_path" "$archive_members"
            ;;
        linux-*)
            install_linux_onefile "$archive_path" "$expected_binary_name" "$extract_dir" "$installed_path" "$archive_members"
            ;;
        *)
            echo "Unsupported release target for install: ${target}" >&2
            exit 1
            ;;
    esac

    echo "Installed OpenMed ${version:-unknown} to ${installed_path}"
    if [[ "$target" == darwin-* ]]; then
        echo "  Distribution: ${OPENMED_SHARE_DIR}/openmed-${version}"
    fi
    "$installed_path" --version || true
    send_install_telemetry "install_success"

    if ! path_contains_install_dir; then
        echo
        echo "Add ${OPENMED_INSTALL_DIR} to your PATH:"
        echo "  export PATH=\"${OPENMED_INSTALL_DIR}:\$PATH\""
    fi
    rm -rf -- "$tmp_dir"
    tmp_dir=""
    trap - EXIT
}


main "$@"
