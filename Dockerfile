ARG ERPNEXT_VERSION=v15
FROM frappe/erpnext:${ERPNEXT_VERSION}

ARG DEALERP_REPO_URL=https://github.com/jeanyves2016/dealerp.git
ARG DEALERP_BRANCH=main
ARG DEALERP_COMMIT=dev

WORKDIR /home/frappe/frappe-bench

RUN echo "Building DealERP commit: ${DEALERP_COMMIT}"

RUN --mount=type=secret,id=github_token \
    if [ -f /run/secrets/github_token ]; then \
      TOKEN=$(cat /run/secrets/github_token); \
      git clone --branch "${DEALERP_BRANCH}" --depth 1 \
        "https://x-access-token:${TOKEN}@$(echo ${DEALERP_REPO_URL} | sed 's#https://##')" \
        apps/dealerp; \
    else \
      git clone --branch "${DEALERP_BRANCH}" --depth 1 "${DEALERP_REPO_URL}" apps/dealerp; \
    fi

# Installation dans le venv du bench
RUN /home/frappe/frappe-bench/env/bin/pip install -e apps/dealerp

# Vérifications (le build échoue immédiatement si un problème existe)
RUN /home/frappe/frappe-bench/env/bin/python -c "import dealerp; print('Dealerp OK:', dealerp.__file__)"
RUN /home/frappe/frappe-bench/env/bin/pip show dealerp

# Déclare l'application
RUN grep -qxF "dealerp" sites/apps.txt || echo "dealerp" >> sites/apps.txt

LABEL org.opencontainers.image.title="DealERP"
LABEL org.opencontainers.image.vendor="Dealtonsite"
LABEL org.opencontainers.image.source="https://github.com/jeanyves2016/dealerp"
LABEL org.opencontainers.image.authors="Jean Yves Ahiba"

RUN bench build --app dealerp