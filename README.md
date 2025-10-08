# Keycloak Helm Chart

This Helm chart deploys Keycloak on a Kubernetes cluster.

## Features

- ✅ Customizable Keycloak deployment
- ✅ Integrated PostgreSQL database (optional)
- ✅ Ingress support with TLS
- ✅ Configurable health checks
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Optional data persistence
- ✅ Service Account and RBAC
- ✅ Proxy configuration for reverse proxy
- ✅ External secrets support
- ✅ Optional metrics

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume provisioner (if persistence is enabled)

## Installation

### Basic Installation

```bash
helm install keycloak .
```

### Installation with Custom Values

```bash
helm install keycloak . -f custom-values.yaml
```

### Installation in a Specific Namespace

```bash
kubectl create namespace keycloak
helm install keycloak . --namespace keycloak
```

### Quick Start with Makefile

```bash
# Development environment
make install-dev

# Production environment
make install-prod

# Default installation
make install
```

## Configuration

### Main Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `quay.io/keycloak/keycloak` |
| `image.tag` | Image tag | `26.4.0` |
| `image.pullPolicy` | Pull policy | `IfNotPresent` |

### Keycloak Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `keycloak.admin.username` | Admin username | `admin` |
| `keycloak.admin.password` | Admin password | `admin` |
| `keycloak.database.vendor` | Database type | `postgres` |
| `keycloak.database.host` | Database host | `postgresql` |
| `keycloak.database.database` | Database name | `keycloak` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress | `true` |
| `ingress.className` | Ingress class (only rendered if non-empty) | `""` |
| `ingress.hosts[0].host` | Hostname | `keycloak.url` |
| `ingress.tls` | TLS configuration | `[]` |

### PostgreSQL

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Deploy PostgreSQL | `true` |
| `postgresql.auth.username` | PostgreSQL username | `keycloak` |
| `postgresql.auth.password` | PostgreSQL password | `keycloak` |
| `postgresql.auth.database` | Database name | `keycloak` |

## Usage Examples

### 1. Installation with Ingress Enabled

```yaml
# values-ingress.yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: keycloak.mydomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: keycloak-tls
      hosts:
        - keycloak.mydomain.com

keycloak:
  proxy:
    enabled: true
    mode: edge
```

```bash
helm install keycloak . -f values-ingress.yaml
```

### 2. Installation with External Database

```yaml
# values-external-db.yaml
postgresql:
  enabled: false

keycloak:
  database:
    host: my-postgres.example.com
    port: 5432
    database: keycloak
    username: keycloak
    password: supersecret
```

```bash
helm install keycloak . -f values-external-db.yaml
```

### 3. High Availability Installation

```yaml
# values-ha.yaml
replicaCount: 3

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi

keycloak:
  cache:
    stack: kubernetes
```

```bash
helm install keycloak . -f values-ha.yaml
```

### 4. Installation with Existing Secrets

```yaml
# values-secrets.yaml
keycloak:
  admin:
    existingSecret: keycloak-admin-secret
    existingSecretKey: password
  database:
    existingSecret: keycloak-db-secret
    existingSecretUsernameKey: username
    existingSecretPasswordKey: password
```

First, create the secrets:

```bash
kubectl create secret generic keycloak-admin-secret \
  --from-literal=password=myAdminPassword

kubectl create secret generic keycloak-db-secret \
  --from-literal=username=keycloak \
  --from-literal=password=myDbPassword
```

Then install:

```bash
helm install keycloak . -f values-secrets.yaml
```

### 5. Installation with Metrics Enabled

```yaml
# values-metrics.yaml
keycloak:
  metrics:
    enabled: true
```

```bash
helm install keycloak . -f values-metrics.yaml
```

## Upgrade

```bash
helm upgrade keycloak . -f custom-values.yaml
```

Or using the Makefile:

```bash
make upgrade-dev    # Development
make upgrade-prod   # Production
make upgrade        # Default
```

## Uninstall

```bash
helm uninstall keycloak
```

Or:

```bash
make uninstall
```

## Accessing Keycloak

### Port-Forward for Local Testing

```bash
kubectl port-forward svc/keycloak 8080:8080
```

Or:

```bash
make port-forward
```

Then access: http://localhost:8080

### Default Credentials

- **Username**: admin
- **Password**: admin (change in production!)

## Keycloak 26 notes

- Health endpoints moved under `/q/health`:
  - Liveness: `/q/health/live`
  - Readiness: `/q/health/ready`
  - Startup: `/q/health/started`
  - If you set `KC_HTTP_RELATIVE_PATH=/auth`, health paths become `/auth/q/health/*`.
- With Traefik/Nginx terminating TLS (edge proxy): set `KC_HTTP_ENABLED=true`, `KC_PROXY_HEADERS=xforwarded`, and `KC_HOSTNAME` to your public host. Leave `ingress.className` empty unless you want to render it.
- Probes are disabled by default in this chart (set to null). Enable them with the paths above if desired.

## Troubleshooting

### View Keycloak Logs

