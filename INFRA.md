# Infrastructure Guide (Admins Only)

This guide covers deploying shared services to OpenShift for the Griot & Grits project.

## Whisper ASR Deployment

Deploy OpenAI Whisper speech-to-text service on OpenShift.

### Prerequisites

- `oc` CLI installed
- Logged into OpenShift cluster
- Namespace/project created

### Quick Deploy

```bash
# Login to OpenShift
oc login <cluster-url>

# Deploy with defaults (base model)
./infra/whisper/deploy.sh

# Deploy with a specific model
./infra/whisper/deploy.sh --model small

# Deploy to specific namespace
./infra/whisper/deploy.sh --namespace griot-grits --model medium

# Remove deployment
./infra/whisper/deploy.sh --delete
```

### Model Options

| Model | RAM | Speed | Accuracy | Best For |
|-------|-----|-------|----------|----------|
| `tiny` | ~1GB | Fastest | Basic | Testing, low resources |
| `base` | ~1GB | Fast | Good | Development (default) |
| `small` | ~2GB | Medium | Better | General use |
| `medium` | ~5GB | Slower | Great | Quality transcription |
| `large-v3` | ~10GB | Slowest | Best | Production |

### API Usage

Once deployed, get the route URL:

```bash
oc get route whisper-asr -n griot-grits
```

Transcribe audio:

```bash
curl -X POST "https://<route-url>/asr" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/path/to/audio.mp3" \
  -F "output=json"
```

### Backend Integration

To enable transcription in the Griot & Grits backend, update `.env`:

```env
PROCESSING_ENABLE_TRANSCRIPTION=true
PROCESSING_TRANSCRIPTION_API_URL=https://<route-url>
```

### GPU Support

For GPU-accelerated transcription, edit `infra/whisper/openshift/deployment.yaml` and uncomment:

```yaml
resources:
  limits:
    nvidia.com/gpu: "1"
```

Requires GPU nodes with NVIDIA GPU Operator installed.

### Troubleshooting

```bash
# Check pod status
oc get pods -n griot-grits

# View logs
oc logs -f deployment/whisper-asr -n griot-grits

# Describe deployment for events
oc describe deployment whisper-asr -n griot-grits

# Check resource usage
oc adm top pods -n griot-grits
```

## Future Infrastructure

Additional shared services to deploy:

- [ ] Shared MongoDB (for multi-user environments)
- [ ] Shared MinIO (for shared object storage)
- [ ] LLM service (for AI enrichment)
