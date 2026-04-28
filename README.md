# Chatwoot SSO via Authentik Header Auth (No‑Patch Plugin; fake SSO/OAuth)

This adds **header‑based authentication** to Chatwoot Community Edition **without modifying any existing Chatwoot files**.  
It is implemented as **new Ruby files only**, mounted into the container via Docker.  
If paired with forward auth, the user experience is **close to Single Sign-On (SSO)**.

> [!NOTE]
> This is not an implementation of the real SSO.

## What it does

- Reads `X-authentik-email`
- Authenticates the user via Warden
- Mints a DeviseTokenAuth session and sets the `cw_d_session_info` cookie
- Keeps the SPA logged in (no `/app/login` bounce)
- Compatible with Traefik + Authentik ForwardAuth

---

## What the user experience
1. User visits `https://chatwoot.domain.tld`
2. Traefik forwards to Authentik for authentication
3. Authentik redirects back to Chatwoot with `X-authentik-email` header
4. User is logged in and sees the Chatwoot dashboard immediately (no login page; practically SSO‑like)

---

# Install (Docker)

This guide assumes you have a working Chatwoot + Traefik + Authentik setup, and that you can edit your `docker-compose.yml` and mount files into the Chatwoot container. If you don't know how to setup forward auth, see the [Authentik documentation](https://docs.goauthentik.io/add-secure-apps/providers/proxy/forward_auth/).

### 1. Mount files into the Chatwoot container
Based on [Chatwoot's docker-compose.production.yaml](https://github.com/chatwoot/chatwoot/blob/6aeda0ddf6d267c7a3807192ab5c75259384819b/docker-compose.production.yaml):

```yaml
services:
  base: &base
    image: chatwoot/chatwoot:latest-ce
    env_file: .env # Change this file for customized env variables
    volumes:
      - storage_data:/app/storage
      - ./overrides/config/initializers/header_auth.rb:/app/config/initializers/header_auth.rb
      - ./overrides/lib/header_auth/strategy.rb:/app/lib/header_auth/strategy.rb
      - ./overrides/lib/header_auth/middleware.rb:/app/lib/header_auth/middleware.rb

# The rest of the file...
```

### 2. Up Chatwoot
```bash
docker compose up -d
```

---

# Required Authentik Header

Your reverse proxy must forward:

```
X-authentik-email: user@example.com
```

Rails sees this as:

```
HTTP_X_AUTHENTIK_EMAIL
```

---

# Logout Redirect (optional but recommended)

To redirect to Authentik logout page after users logout inside Chatwoot:

```bash
docker compose exec rails bin/rails runner \
'InstallationConfig.find_or_create_by!(name: "LOGOUT_REDIRECT_LINK").update!(value: "<REDIRECT_URL>")'
```
Replace `<REDIRECT_URL>` with your Authentik logout URL, e.g. `https://chatwoot.domain.tld/outpost.goauthentik.io/sign_out`.

Then restart:

```bash
docker compose restart rails
```

---

# ⚠️ Security Note

Only expose Chatwoot **through Traefik**.  
If Chatwoot is reachable directly, users could spoof headers.

---

# License
This repository is licensed under the MIT License. See [LICENSE](LICENSE) for details.
