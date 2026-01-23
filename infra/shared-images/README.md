# Pre-imported Container Images

This directory contains ImageStream definitions for pre-importing container images into the OpenShift cluster's internal registry.

## Why Pre-import?

For hackathons with many participants (e.g., 60 users), pre-importing images provides:
- **Faster deployments**: No waiting for external pulls
- **Reduced bandwidth**: Images pulled once, shared by all
- **Offline resilience**: Works if external registries are slow/unavailable
- **Consistent versions**: All users get the same image version

## Images Included

- `mongodb:latest` - MongoDB 7.0 database
- `minio:latest` - MinIO object storage
- `minio-mc:latest` - MinIO client (for initialization)
- `python-311:latest` - Python 3.11 (for backend)
- `nodejs-20:latest` - Node.js 20 (for frontend)
- `git:latest` - Alpine Git (for cloning repos)

## Admin Setup (Before Hackathon)

**Prerequisites:**
- Cluster admin permissions
- Access to `openshift` namespace

**Import images:**

```bash
# As cluster admin
./scripts/admin-import-images.sh
```

This creates ImageStreams in the `openshift` namespace and imports all images.

**Verify imports:**

```bash
# View by label
oc get imagestreams -n openshift -l app=griot-grits-hackathon

# Or grep by name
oc get imagestreams -n openshift | grep -E '(mongodb|minio|python-311|nodejs-20|git)'

# Describe specific image
oc describe imagestream mongodb -n openshift
```

## Using Pre-imported Images

### Automatic (Recommended)

The deployment scripts automatically detect and use pre-imported images if available:

```bash
./scripts/deploy-services.sh --use-internal-registry -n gng-user1
```

### Manual Reference

Images are available at:
```
image-registry.openshift-image-registry.svc:5000/openshift/<image>:latest
```

Example:
```yaml
spec:
  containers:
  - name: mongodb
    image: image-registry.openshift-image-registry.svc:5000/openshift/mongodb:latest
```

## Updating Images

ImageStreams are configured with `scheduled: true`, so they automatically check for updates periodically.

To manually trigger an update:

```bash
oc import-image mongodb -n openshift
oc import-image minio -n openshift
```

## Cleanup

To remove pre-imported images:

```bash
oc delete imagestream -l app=griot-grits-hackathon -n openshift
```

## Alternative: DaemonSet Pre-pull

If you can't create ImageStreams in `openshift` namespace, use a DaemonSet to pre-pull on all nodes:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: image-prepull
spec:
  template:
    spec:
      initContainers:
      - name: prepull-mongodb
        image: docker.io/mongo:7.0
        command: ['sh', '-c', 'echo Prepulled']
      - name: prepull-minio
        image: quay.io/minio/minio:latest
        command: ['sh', '-c', 'echo Prepulled']
      containers:
      - name: pause
        image: gcr.io/google_containers/pause:3.2
```

Deploy this before the hackathon, then delete it once images are cached on nodes.

## Troubleshooting

**ImageStream not importing:**
```bash
oc describe imagestream mongodb -n openshift
# Check Events section for errors
```

**Users can't pull from internal registry:**
```bash
# Grant registry access
oc policy add-role-to-group system:image-puller system:authenticated -n openshift
```

**Storage space issues:**
```bash
# Check registry storage
oc get pvc -n openshift-image-registry
```
