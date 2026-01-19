## FishKube Manager

FishKube Manager is a modern Kubernetes management UI built with **Flask + Gunicorn** and a lightweight **vanilla JS** frontend. It ships with a Helm chart for deployment.

It provides:
- **Overview** dashboard (cluster or namespace scoped)
- Resource browsing (pods, deployments, nodes, services, ingresses, storage, etc.)
- Modern **Logs** viewer
- **YAML** viewer/editor with RBAC
- Optional **Chat AI** for operational questions and cluster actions (tool-calling over live Kubernetes data)
- Optional external **Resources usage monitoring** link (Grafana) per pod namespace

---

## Features

- **Authentication**
  - Local users (SQLite) and/or Google OAuth
  - Group-based permissions + Admin UI
- **Overview dashboard**
  - Nodes / Pods / Namespaces / Services
  - CPU/Memory requests/limits vs allocatable capacity
  - Current usage shown when **metrics-server** is installed (metrics.k8s.io)
  - Pod status cards (Running/Pending/Failed/Evicted)
- **Pods table**
  - Shows node **InternalIP**
  - Separate **CPU** and **Memory** usage columns with request-based bar visualization + tooltip (request/limit)
- **Logs drawer**
  - ANSI stripping, readable timestamps, colored levels
  - Pretty/Raw toggle, filter, wrap
- **Drawer (resource details)**
  - YAML view with key/value coloring
  - Inline full-height YAML editor (Save/Cancel applies via `/api/apply`)
  - Header buttons: YAML, Resources usage monitoring (optional), Pod Info, Copy, Edit, Save/Cancel, Close
- **Chat AI (optional)**
  - Tool-enabled (functions) across providers
  - Supports OpenAI (default), Gemini, and AWS Bedrock (Anthropic Claude)

---

## Kubernetes access & RBAC

The app uses **in-cluster** auth when deployed in Kubernetes. Locally it falls back to your kubeconfig.

Typical RBAC requirements:
- **Read**: nodes, namespaces, pods, pods/log, deployments, daemonsets, statefulsets, replicasets, jobs, cronjobs, services, ingresses, ingressclasses, configmaps, secrets, pvcs, pvs, events, volumeattachments
- **Write (optional; controlled by app RBAC groups):**
  - pods: delete
  - deployments/scale: update/patch
  - volumeattachments: delete
  - server-side apply/patch for kinds supported by `/api/apply`

---

## Run locally

### Python (recommended for dev)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export FKM_DB="$(pwd)/data/users.db"
export FKM_SECRET="change-me"
export FKM_BOOTSTRAP_USER="admin"
export FKM_BOOTSTRAP_PASS="change_me"

python -c "from app.app import app; app.run(host='0.0.0.0', port=8080, debug=True)"
```

### Docker

```bash
docker build -t fishkube-manager .

docker run --rm -p 8080:8080 \
  -e FKM_DB=/data/users.db \
  -e FKM_SECRET=change-me \
  -e FKM_BOOTSTRAP_USER=admin \
  -e FKM_BOOTSTRAP_PASS=change_me \
  -v ~/.kube/config:/root/.kube/config:ro \
  -v ~/.aws:/root/.aws:rw \
  -v "$(pwd)/data:/data" \
  fishkube-manager
```

Open `http://localhost:8080`.

---

## Deploy with Helm

```bash
helm upgrade --install fishkube-manager ./helm \
  -n fishkube-manager --create-namespace \
  -f helm/value-dev.yaml
```

Port-forward (from chart NOTES):

```bash
export POD_NAME=$(kubectl get pods -n fishkube-manager -l "app.kubernetes.io/name=fishkube-manager" -o jsonpath="{.items[0].metadata.name}")
kubectl -n fishkube-manager port-forward pod/$POD_NAME 8080:8080
open http://localhost:8080
```

---

## Configuration reference (env vars)

### Core / DB / sessions
- **`FKM_SECRET`**: Flask session secret key (set a strong value in prod)
- **`FKM_DB`**: SQLite DB path (default `/data/users.db`)
- **`FKM_SCALE_WAIT`**: max wait seconds for scaling ops (default `45`)
- **`FKM_CHAT_BUDGET`**: max request budget seconds for Chat AI loop (default `50`)

