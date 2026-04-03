# FishKube Manager

FishKube Manager is a modern, self-hosted Kubernetes management platform with multi-cluster support, AI-powered operations, fine-grained RBAC, and a mobile-friendly UI.

FishKube Manager is a modern SAAS Kubernetes management dashboard, featuring frontend and a Helm chart for Kubernetes deployment.

It focuses on operational visibility, safe resource management, and optional AI assisted cluster interactions.

Built for real-world DevOps — triage incidents from your phone, manage clusters from a single pane of glass, and let AI handle the repetitive queries.

## Features
- Cluster or namespace overview dashboard
- Resource browsing for core Kubernetes objects
- Modern logs viewer
- YAML viewer and editor with RBAC
- Local and Google OAuth authentication
- Optional AI assistant for cluster operations
- Optional external monitoring links (Grafana)

## Screenshots
![alt text](screenshots/image.png)


![alt text](screenshots/image-2.png)

- Dashboard overview
- Pods table and resource usage
- Logs viewer
- YAML editor
- Chat AI assistant

![alt text](image.png)

### Full Feature List

- **Multi-cluster management** — local, kubeconfig, and agent-based cluster connections in one UI
- **Cluster overview dashboard** — nodes, pods, namespaces, CPU/memory usage at a glance
- **Resource browser** — Pods, Deployments, DaemonSets, StatefulSets, ReplicaSets, Jobs, CronJobs, Services, Ingresses, ConfigMaps, Secrets, PVCs, PVs, Nodes, Events
- **Logs viewer** — real-time pod logs with ANSI color support, filtering, and wrap toggle
- **YAML viewer & editor** — syntax-highlighted YAML with inline editing and server-side apply
- **Scale operations** — scale deployments up/down from the UI or via natural language in Chat AI
- **AI Chat assistant** — ask questions in plain English, get answers from live cluster data
  - Multi-provider: OpenAI, Google Gemini, AWS Bedrock (Claude)
  - Cross-cluster queries across all connected clusters
  - Session memory and suggested follow-up questions
  - Safe by design — write operations require explicit confirmation
- **Authentication** — local user database or Google SSO (or both)
- **Permission groups** — Administrators, DevOps, Team Leads, RnD, Read Only (+ custom groups)
- **Per-cluster permissions** — assign different permission groups per user per cluster
- **Default cluster access** — set a baseline permission group per cluster for all users
- **Custom cluster colors** — visual cluster identification with color-coded selectors
- **Jira integration** — ticket-gated tier changes with API verification, AI content validation, and auto-commenting
- **Slack notifications** — real-time alerts for tier changes and scale operations
- **Prometheus integration** — 1h average CPU/memory usage per pod
- **External monitoring deep-links** — configurable links to Grafana, Datadog, or any monitoring tool
- **Mobile-responsive UI** — fully functional on phones and tablets
- **Dark/light theme** — toggle from the header

## Screenshots

![Overview Dashboard](screenshots/image.png)

![Pods Table](screenshots/image-2.png)

## Architecture

A single Helm chart deploys both the **manager** (full UI) and the **agent** (lightweight proxy for remote clusters):

| Mode | What it deploys | Use case |
|------|----------------|----------|
| `manager` | Full management UI with auth, AI, SQLite | Central control plane |
| `agent` | Lightweight Kubernetes API proxy | Remote clusters behind firewalls |

Connection types:

| Type | How it works | Best for |
|------|-------------|----------|
| **Local** | In-cluster ServiceAccount | The cluster where the manager runs |
| **Kubeconfig** | Stored kubeconfig YAML | Remote clusters with direct API access |
| **Agent** | HTTP proxy deployed on remote cluster | Clusters behind firewalls or different VPCs |

## Quick Start

```bash
# Create namespace and admin secret
kubectl create namespace fishkube-manager
kubectl create secret generic fishkube-admin \
  --namespace fishkube-manager \
  --from-literal=username=admin \
  --from-literal=password='your-secure-password'

# Deploy the manager
helm upgrade --install fishkube-manager ./helm \
  -n fishkube-manager -f helm/values.yaml

# Access the UI
kubectl port-forward -n fishkube-manager svc/fishkube-manager 8080:80
open http://localhost:8080
```

