## Patch service for dualstack
```bash
kubectl get svc -n postgres -o name | while read svc; do
  kubectl patch "$svc" -n postgres --type merge -p '{
    "spec": {
      "ipFamilyPolicy": "PreferDualStack",
      "ipFamilies": ["IPv4", "IPv6"]
    }
  }'
done
```
