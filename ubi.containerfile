ARG DISTRO_VERSION=9

# warning: Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag
# hadolint ignore=DL3007
FROM docker.io/alpine/git:latest AS downloader
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Download and Install the latest version of HadoLint
RUN <<EORUN
GITHUB_RELEASE_VERSION=$(
  git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/hadolint/hadolint.git \
  | grep -oE 'refs/tags/v?(\d+(\.\d+)?(\.\d+)?)$' \
  | tail -n 1 \
  | cut -d '/' -f 3
)
wget -q "https://github.com/hadolint/hadolint/releases/download/${GITHUB_RELEASE_VERSION}/hadolint-Linux-x86_64" -O "/usr/local/bin/hadolint"
chmod +x "/usr/local/bin/hadolint"
EORUN

# warning: Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag
# hadolint ignore=DL3007
FROM registry.access.redhat.com/ubi${DISTRO_VERSION}/ubi:latest
LABEL org.opencontainers.image.source="https://github.com/djarbz/ubi-podman"
LABEL org.opencontainers.image.description="A UBI image with Podman tooling for use in Github Workflows."
LABEL org.opencontainers.image.licenses="MIT"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install container tools
# warning: Specify version with `dnf install -y <package>-<version>`
# hadolint ignore=DL3041
RUN <<EORUN
dnf -y install podman buildah skopeo jq git gettext
dnf clean all
rm -rf /var/cache /var/log /var/lib/dnf /var/lib/rhsm
EORUN

# warning: Pin versions in pip. Instead of `pip install <package>` use `pip install <package>==<version>` or `pip install --requirement <requirements file>`
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --root-user-action=ignore pykickstart


COPY --from=downloader /usr/local/bin/hadolint /usr/local/bin/hadolint
