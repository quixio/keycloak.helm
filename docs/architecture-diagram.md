# Keycloak with Microsoft Entra ID - Architecture

This document describes the architecture of Keycloak integrated with Microsoft Entra ID.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          End Users                               │
└────────────┬────────────────────────────────────┬───────────────┘
             │                                    │
             │ 1. Access Application              │ 3. Login with Microsoft
             │                                    │
             ▼                                    ▼
┌────────────────────────┐           ┌───────────────────────────┐
│                        │           │   Microsoft Entra ID      │
│   Your Application     │           │   (Azure Active Directory)│
│                        │           │                           │
│  - Web App             │           │  - User Authentication    │
│  - Mobile App          │           │  - MFA (optional)         │
│  - API                 │           │  - Conditional Access     │
│                        │           │  - Group Management       │
└────────┬───────────────┘           └──────────┬────────────────┘
         │                                      │
         │ 2. Redirect to SSO                   │ 4. OIDC Tokens
         │                                      │
         ▼                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Keycloak (SSO)                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Identity Brokering                                       │   │
│  │  - Microsoft Entra ID (OIDC)                             │   │
│  │  - Google, GitHub, etc.                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Realm Management                                         │   │
│  │  - Multiple Realms                                       │   │
│  │  - Clients (Applications)                                │   │
│  │  - Users & Roles                                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Session Management                                       │   │
│  │  - SSO Sessions                                          │   │
│  │  - Token Management                                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────┬───────────────────────────────────────────────────────┘
         │
         │ 5. Store User Data & Sessions
         ▼
┌─────────────────────────┐
│   PostgreSQL Database   │
│                         │
│  - User Data            │
│  - Sessions             │
│  - Configurations       │
└─────────────────────────┘
```

## Authentication Flow

### Standard Login Flow (with Microsoft Entra ID)

```
┌──────┐                ┌──────────┐               ┌──────────┐              ┌──────────────┐
│ User │                │   App    │               │ Keycloak │              │ Microsoft    │
│      │                │          │               │          │              │ Entra ID     │
└──┬───┘                └────┬─────┘               └────┬─────┘              └──────┬───────┘
   │                         │                          │                           │
   │  1. Access App          │                          │                           │
   ├────────────────────────>│                          │                           │
   │                         │                          │                           │
   │  2. Redirect to Login   │                          │                           │
   │<────────────────────────┤                          │                           │
   │                         │                          │                           │
   │  3. Request Auth        │                          │                           │
   ├─────────────────────────┼─────────────────────────>│                           │
   │                         │                          │                           │
   │  4. Show IdP Options    │                          │                           │
   │<────────────────────────┼──────────────────────────┤                           │
   │                         │                          │                           │
   │  5. Select Microsoft    │                          │                           │
   ├─────────────────────────┼─────────────────────────>│                           │
   │                         │                          │                           │
   │                         │   6. Redirect to MS      │                           │
   │<────────────────────────┼──────────────────────────┤                           │
   │                         │                          │                           │
   │  7. Microsoft Login     │                          │                           │
   ├─────────────────────────┼──────────────────────────┼──────────────────────────>│
   │                         │                          │                           │
   │  8. Enter Credentials   │                          │                           │
   │  (+ MFA if enabled)     │                          │                           │
   ├─────────────────────────┼──────────────────────────┼──────────────────────────>│
   │                         │                          │                           │
   │  9. Auth Code           │                          │                           │
   │<────────────────────────┼──────────────────────────┼───────────────────────────┤
   │                         │                          │                           │
   │  10. Redirect with Code │                          │                           │
   ├─────────────────────────┼─────────────────────────>│                           │
   │                         │                          │                           │
   │                         │  11. Exchange Code       │                           │
   │                         │  for Tokens              │                           │
   │                         │                          ├──────────────────────────>│
   │                         │                          │                           │
   │                         │  12. ID Token +          │                           │
   │                         │  Access Token            │                           │
   │                         │                          │<──────────────────────────┤
   │                         │                          │                           │
   │                         │  13. Create/Update User  │                           │
   │                         │  in Keycloak             │                           │
   │                         │                          │                           │
   │  14. Create Session     │                          │                           │
   │  & Issue Tokens         │                          │                           │
   │<────────────────────────┼──────────────────────────┤                           │
   │                         │                          │                           │
   │  15. Redirect to App    │                          │                           │
   │  with Keycloak Tokens   │                          │                           │
   ├────────────────────────>│                          │                           │
   │                         │                          │                           │
   │  16. Access Granted     │                          │                           │
   │<────────────────────────┤                          │                           │
   │                         │                          │                           │
