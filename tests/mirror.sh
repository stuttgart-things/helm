#!/usr/bin/env bash
set -x

# Usage: ./mirror.sh TARGET_REGISTRY
# Example: ./mirror.sh ghcr.io/YOUR_USER

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 TARGET_REGISTRY"
    exit 1
fi

TARGET_REGISTRY="$1"
SOURCES_FILE="sources.yaml"

if [[ ! -f "$SOURCES_FILE" ]]; then
    echo "Error: $SOURCES_FILE not found"
    exit 1
fi

# Require yq and skopeo installed
command -v yq >/dev/null 2>&1 || { echo >&2 "yq required but not installed"; exit 1; }
command -v skopeo >/dev/null 2>&1 || { echo >&2 "skopeo required but not installed"; exit 1; }

# === FUNCTIONS ===

mirror_chart() {
    local chart_spec=$1
    local target_registry=$2

    # parse chart URL and version
    local chart url version
    if [[ "$chart_spec" =~ ^oci:// ]]; then
        # OCI format: oci://registry/repo/chart:version
        chart="$chart_spec"
        version="${chart_spec##*:}"
        url="$chart_spec"
        chart_name=$(basename "${chart%%:*}")
    else
        # classic Helm repo URL: https://charts.bitnami.com/bitnami/metallb:6.4.22
        url="${chart_spec%:*}"
        version="${chart_spec##*:}"
        chart_name=$(basename "$url")

        # Extract repo name from URL (e.g., bitnami)
        repo_name=$(basename "$(dirname "$url")")

        echo "Adding Helm repo $repo_name -> $url"
        helm repo add "$repo_name" "$url" || true
        helm repo update

        echo "Pulling $repo_name/$chart_name:$version ..."
        helm pull "$repo_name/$chart_name" --version "$version"
    fi

    echo "=== Mirroring chart: $chart_name:$version ==="

    # Pull chart as tgz
    helm pull "$url" --version "$version"
    tgz_file="${chart_name}-${version}.tgz"

    # Push to target OCI registry
    echo "Pushing $tgz_file → $target_registry/charts/$chart_name"
    helm push "$tgz_file" "oci://$target_registry/charts/$chart_name"

    rm -f "$tgz_file"
    echo
}

mirror_image() {
    local image=$1
    local target_registry=$2

    local image_name="${image%%:*}"
    local tag="${image##*:}"

    echo "=== Mirroring image: $image → $target_registry/$(basename "$image_name"):$tag ==="
    skopeo copy "docker://$image" "docker://$target_registry/$(basename "$image_name"):$tag"

    echo
}

# === MAIN ===

charts_count=$(yq e '.charts | length' "$SOURCES_FILE")
images_count=$(yq e '.images | length' "$SOURCES_FILE")

echo "Found $charts_count charts and $images_count images to mirror."

# Mirror charts
for i in $(seq 0 $((charts_count - 1))); do
    chart_spec=$(yq e ".charts[$i]" "$SOURCES_FILE")
    mirror_chart "$chart_spec" "$TARGET_REGISTRY"
done

# Mirror images
for i in $(seq 0 $((images_count - 1))); do
    image=$(yq e ".images[$i]" "$SOURCES_FILE")
    mirror_image "$image" "$TARGET_REGISTRY"
done

echo "✅ Done!"
