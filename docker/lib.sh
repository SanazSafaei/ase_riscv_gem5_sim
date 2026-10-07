# Shared helpers for sim.sh / studio.sh (sourced, not executed).
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Published multi-arch image (amd64 + arm64). Override with ASE_IMAGE to use another one.
IMAGE="${ASE_IMAGE:-ghcr.io/sanazsafaei/ase-riscv-gem5:latest}"
LOCAL_IMAGE="ase-riscv-gem5:local"

# Git Bash on Windows: stop it from rewriting container paths, and use a Windows-style mount path.
export MSYS_NO_PATHCONV=1
MOUNT="$(cd "$REPO" && (pwd -W 2>/dev/null || pwd))"

# On Linux, run as the current user so files in results/ and programs/ are not owned by root.
USER_ARGS=()
[[ "$(uname -s)" == "Linux" ]] && USER_ARGS=(--user "$(id -u):$(id -g)")

die() { echo "error: $*" >&2; exit 1; }

ensure_image() {
    command -v docker >/dev/null 2>&1 || die "Docker is not installed. See INSTALL_DOCKER.md."
    docker info >/dev/null 2>&1 || die "Docker is installed but not running. Start Docker Desktop and retry."
    [[ -f "$REPO/setup_default" ]] || die "setup_default not found: run this from the ase_riscv_gem5_sim repository."
    docker image inspect "$IMAGE" >/dev/null 2>&1 && return 0
    # A registry name (contains '/') is pulled; if that fails, fall back to a local build.
    if [[ "$IMAGE" == */* ]]; then
        echo "Downloading $IMAGE (one time, about 2 GB) ..."
        docker pull "$IMAGE" && return 0
        echo "Could not download the image; building it locally instead."
        IMAGE="$LOCAL_IMAGE"
        docker image inspect "$IMAGE" >/dev/null 2>&1 && return 0
    fi
    echo "Building the image $IMAGE (one time, can take 3-4 hours) ..."
    docker build -t "$IMAGE" -f "$REPO/docker/Dockerfile" "$REPO" || die "image build failed"
}