```bash
kubectl logs -f deployment/keycloak
```

Or:

```bash
make logs
```

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=keycloak
```

### Verify Secrets

```bash
kubectl get secrets
```

### Get Admin Password

```bash
kubectl get secret keycloak-admin -o jsonpath="{.data.password}" | base64 --decode
```

Or:

```bash
make get-admin-password
```

### Access Pod for Debugging

```bash
kubectl exec -it deployment/keycloak -- /bin/bash
```

## Available Make Targets

```bash
make help                 # Show all available targets
make install             # Install with default values
make install-dev         # Install with development values
make install-prod        # Install with production values
make upgrade             # Upgrade existing installation
make uninstall           # Remove the installation
make template            # Generate manifests without installing
make lint                # Lint the chart
make port-forward        # Port-forward to Keycloak service
make logs                # Show Keycloak logs
make status              # Show release status
make get-admin-password  # Get admin password from secret
```

## Environment-Specific Configurations

### Development

Use `values-development.yaml` for local development:
- Single replica
- Minimal resources
- Bundled PostgreSQL without persistence
- No Ingress
- Debug logging enabled

```bash
make install-dev
```

### Production

Use `values-production.yaml` for production:
- 3 replicas with autoscaling
- High availability configuration
- External database
- Ingress with TLS
- Metrics enabled
- Pod anti-affinity rules

```bash
make install-prod
```

## Security Considerations

1. **Change default passwords** before deploying to production
2. **Use external secrets** instead of storing passwords in `values.yaml`
3. **Enable TLS** on Ingress
4. **Configure appropriate resource limits**
5. **Review pod security policies**
6. **Use strong admin credentials**
7. **Enable HTTPS** for production deployments
8. **Implement network policies** if required

## Monitoring and Metrics

Enable metrics in your values file:

```yaml
keycloak:
  metrics:
    enabled: true
```

Metrics will be available on port 9000 and can be scraped by Prometheus.

## Database Configuration

### Using Bundled PostgreSQL (Development)

The chart includes PostgreSQL by default:

```yaml
postgresql:
  enabled: true
  auth:
    username: keycloak
    password: keycloak
    database: keycloak
```

### Using External Database (Production)

For production, use an external database:

```yaml
postgresql:
  enabled: false

keycloak:
  database:
    host: your-postgres-host.com
    port: 5432
    database: keycloak
    username: keycloak
    existingSecret: keycloak-db-secret
```

## Supported Databases

- PostgreSQL (recommended)
- MySQL/MariaDB
- Oracle
- Microsoft SQL Server

Configure the database vendor in `keycloak.database.vendor`.

## High Availability

For HA deployments:

1. Set `replicaCount` to 3 or more
2. Enable `autoscaling`
3. Configure `cache.stack` to `kubernetes`
4. Use external database
5. Configure pod anti-affinity rules

```yaml
replicaCount: 3
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
keycloak:
  cache:
    stack: kubernetes
```

## Custom Themes

To add custom themes, use init containers:

```yaml
keycloak:
  themes:
    enabled: true
    initContainer:
      image: your-themes-image
      command:
        - sh
        - -c
        - cp -R /themes/* /opt/keycloak/themes/
```

## Identity Provider Integration

### Microsoft Entra ID (Azure AD)

This chart includes comprehensive support for Microsoft Entra ID integration. See the detailed guides:

- **[Microsoft Entra ID Integration Guide](docs/microsoft-entra-integration.md)** - Complete step-by-step configuration
- **[Quick Start Guide](docs/quick-start-microsoft-entra.md)** - Fast-track setup (20 minutes)
- **[values-microsoft-entra.yaml](values-microsoft-entra.yaml)** - Pre-configured values file

Quick deployment with Microsoft Entra ID support:

```bash
# Create secrets first
kubectl create secret generic keycloak-admin-credentials --from-literal=password='YourPassword'
kubectl create secret generic keycloak-db-credentials --from-literal=username='keycloak' --from-literal=password='DBPassword'

# Deploy
helm install keycloak . -f values-microsoft-entra.yaml --namespace keycloak --create-namespace
```

After deployment, follow the [integration guide](docs/microsoft-entra-integration.md) to configure the identity provider.

### Other Identity Providers

Keycloak supports integration with many identity providers:
- Google
- GitHub
- Facebook
- SAML providers
- LDAP/Active Directory
- Custom OpenID Connect providers

Refer to [Keycloak's Identity Brokering documentation](https://www.keycloak.org/docs/latest/server_admin/#_identity_broker) for configuration details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This Helm chart is open source. Keycloak is licensed under the Apache 2.0 License.

## Resources

- [Keycloak Official Documentation](https://www.keycloak.org/documentation)
- [Keycloak GitHub Repository](https://github.com/keycloak/keycloak)
- [Helm Documentation](https://helm.sh/docs/)
- [Microsoft Entra ID Integration](docs/microsoft-entra-integration.md)

## Support

For issues and questions:
- Keycloak: https://github.com/keycloak/keycloak/issues
- This Chart: Create an issue in the repository
