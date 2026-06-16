ARG DISTRO_VERSION=9

# warning: Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag
# hadolint ignore=DL3007
FROM registry.access.redhat.com/ubi${DISTRO_VERSION}/ubi:latest
LABEL org.opencontainers.image.source="https://github.com/djarbz/ubi-podman"
LABEL org.opencontainers.image.description="A UBI image with Podman tooling for use in Github Workflows."
LABEL org.opencontainers.image.licenses="MIT"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ==========================================
# Install Standalone Binaries
# ==========================================
COPY --from=ghcr.io/hadolint/hadolint:latest /bin/hadolint /usr/local/bin/hadolint
COPY --from=docker.io/mvdan/shfmt:latest /bin/shfmt /usr/local/bin/shfmt
COPY --from=docker.io/koalaman/shellcheck:stable /bin/shellcheck /usr/local/bin/shellcheck

# ==========================================
# Install System Packages & GitHub CLI
# ==========================================
# warning: Specify version with `dnf install -y <package>-<version>`
# warning: Pin versions in pip. Instead of `pip install <package>` use `pip install <package>==<version>`
# hadolint ignore=DL3041,DL3013
RUN <<EORUN
# Add GitHub CLI repo
curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo -o /etc/yum.repos.d/github-cli.repo

# Install all packages in a single transaction
dnf -y install \
  podman \
  podman-docker \
  buildah \
  skopeo \
  fuse-overlayfs \
  jq \
  git \
  gettext \
  python3-pip \
  binutils \
  gh

# Clean up DNF caches to drastically reduce image size
dnf clean all
rm -rf /var/cache /var/log /var/lib/dnf /var/lib/rhsm

# Tell git to trust all directories, bypassing dubious ownership checks caused by Docker volume mounts in GitHub Actions
RUN git config --system --add safe.directory '*'

# Install python packages
PIP_ROOT_USER_ACTION=ignore pip install --no-cache-dir pykickstart systemdlint
EORUN
