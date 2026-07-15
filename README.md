# DevOps Intern – Final Assessment

A complete DevOps pipeline demonstrating Git, Linux scripting, Docker, CI/CD, Nomad orchestration, Grafana Loki monitoring, and MLflow experiment tracking.

---

## 📁 Project Structure

```
.
├── .github/workflows/ci.yml   # GitHub Actions CI pipeline
├── mlflow/
│   ├── mlflow_tracker.py       # MLflow experiment tracker (Extra Credit)
│   └── requirements.txt        # Python dependencies for MLflow
├── monitoring/
│   ├── loki-config.yaml        # Grafana Loki configuration
│   └── loki_setup.txt          # Loki setup & usage guide
├── nomad/
│   └── hello.nomad             # HashiCorp Nomad job definition
├── scripts/
│   └── sysinfo.sh              # System information Bash script
├── .gitignore
├── Dockerfile                  # Docker image for hello.py
├── hello.py                    # Main Python script
└── README.md
```

---

## 1. Git & Python Basics

### hello.py

A simple Python script that prints `"Hello, DevOps!"`.

```bash
python hello.py
# Output: Hello, DevOps!
```

### Git Setup

```bash
git init
git add .
git commit -m "Initial commit - DevOps assessment"
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

---

## 2. Linux & Scripting Basics

### scripts/sysinfo.sh

A Bash script that displays system information including current user, hostname, date, disk usage, and memory usage.

```bash
chmod +x scripts/sysinfo.sh
bash scripts/sysinfo.sh
```

**Sample Output:**
```
=============================
  System Information Report
=============================

Current User : devvr
Hostname     : my-machine
Date & Time  : Tue Jul 15 20:59:00 IST 2026
Uptime       : up 3 hours, 42 minutes

--- Disk Usage ---
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   55G  45% /

--- Memory Usage ---
              total        used        free
Mem:           16G         8G         8G

=============================
```

---

## 3. Docker Basics

### Building the Docker Image

```bash
docker build -t hello-devops:latest .
```

### Running the Container

```bash
docker run --rm hello-devops:latest
# Output: Hello, DevOps!
```

### Dockerfile Breakdown

| Instruction | Purpose |
|-------------|---------|
| `FROM python:3.12-slim` | Lightweight Python base image |
| `WORKDIR /app` | Sets the working directory |
| `COPY hello.py .` | Copies the script into the container |
| `CMD ["python", "hello.py"]` | Runs the script on container start |

---

## 4. CI/CD with GitHub Actions

### .github/workflows/ci.yml

The CI pipeline is triggered on every push or pull request to `main`/`master` and performs:

1. **Checkout** – Clones the repository
2. **Python Setup** – Installs Python 3.12
3. **Run hello.py** – Verifies the script works
4. **Run sysinfo.sh** – Verifies the Bash script works
5. **Docker Build** – Builds the container image
6. **Docker Run** – Runs the container to validate the image

Once you push to GitHub, the workflow runs automatically. Check the **Actions** tab for results.

---

## 5. Job Deployment with Nomad

### nomad/hello.nomad

A HashiCorp Nomad job definition that deploys the `hello-devops` Docker container as a service.

**Key Configuration:**

| Parameter | Value |
|-----------|-------|
| Job Type | `service` |
| Driver | `docker` |
| Image | `hello-devops:latest` |
| CPU | 100 MHz |
| Memory | 128 MB |

### Running with Nomad

```bash
# Start the Nomad agent (dev mode)
nomad agent -dev

# Submit the job
nomad job run nomad/hello.nomad

# Check job status
nomad job status hello-devops
```

---

## 6. Monitoring with Grafana Loki

### Setup Overview

Grafana Loki is a log aggregation system. The configuration is in `monitoring/loki-config.yaml` and full setup instructions are in `monitoring/loki_setup.txt`.

### Quick Start

```bash
# Run Loki
docker run -d --name loki -p 3100:3100 \
  -v $(pwd)/monitoring/loki-config.yaml:/etc/loki/config.yaml \
  grafana/loki:latest -config.file=/etc/loki/config.yaml

# Run Grafana
docker run -d --name grafana -p 3000:3000 grafana/grafana:latest

# Open Grafana at http://localhost:3000
# Add Loki as a data source → URL: http://loki:3100
```

See [loki_setup.txt](monitoring/loki_setup.txt) for detailed instructions on Promtail and Docker log forwarding.

---

## 7. Extra Credit: MLflow

### mlflow/mlflow_tracker.py

A Python script that logs a dummy ML experiment to MLflow, demonstrating:
- **Parameter logging** (model type, learning rate, epochs)
- **Metric logging** (loss and accuracy over 10 steps)
- **Artifact logging** (model summary text file)

### Running MLflow

```bash
# Install dependencies
pip install -r mlflow/requirements.txt

# Run the experiment tracker
python mlflow/mlflow_tracker.py

# Start the MLflow UI to view results
mlflow ui
# Open http://localhost:5000
```

---

## 🛠️ Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.12+ | Running scripts |
| Docker | 29.x+ | Containerization |
| Git | 2.x+ | Version control |
| Nomad | 1.x+ | Job orchestration |
| MLflow | 2.15+ | Experiment tracking (Extra Credit) |

---

## 📋 Assessment Checklist

- [x] **Git & Python** – `hello.py` script, Git repository initialized
- [x] **Linux & Scripting** – `sysinfo.sh` Bash script
- [x] **Docker** – Dockerfile, build & run commands
- [x] **CI/CD** – GitHub Actions workflow (`.github/workflows/ci.yml`)
- [x] **Nomad** – Job definition (`nomad/hello.nomad`)
- [x] **Monitoring** – Grafana Loki config and setup guide
- [x] **Extra Credit** – MLflow experiment tracking
