# Kyverno Policies

These are collections of policies which implement the various levels of Kubernetes [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) for CSM services.

The policies are minimally restrictive and follows the common security best practices for Pods. The policies make sure the following values are set for workloads.

```
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  runAsUser: 65534
  runAsNonRoot: true
  runAsGroup: 65534
```

The preferred way of installing these Pod Security Standard policies is by using Helm.

While installing the chart all policies are enforced and incase of any issues, inidividual policies can be deleted using kubectl CLI as Kyverno is kubernetes native Policy engine.