### Connect a Remote Cluster (Agent)

```bash
# On the remote cluster
helm upgrade --install fishkube-agent ./helm \
  -f helm/values-agent.yaml \
  -n fishkube-manager --create-namespace \
  --set agent.token='shared-secret-token'
```

Then register the agent in **Admin > Clusters** with its URL and token.

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FKM_SECRET` | — | Flask session secret key |
| `FKM_DB` | `/data/users.db` | SQLite database path |
| `FKM_BOOTSTRAP_USER` | `admin` | Initial admin username |
| `FKM_BOOTSTRAP_PASS` | `change_me` | Initial admin password |
| `FKM_AI_PROVIDER` | `openai` | AI provider: `openai`, `gemini`, or `bedrock_anthropic` |
| `FKM_SCALE_WAIT` | `45` | Max wait seconds for scale operations |
| `FKM_CHAT_BUDGET` | `120` | Max request budget seconds for AI Chat |
| `FKM_AGENT_TIMEOUT` | `180` | HTTP timeout for agent proxy requests |
| `FKM_PROM_URL` | — | Prometheus URL for CPU/memory metrics |
| `FKM_MONITORING_BASE_URL` | — | Monitoring tool base URL for deep-links |
| `FKM_MONITORING_QUERY_TEMPLATE` | — | URL template with `<namespace>` placeholder |
| `FKM_EXTERNAL_MONITORING_URL_BTN` | `false` | Show monitoring deep-link button |
| `FKM_AUTH_PROVIDER` | `local` | Auth provider: `local` or `google` |

### AI Providers

**OpenAI:** `OPENAI_API_KEY`, `OPENAI_MODEL`, `OPENAI_TEMPERATURE`

**Google Gemini:** `GEMINI_API_KEY`, `GEMINI_MODEL`

**AWS Bedrock:** `AWS_REGION`, `BEDROCK_MODEL_ID` (requires `bedrock:InvokeModel` IAM permission)

### Integrations

| Key | Description |
|-----|-------------|
| `integrations.jira.baseUrl` | Jira instance URL |
| `integrations.jira.userEmail` | Jira API user email |
| `integrations.jira.apiToken` | Jira API token |
| `integrations.slack.botToken` | Slack Bot OAuth token |
| `integrations.slack.channelId` | Slack channel ID for notifications |

Leave empty to disable. The system works fully without Jira/Slack.

### Helm Values

See `helm/values.yaml` for all defaults. Key sections:

- `mode` — `manager` or `agent`
- `authProvider` — local vs Google SSO
- `persistence` — PVC size, mount path, storage class
- `ai` — provider selection and credentials
- `integrations` — Jira and Slack configuration
- `env` — operational environment variables

### Security Notes

- Do **not** commit API keys or secrets to git
- Use Kubernetes Secrets for sensitive values
- Always set a strong `agent.token` for agent connections
- Set `FKM_SECRET` to a strong random value in production

## Permission Groups

| Group | Description |
|-------|-------------|
| **Administrators** | Full platform control including user management |
| **DevOps** | All resource operations except user management |
| **Team Leads** | View all, scale workloads, view logs |
| **RnD** | View all, view logs, delete pods |
| **Read Only** | View all resources and logs, no mutations |

Custom groups can be created with fine-grained permission control. Per-cluster access allows different groups per user per cluster. Default cluster access groups provide baseline permissions for all users.

## Run Locally

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

export FKM_DB="$(pwd)/data/users.db"
export FKM_SECRET="change-me"
export FKM_BOOTSTRAP_USER="admin"
export FKM_BOOTSTRAP_PASS="change_me"

python -c "from app.app import app; app.run(host='0.0.0.0', port=8080, debug=True)"
```

## License

Apache License 2.0
