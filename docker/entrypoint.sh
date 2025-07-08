#!/bin/bash
set -eu

# Start Docker daemon in the background
/usr/local/bin/dockerd-entrypoint.sh > /var/log/dockerd/$(date +%s).log 2>&1 &

# Configure Git
git config --global advice.detachedHead "false"
git config --global user.name ${ACTOR}
git config --global user.email ${ACTOR}@example.com
git config --global core.compression 9
git config --global http.postBuffer 524288000

# Create cache directory if it doesn't exist
mkdir -p "${CACHES}"

# Parallel caching of GitHub Actions repositories
cache_repo() {
  local repo=$1
  local branch=$2
  local repo_dir="${CACHES}/${repo//\//-}@$branch"

  if [ -d "$repo_dir" ]; then
    echo "Cache hit for $repo $branch"
    return 0
  fi

  echo "Caching $repo $branch..."
  git clone --branch "$branch" "git@github.com:$repo.git" "$repo_dir"
  cd "$repo_dir" && git remote set-url origin "https://github.com/${repo}"
  echo "Cached $repo $branch"
}

# Extract repositories from workflow files and cache them in parallel
echo "Caching GitHub Actions repositories..."
export -f cache_repo
grep -rho "uses: *.*" /workflow/.github/workflows/*.yml \
  | awk -F'uses:' '{gsub(/^ +| +$/, "", $2); print $2}' \
  | grep -v "^${DIR_NAME}" \
  | grep -v '^$' \
  | sort -u \
  | awk -F'[@]' '{print $1, $2}' \
  | xargs -P 4 -n 2 bash -c 'cache_repo "$0" "$1"'

# Wait for Docker to be available
echo "Waiting for Docker to be available..."
until docker info >/dev/null 2>&1; do sleep 1; done

# Initialize Docker Compose services
cd /docker
echo "Starting Docker Compose services..."
docker compose down
# Use parallel build and pull for faster startup
docker compose up -d --wait --build --quiet-pull

# Build act-with-gh image with build cache optimization
echo "Building act-with-gh image..."
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t act-with-gh act-with-gh

# Set up logging for services
mkdir -p /var/log/docker
docker compose ps -a --services | while read svc; do
  docker compose logs -f "$svc" | grep -viE 'ping|healthcheck' > "/var/log/docker/$svc.log" 2>&1 &
done

# GPG
PASSPHRASE=$(openssl rand -base64 -hex 10)
cat > ~/gpg-batch.conf <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${ACTOR}
Name-Email: ${ACTOR}@example.com
Passphrase: $PASSPHRASE
%commit
EOF
gpg --batch --generate-key ~/gpg-batch.conf
KEY_ID=$(gpg --list-secret-keys --with-colons | grep '^sec' | head -n1 | cut -d: -f5)
gpg --armor --export-secret-keys --batch --pinentry-mode=loopback --yes --passphrase "$PASSPHRASE" "$KEY_ID" > ~/.gpgkey

# Substitute environment variables in the template
echo "Configuring act..."
ACTOR=${ACTOR:-""} \
TOKEN=${TOKEN:-""} \
CACHES=${CACHES:-""} \
PASSPHRASE=${PASSPHRASE:-""} \
envsubst < .actrc > ~/.actrc

echo "Initialization complete"
exec "$@"
