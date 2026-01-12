# Whisper ASR - OpenShift Deployment

Deploys OpenAI Whisper speech-to-text service on OpenShift for the Griot & Grits project.

## Quick Start

```bash
# Login to OpenShift
oc login <your-cluster-url>

# Deploy with defaults (base model)
./deploy.sh

# Deploy with a specific model
./deploy.sh --model small

# Deploy to specific namespace
./deploy.sh --namespace my-project --model medium
```

## Model Options

| Model | RAM | Speed | Accuracy | Best For |
|-------|-----|-------|----------|----------|
| `tiny` | ~1GB | Fastest | Basic | Testing, low resources |
| `base` | ~1GB | Fast | Good | Development (default) |
| `small` | ~2GB | Medium | Better | General use |
| `medium` | ~5GB | Slower | Great | Quality transcription |
| `large-v3` | ~10GB | Slowest | Best | Production |

## API Usage

Once deployed, the Whisper API is available at the route URL:

```bash
# Get the URL
oc get route whisper-asr -n griot-grits

# Transcribe an audio file
curl -X POST "https://<route-url>/asr" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/path/to/audio.mp3" \
  -F "output=json"
```

### API Parameters

- `audio_file`: Audio file (mp3, wav, m4a, etc.)
- `task`: `transcribe` (default) or `translate` (to English)
- `language`: Auto-detect (default) or specify (e.g., `en`, `es`)
- `output`: `json`, `txt`, `vtt`, `srt`

## Backend Integration

To enable transcription in the Griot & Grits backend:

```env
PROCESSING_ENABLE_TRANSCRIPTION=true
PROCESSING_TRANSCRIPTION_API_URL=https://<route-url>
```

## GPU Support

For GPU-accelerated transcription, uncomment the GPU resource limit in `deployment.yaml`:

```yaml
resources:
  limits:
    nvidia.com/gpu: "1"
```

Requires GPU nodes with NVIDIA GPU Operator installed.

## Troubleshooting

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

## Cleanup

```bash
./deploy.sh --delete
```
