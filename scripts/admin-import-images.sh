#!/bin/bash

# Admin script to pre-import container images into OpenShift cluster
# This should be run ONCE by cluster admin before the hackathon

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}=== Griot & Grits - Pre-import Container Images ===${NC}"
echo ""

# Check if user is cluster admin
if ! oc auth can-i create imagestreams -n openshift &>/dev/null; then
    echo -e "${YELLOW}Warning: You may need cluster-admin permissions to create ImageStreams in 'openshift' namespace${NC}"
    echo ""
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}Importing container images into cluster...${NC}"
echo ""

# Apply ImageStreams
oc apply -f "$ROOT_DIR/infra/shared-images/imagestreams.yaml"

echo ""
echo -e "${CYAN}Waiting for images to import...${NC}"
echo ""

# Wait for each ImageStream to import
IMAGES=(mongodb minio minio-mc python-311 nodejs-20 git)
for img in "${IMAGES[@]}"; do
    echo -n "  Importing $img... "

    # Wait up to 2 minutes for import
    timeout=120
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if oc get istag "$img:latest" -n openshift &>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            break
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    if [ $elapsed -ge $timeout ]; then
        echo -e "${YELLOW}⚠ Timeout (check manually)${NC}"
    fi
done

echo ""
echo -e "${GREEN}${BOLD}✓ Image Import Complete${NC}"
echo ""
echo "Images are now available cluster-wide at:"
echo -e "  ${CYAN}image-registry.openshift-image-registry.svc:5000/openshift/<image>:latest${NC}"
echo ""
echo "Users can now reference these images instead of pulling from external registries."
echo ""
echo "To verify imports:"
echo -e "  ${CYAN}oc get imagestreams -n openshift | grep -E '(mongodb|minio|python-311|nodejs-20|git)'${NC}"
echo ""
echo "Or view with labels:"
echo -e "  ${CYAN}oc get imagestreams -n openshift -l app=griot-grits-hackathon${NC}"
echo ""