```

## Kubernetes Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Ingress Controller                       │ │
│  │              (nginx, traefik, etc.)                        │ │
│  │                                                             │ │
│  │  Routes:                                                   │ │
│  │  - keycloak.yourdomain.com → Keycloak Service            │ │
│  │  - TLS Termination                                        │ │
│  └──────────────────────┬─────────────────────────────────────┘ │
│                         │                                        │
│                         ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            Keycloak Service (ClusterIP)                  │   │
│  │  - Port 8080 (HTTP)                                      │   │
│  │  - Port 8443 (HTTPS)                                     │   │
│  │  - Port 9000 (Metrics - optional)                        │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          Keycloak Deployment / StatefulSet                │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Keycloak     │  │ Keycloak     │  │ Keycloak     │   │  │
│  │  │ Pod 1        │  │ Pod 2        │  │ Pod 3        │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │ Resources:   │  │ Resources:   │  │ Resources:   │   │  │
│  │  │ CPU: 1-2     │  │ CPU: 1-2     │  │ CPU: 1-2     │   │  │
│  │  │ Mem: 1-2Gi   │  │ Mem: 1-2Gi   │  │ Mem: 1-2Gi   │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │ Probes:      │  │ Probes:      │  │ Probes:      │   │  │
│  │  │ - Liveness   │  │ - Liveness   │  │ - Liveness   │   │  │
│  │  │ - Readiness  │  │ - Readiness  │  │ - Readiness  │   │  │
│  │  │ - Startup    │  │ - Startup    │  │ - Startup    │   │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │  │
│  │         │                  │                  │           │  │
│  │         └──────────────────┼──────────────────┘           │  │
│  │                            │                              │  │
│  └────────────────────────────┼──────────────────────────────┘  │
│                               │                                  │
│                               ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         PostgreSQL Service (ClusterIP)                    │  │
│  └──────────────────────┬───────────────────────────────────┘  │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │      PostgreSQL StatefulSet                               │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────┐         │  │
│  │  │ PostgreSQL Pod                                │         │  │
│  │  │                                               │         │  │
│  │  │ - Persistent Volume Claim (8-10Gi)           │         │  │
│  │  │ - Database: keycloak                         │         │  │
│  │  │ - User credentials from Secret                │         │  │
│  │  └──────────────────────────────────────────────┘         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     Secrets                               │  │
│  │                                                            │  │
│  │  - keycloak-admin-credentials                            │  │
│  │    * Admin password                                       │  │
│  │                                                            │  │
│  │  - keycloak-db-credentials                               │  │
│  │    * Database username                                    │  │
│  │    * Database password                                    │  │
│  │                                                            │  │
│  │  - keycloak-tls (optional)                               │  │
│  │    * TLS certificate                                      │  │
│  │    * TLS key                                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Horizontal Pod Autoscaler (HPA)                   │  │
│  │                                                            │  │
│  │  - Min Replicas: 2-3                                      │  │
│  │  - Max Replicas: 8-10                                     │  │
│  │  - Target CPU: 70-75%                                     │  │
│  │  - Target Memory: 80%                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow

### User Authentication Data Flow

```
1. User Attributes Flow (Microsoft → Keycloak)

   Microsoft Entra ID User                 Keycloak User
   ┌─────────────────────┐                ┌──────────────────┐
   │ UPN                 │───mapped to──→ │ Username         │
   │ given_name          │───mapped to──→ │ First Name       │
   │ family_name         │───mapped to──→ │ Last Name        │
   │ email               │───mapped to──→ │ Email            │
   │ groups (optional)   │───mapped to──→ │ Roles/Groups     │
   └─────────────────────┘                └──────────────────┘


2. Token Flow

   Microsoft Tokens                        Keycloak Tokens
   ┌─────────────────────┐                ┌──────────────────┐
   │ ID Token            │                │ Access Token     │
   │ Access Token        │──exchanged──→  │ ID Token         │
   │ Refresh Token       │    for         │ Refresh Token    │
   └─────────────────────┘                └──────────────────┘
```

## Security Layers

```
┌──────────────────────────────────────────────────────────────────┐
│                      Security Layers                              │
│                                                                    │
│  Layer 1: Network Security                                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - Ingress with TLS/SSL (cert-manager)                      │  │
│  │ - Network Policies (optional)                              │  │
│  │ - Firewall Rules                                           │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Layer 2: Identity & Access                                       │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - Microsoft Entra ID Authentication                        │  │
│  │ - Multi-Factor Authentication (Azure)                      │  │
│  │ - Conditional Access Policies                              │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Layer 3: Application Security                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - Keycloak Admin Access Control                            │  │
│  │ - Realm Isolation                                          │  │
│  │ - Client Secrets                                           │  │
│  │ - Token Validation                                         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Layer 4: Kubernetes Security                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - RBAC (Role-Based Access Control)                         │  │
│  │ - Service Accounts                                         │  │
│  │ - Pod Security Policies                                    │  │
│  │ - Secrets Encryption at Rest                               │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Layer 5: Data Security                                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - Database Encryption                                       │  │
│  │ - Secrets Management (Kubernetes Secrets)                  │  │
│  │ - Backup & Disaster Recovery                               │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Scalability & High Availability

```
┌──────────────────────────────────────────────────────────────────┐
│                  Scalability Features                             │
│                                                                    │
│  Horizontal Scaling                                               │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - HPA based on CPU/Memory metrics                          │  │
│  │ - Multiple Keycloak replicas (2-10)                        │  │
│  │ - Load balancing via Kubernetes Service                    │  │
│  │ - Session replication (Kubernetes cache stack)             │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  High Availability                                                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - Multiple replicas across nodes                           │  │
│  │ - Pod anti-affinity rules                                  │  │
│  │ - External PostgreSQL with replication                     │  │
│  │ - Health checks & automatic restart                        │  │
│  │ - Rolling updates with zero downtime                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Monitoring & Observability                                       │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ - Keycloak metrics (optional)                              │  │
│  │ - Kubernetes events                                        │  │
│  │ - Application logs                                         │  │
│  │ - Health check endpoints                                   │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Component Versions

| Component | Version | Purpose |
|-----------|---------|---------|
| Keycloak | 23.0.0 | Identity & Access Management |
| PostgreSQL | Latest | Database for Keycloak |
| Kubernetes | 1.19+ | Container orchestration |
| Helm | 3.0+ | Package manager |
| Microsoft Entra ID | v2.0 | External Identity Provider |

## Network Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Keycloak main interface |
| 8443 | HTTPS | Keycloak secure interface |
| 9000 | HTTP | Metrics (optional) |
| 5432 | TCP | PostgreSQL database |
| 443 | HTTPS | Ingress (external access) |

## References

- [Keycloak Architecture](https://www.keycloak.org/docs/latest/server_admin/#_architecture)
- [Microsoft Identity Platform](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-overview)
- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)

