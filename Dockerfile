ARG ERPNEXT_VERSION=v15
FROM frappe/erpnext:${ERPNEXT_VERSION}

# Dépôt Git officiel de l'application DealERP
# ARG DEALERP_REPO_URL=https://github.com/Dealtonsite/dealerp.git
# Cette valeur peut être surchargée via les Build Args de Coolify.
ARG DEALERP_REPO_URL=https://github.com/jeanyves2016/dealerp.git
ARG DEALERP_BRANCH=main

WORKDIR /home/frappe/frappe-bench

# Clone de l'app dealerp à une branche/tag précis (reproductibilité du build).
# Pour un repo privé, le build doit fournir les identifiants via un secret BuildKit
# (--mount=type=secret), jamais en clair dans une instruction RUN classique,
# sinon le token reste lisible dans les layers de l'image.
RUN --mount=type=secret,id=github_token \
    if [ -f /run/secrets/github_token ]; then \
      TOKEN=$(cat /run/secrets/github_token); \
      git clone --branch "${DEALERP_BRANCH}" --depth 1 \
        "https://x-access-token:${TOKEN}@$(echo ${DEALERP_REPO_URL} | sed 's#https://##')" \
        apps/dealerp; \
    else \
      git clone --branch "${DEALERP_BRANCH}" --depth 1 "${DEALERP_REPO_URL}" apps/dealerp; \
    fi

# Installe les dépendances Python de l'app dans l'environnement bench existant
RUN /home/frappe/frappe-bench/env/bin/pip install -e apps/dealerp

# Déclare l'app dans le bench (nécessaire pour que bench la reconnaisse au build/migrate)
# Évite d'ajouter plusieurs fois "dealerp" dans sites/apps.txt RUN echo "dealerp" >> sites/apps.txt
RUN grep -qxF "dealerp" sites/apps.txt || echo "dealerp" >> sites/apps.txt

LABEL org.opencontainers.image.title="DealERP"
LABEL org.opencontainers.image.vendor="Dealtonsite"
LABEL org.opencontainers.image.source="https://github.com/jeanyves2016/dealerp"
LABEL org.opencontainers.image.authors="Jean Yves Ahiba"

# Compile les assets front-end (JS/CSS, Workspaces, icônes) — étape oubliée
# dans un simple git clone + pip install, indispensable pour que l'app soit
# visible et fonctionnelle côté Desk.
RUN bench build --app dealerp
