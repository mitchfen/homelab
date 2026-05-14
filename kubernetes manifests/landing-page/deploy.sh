#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NAMESPACE="landing-page"

cat > "$SCRIPT_DIR/manifest.yaml" << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: landing-page
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: landing-page-html
  namespace: landing-page
data:
  index.html: |
EOF

# Indent the HTML file and append it
sed 's/^/    /' "$SCRIPT_DIR/index.html" >> "$SCRIPT_DIR/manifest.yaml"

cat >> "$SCRIPT_DIR/manifest.yaml" << 'EOF'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: landing-page
  namespace: landing-page
spec:
  replicas: 1
  selector:
    matchLabels:
      app: landing-page
  template:
    metadata:
      labels:
        app: landing-page
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            memory: "32Mi"
            cpu: "10m"
          limits:
            memory: "64Mi"
            cpu: "100m"
      volumes:
      - name: html
        configMap:
          name: landing-page-html
          items:
          - key: index.html
            path: index.html
---
apiVersion: v1
kind: Service
metadata:
  name: landing-page
  namespace: landing-page
spec:
  type: ClusterIP
  selector:
    app: landing-page
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF

echo "Applying manifest..."
kubectl apply -f "$SCRIPT_DIR/manifest.yaml"

echo "Restarting deployment..."
kubectl rollout restart deployment/landing-page -n "$NAMESPACE"

echo "Done! Landing page deployed."
