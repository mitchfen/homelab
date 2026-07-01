$ErrorActionPreference = 'Stop'

# $PSScriptRoot gets the directory of the current script (must be run from a .ps1 file)
$SCRIPT_DIR = $PSScriptRoot
$NAMESPACE = 'landing-page'
$MANIFEST_PATH = Join-Path -Path $SCRIPT_DIR -ChildPath 'manifest.yaml'
$INDEX_PATH = Join-Path -Path $SCRIPT_DIR -ChildPath 'index.html'

# Create the initial part of the manifest
$part1 = @"
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
"@
Set-Content -Path $MANIFEST_PATH -Value $part1 -Encoding UTF8

# Indent the HTML file by 4 spaces and append it
Get-Content -Path $INDEX_PATH | ForEach-Object { "    $_" } | Add-Content -Path $MANIFEST_PATH -Encoding UTF8

# Append the rest of the manifest
$part2 = @"
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
"@
Add-Content -Path $MANIFEST_PATH -Value $part2 -Encoding UTF8

Write-Output "Applying manifest..."
kubectl apply -f $MANIFEST_PATH

Write-Output "Restarting deployment..."
kubectl rollout restart deployment/landing-page -n $NAMESPACE

Write-Output "Done! Landing page deployed."
