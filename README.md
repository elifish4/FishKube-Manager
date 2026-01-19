# FishKube Manager





FishKube Manager is a modern Kubernetes management dashboard built with Flask and Gunicorn, featuring a lightweight vanilla JavaScript frontend and a Helm chart for Kubernetes deployment.

It focuses on operational visibility, safe resource management, and optional AI assisted cluster interactions.

![alt text](screenshots/image.png)


![alt text](screenshots/image-2.png)

## Features
- Cluster or namespace overview dashboard
- Resource browsing for core Kubernetes objects
- Modern logs viewer
- YAML viewer and editor with RBAC
- Local and Google OAuth authentication
- Optional AI assistant for cluster operations
- Optional external monitoring links (Grafana)

## Screenshots

> Screenshots will be added here.

- Dashboard overview
- Pods table and resource usage
- Logs viewer
- YAML editor
- Chat AI assistant

## Quick Start

### Local
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -c "from app.app import app; app.run(host='0.0.0.0', port=8080)"
```

### Kubernetes
```bash
helm upgrade --install fishkube-manager ./helm \
  -n fishkube-manager --create-namespace
```

## Documentation
Full documentation is available in the `docs/` directory.

## License
Apache License 2.0
