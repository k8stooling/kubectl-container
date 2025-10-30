# Stage 1: Builder
# Use debian:bookworm-slim to build and install all tools.
FROM docker.io/debian:bookworm-slim AS builder

USER root

# Install necessary build tools and ca-certificates for curl/https.
# Use --no-install-recommends to keep the builder stage as lean as possible.
# Clean up apt lists to reduce size.
RUN apt-get update && apt-get upgrade -q -y \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates busybox-static \
    && rm -rf /var/lib/apt/lists/*

# Install Helm (installs to /usr/local/bin by default)
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
RUN set -x; \
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt); \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    mv kubectl /usr/local/bin/kubectl; \
    chmod 755 /usr/local/bin/kubectl

# Stage 2: Final distroless image
# Using distroless/base-debian12 because helm, uv, and kubectl are dynamically linked
# and require a C standard library (glibc), which is provided by this image.
FROM gcr.io/distroless/cc-debian12

# Copy the compiled binaries from the builder stage into the final image.
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /bin/busybox /busybox
RUN ["/busybox", "ln", "-s", "/busybox", "/usr/bin/which"]
RUN ["/busybox", "ln", "-s", "/busybox", "/usr/bin/cp"]


# Set user and group to a non-root user (e.g., UID 1000, GID 1000).
# Distroless images do not have useradd/groupadd, so we specify numeric IDs.
# This aligns with the original intent of running as a non-root 'kubectl' user.
USER 1000:1000
