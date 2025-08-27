#!/usr/bin/env bash
set -x

TARGET_REGISTRY="$1"
SOURCES_FILE="$2"

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

    local chart_name url version tgz_file

    if [[ "$chart_spec" =~ ^oci:// ]]; then
        # OCI chart (oci://registry/repo/chart:version)
        version="${chart_spec##*:}"
        url="${chart_spec%:*}"             # strip :version
        chart_name=$(basename "$url")      # get "nginx"

        echo "=== Mirroring chart: $chart_name:$version ==="
        helm pull "$chart_spec" --version "$version"
        tgz_file="${chart_name}-${version}.tgz"

    else
        # Classic Helm repo chart (https://.../repo/chart:version)
        url="${chart_spec%:*}"
        version="${chart_spec##*:}"
        chart_name=$(basename "$url")
        repo_name=$(basename "$(dirname "$url")")

        echo "Adding Helm repo $repo_name -> $url"
        helm repo add "$repo_name" "$url" || true
        helm repo update

        echo "Pulling $repo_name/$chart_name:$version ..."
        helm pull "$repo_name/$chart_name" --version "$version"
        tgz_file="${chart_name}-${version}.tgz"
    fi

    # Push to target registry
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
