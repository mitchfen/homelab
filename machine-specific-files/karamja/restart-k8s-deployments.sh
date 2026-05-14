#!/bin/bash

echo "Restarting all Kubernetes deployments..."
echo ""

# Get all namespaces, excluding kube* namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v '^kube')

total=0
restarted=0

for namespace in $namespaces; do
    echo "Processing namespace: $namespace"

    # Get all deployments in the namespace
    deployments=$(kubectl get deployments -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) || true

    if [ -z "$deployments" ]; then
        echo "  No deployments found"
        continue
    fi

    for deployment in $deployments; do
        echo "  Restarting deployment: $deployment"
        kubectl rollout restart deployment/"$deployment" -n "$namespace" || true
        ((restarted++))
    done
    ((total++))
    echo ""
done

echo "✓ Restart complete!"
echo "Restarted $restarted deployment(s) across $total namespace(s)"