### Bootstrap users
- **`FKM_BOOTSTRAP_USER`**, **`FKM_BOOTSTRAP_PASS`**: created when DB has no users yet
- **`BOOTSTRAP_ADMIN`**, **`BOOTSTRAP_PASSWORD`**: recovery path (forces role=admin on login)

The app also auto-repairs configured bootstrap usernames to `role=admin` on startup.

### Authentication provider
- **`FKM_AUTH_PROVIDER`**: `local` | `google`
- **`GOOGLE_CLIENT_ID`**, **`GOOGLE_CLIENT_SECRET`**
- **`GOOGLE_ALLOWED_DOMAIN`**: optional email domain restriction
- **`FKM_OAUTH_REDIRECT_URI`**: optional explicit redirect URI
- **`FKM_COOKIE_DOMAIN`**: cookie domain override
- **`FKM_SESSION_COOKIE_NAME`**: session cookie name override
- **`FKM_ALLOW_LOCAL_WITH_GOOGLE`**: `true|false` (default true)

### Pod “Resources usage monitoring” external link (Grafana)
- **`FKM_EXTERNAL_MONITORING_URL_BTN`**: `true|false` (if false, button is hidden)
- **`FKM_MONITORING_BASE_URL`**: e.g. `https://grafana.example.com/`
- **`FKM_MONITORING_QUERY_TEMPLATE`**: path+query, supports `<namespace>` placeholder

Example template:
`/d/<UID>/kubernetes-compute-resources-namespace-workloads?...&var-namespace=<namespace>&var-type=All`

### Pod usage data source
- **`FKM_PROM_URL`** (or `PROM_URL`): Prometheus base URL to enable 1h average CPU/memory in pods table.
- Without Prometheus, Overview can show **current node usage** if **metrics-server** is installed.

### Chat AI provider selection
- **`FKM_AI_PROVIDER`**: `openai` (default) | `gemini` | `bedrock_anthropic`

OpenAI:
- **`OPENAI_API_KEY`**
- **`OPENAI_MODEL`** (e.g. `gpt-5.2`)
- **`OPENAI_TEMPERATURE`** (ignored for `gpt-5*` models)

Gemini:
- **`GEMINI_API_KEY`**
- **`GEMINI_MODEL`** (e.g. `gemini-1.5-pro`)

AWS Bedrock (Anthropic Claude):
- **`AWS_REGION`**
- **`BEDROCK_MODEL_ID`** (e.g. `anthropic.claude-3-5-sonnet-20240620-v1:0`)
- Credentials via IRSA / node role / env credentials; needs `bedrock:InvokeModel`

---

## Helm values (what to edit)

See `helm/values.yaml` for defaults and `helm/value-*.yaml` for environment overlays.

Key sections:
- `authProvider`: local vs google auth
- `persistence`: PVC size/mountPath/storageClassName
- `env`: operational env vars (Prometheus URL, monitoring URL button, etc.)
- `ai`: provider selection + credentials/models

Security:
- Do **not** commit real API keys to git.
- Prefer Kubernetes Secrets for `OPENAI_API_KEY`, `GEMINI_API_KEY`, and Google OAuth secrets.

---

## Troubleshooting

### “DB error: unable to open database file”
This is almost always storage:

```bash
kubectl -n <ns> exec deploy/fishkube-manager -- sh -lc 'echo "FKM_DB=$FKM_DB"; ls -ld /data; touch /data/_write_test'
```

If you get `Input/output error`, the volume is unhealthy (EBS attach/mount issue).

### EBS: “AttachVolume.Attach failed … volume attachment is being deleted”
This means the old `VolumeAttachment` hasn’t finished detaching.
Find the `csi-...` VolumeAttachment for that `pvc-...` handle and delete the correct object (not the pvc handle string).

### Usage columns show “-”
- Ensure `FKM_PROM_URL` points to a reachable Prometheus that has container metrics.
- Without Prometheus, you’ll only see **current usage** in Overview if metrics-server exists.

### Bedrock chat errors
Most common causes:
- Missing IAM permissions (`bedrock:InvokeModel`)
- Wrong `AWS_REGION` or `BEDROCK_MODEL_ID`

---

## License

This project is licensed under the **Apache License 2.0**.

