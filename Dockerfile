FROM docker.io/debian:trixie-slim
USER root

RUN apt-get update && apt-get upgrade -q -y && apt install -y curl

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN cd /tmp; curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; mv kubectl /usr/bin/kubectl; chmod 755 /usr/bin/kubectl
RUN groupadd kubectl && useradd -m -u 1000 -g kubectl kubectl
USER kubectl