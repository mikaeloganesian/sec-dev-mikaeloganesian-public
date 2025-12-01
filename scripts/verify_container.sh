#!/bin/bash

set -e

echo "=========================================="
echo "Container Hardening Verification"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE_NAME="sec-dev-app:latest"
CONTAINER_NAME="sec-dev-app-test"
ERRORS=0

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "1. File structure..."
[ -f "Dockerfile" ] && check "Dockerfile exists"
[ -f "compose.yaml" ] && check "compose.yaml exists"
[ -f ".dockerignore" ] && check ".dockerignore exists"
[ -f "Makefile" ] && check "Makefile exists"
echo ""

echo "2. Dockerfile checks..."
grep -q "FROM python:3.11-slim AS build" Dockerfile && check "Multi-stage build: build stage"
grep -q "FROM python:3.11-slim AS runtime" Dockerfile && check "Multi-stage build: runtime stage"
grep -q "USER app" Dockerfile && check "Non-root user (USER app)"
grep -q "WORKDIR /app" Dockerfile && check "WORKDIR set"
grep -q "HEALTHCHECK" Dockerfile && check "HEALTHCHECK present"
grep -q "ENTRYPOINT" Dockerfile && check "ENTRYPOINT declared"
grep -q "CMD" Dockerfile && check "CMD declared"
grep -q "EXPOSE 8000" Dockerfile && check "EXPOSE 8000"
echo ""

echo "3. .dockerignore checks..."
grep -q "^\.git" .dockerignore && check ".git ignored"
grep -q "venv" .dockerignore && check "venv ignored"
grep -q "__pycache__" .dockerignore && check "__pycache__ ignored"
grep -q "\.vscode" .dockerignore && check ".vscode ignored"
echo ""

echo "4. Version pins in requirements.txt..."
if grep -q "==" requirements.txt; then
    check "Versions pinned (==) in requirements.txt"
else
    echo -e "${RED}✗${NC} Versions not pinned in requirements.txt"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "5. compose.yaml checks..."
grep -q "healthcheck:" compose.yaml && check "Healthcheck in compose.yaml"
grep -q "ports:" compose.yaml && check "Ports configured"
echo ""

echo "6. Building Docker image..."
if docker build --pull -t $IMAGE_NAME . > /tmp/docker-build.log 2>&1; then
    check "Image built successfully"
else
    echo -e "${RED}✗${NC} Build failed. Log:"
    tail -20 /tmp/docker-build.log
    ERRORS=$((ERRORS + 1))
    echo ""
    exit 1
fi
echo ""

echo "7. Non-root user check..."
CONTAINER_UID=$(docker run --rm --entrypoint id $IMAGE_NAME -u 2>/dev/null || echo "0")
if [ "$CONTAINER_UID" != "0" ]; then
    check "Container runs as non-root (UID=$CONTAINER_UID)"
else
    echo -e "${RED}✗${NC} Container runs as root (UID=0)"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "8. Healthcheck verification..."
CID=$(docker run -d --rm --name $CONTAINER_NAME -p 8000:8000 $IMAGE_NAME 2>/dev/null || echo "")

if [ -z "$CID" ]; then
    echo -e "${RED}✗${NC} Failed to start container"
    ERRORS=$((ERRORS + 1))
else
    echo "Waiting for container to become healthy (max 60s)..."
    HEALTHY=false
    for i in {1..30}; do
        sleep 2
        STATUS=$(docker inspect -f '{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null || echo "starting")
        if [ "$STATUS" = "healthy" ]; then
            HEALTHY=true
            break
        fi
        echo "  Attempt $i/30: status = $STATUS"
    done

    if [ "$HEALTHY" = true ]; then
        check "Container became healthy"
    else
        echo -e "${RED}✗${NC} Container did not become healthy within 60s"
        echo "Container logs:"
        docker logs $CONTAINER_NAME 2>&1 | tail -20
        ERRORS=$((ERRORS + 1))
    fi

    docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
fi
echo ""

echo "9. Hadolint check (optional)..."
if command -v hadolint &> /dev/null; then
    if hadolint Dockerfile 2>/dev/null; then
        check "hadolint: no critical issues"
    else
        echo -e "${YELLOW}⚠${NC} hadolint found warnings"
    fi
elif docker run --rm -i hadolint/hadolint hadolint - < Dockerfile 2>/dev/null; then
    check "hadolint (via docker): no critical issues"
else
    echo -e "${YELLOW}⚠${NC} hadolint unavailable or found warnings"
fi
echo ""

echo "10. Trivy scan (optional)..."
if command -v trivy &> /dev/null; then
    if trivy image --no-progress $IMAGE_NAME > /tmp/trivy.log 2>&1; then
        echo -e "${GREEN}✓${NC} Trivy scan completed (see /tmp/trivy.log)"
    else
        echo -e "${YELLOW}⚠${NC} Trivy found vulnerabilities (see /tmp/trivy.log)"
    fi
elif docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --no-progress $IMAGE_NAME > /tmp/trivy.log 2>&1; then
    echo -e "${GREEN}✓${NC} Trivy scan completed via docker (see /tmp/trivy.log)"
else
    echo -e "${YELLOW}⚠${NC} Trivy unavailable or found vulnerabilities (see /tmp/trivy.log)"
fi
echo ""

echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All checks passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Found errors: $ERRORS${NC}"
    exit 1
fi
