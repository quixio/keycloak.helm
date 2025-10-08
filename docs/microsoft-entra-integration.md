# Microsoft Entra ID Integration with Keycloak

This guide explains how to configure Microsoft Entra ID (formerly Azure Active Directory) as an Identity Provider in Keycloak.

## Prerequisites

- Keycloak instance running and accessible
- Microsoft Entra ID (Azure AD) tenant
- Admin access to both Keycloak and Microsoft Entra ID
- Keycloak URL (e.g., `https://keycloak.yourdomain.com`)

## Overview

This integration allows users to log in to applications protected by Keycloak using their Microsoft Entra ID credentials via OpenID Connect (OIDC).

## Step 1: Register Application in Microsoft Entra ID

### 1.1 Access Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Microsoft Entra ID** (or **Azure Active Directory**)
3. Click on **App registrations** in the left menu
4. Click **+ New registration**

### 1.2 Configure Application Registration

Fill in the registration form:

- **Name**: `Keycloak SSO` (or any descriptive name)
- **Supported account types**: Choose based on your needs:
  - **Single tenant**: Only users in your organization
  - **Multi-tenant**: Users from any organization
  - **Multi-tenant + personal accounts**: Include Microsoft personal accounts
- **Redirect URI**:
  - Platform: **Web**
  - URI: `https://keycloak.yourdomain.com/realms/{realm-name}/broker/microsoft/endpoint`
  
  Replace:
  - `keycloak.yourdomain.com` with your Keycloak domain
  - `{realm-name}` with your Keycloak realm name (e.g., `master` or `myrealm`)

Click **Register**.

### 1.3 Note the Application Details

After registration, note these values:

- **Application (client) ID**: e.g., `12345678-1234-1234-1234-123456789abc`
- **Directory (tenant) ID**: e.g., `87654321-4321-4321-4321-cba987654321`

### 1.4 Create Client Secret

1. In your app registration, go to **Certificates & secrets**
2. Click **+ New client secret**
3. Add a description: `Keycloak Integration`
4. Choose expiration period (recommended: 24 months)
5. Click **Add**
6. **Copy the secret value immediately** (you won't see it again!)

### 1.5 Configure API Permissions

1. Go to **API permissions**
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Choose **Delegated permissions**
5. Add these permissions:
   - `openid` (already included)
   - `profile`
   - `email`
   - `User.Read`
6. Click **Add permissions**
7. (Optional) Click **Grant admin consent** if required by your organization

### 1.6 Configure Token Configuration (Optional)

To include additional user information in tokens:

1. Go to **Token configuration**
2. Click **+ Add optional claim**
3. Select **ID** token type
4. Add claims:
   - `email`
   - `family_name`
   - `given_name`
   - `upn` (User Principal Name)
5. Click **Add**

## Step 2: Configure Keycloak

### 2.1 Access Keycloak Admin Console

1. Go to your Keycloak admin console: `https://keycloak.yourdomain.com`
2. Log in with admin credentials
3. Select the realm where you want to configure the integration

### 2.2 Add Microsoft Entra ID as Identity Provider

1. In the left menu, click **Identity Providers**
2. From the **Add provider** dropdown, select **OpenID Connect v1.0**
3. Configure the following:

#### Basic Settings:

- **Alias**: `microsoft` (or any identifier you prefer)
- **Display Name**: `Microsoft` or `Sign in with Microsoft`
- **Enabled**: ON
- **Trust Email**: ON (if you trust Microsoft's email verification)
- **First Login Flow**: `first broker login` (default)

#### OpenID Connect Configuration:

- **Authorization URL**: 
  ```
  https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/authorize
  ```

- **Token URL**: 
  ```
  https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token
  ```

- **Logout URL**: 
  ```
  https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/logout
  ```

- **User Info URL**: 
  ```
  https://graph.microsoft.com/oidc/userinfo
  ```

- **Client ID**: Paste the **Application (client) ID** from Azure
- **Client Secret**: Paste the **Client Secret** value from Azure

- **Default Scopes**: 
  ```
  openid profile email
  ```

- **Prompt**: `unset` or `select_account` (to force account selection)

- **Validate Signatures**: ON
- **Use JWKS URL**: ON
- **JWKS URL**: 
  ```
  https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys
  ```

Replace `{tenant-id}` with your **Directory (tenant) ID** from Azure.

#### Alternative: Using Well-Known Configuration

Instead of manually entering URLs, you can use the discovery endpoint:

1. Set **Discovery endpoint URL** to:
   ```
   https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration
   ```
2. Click **Import from URL**
3. This will auto-populate most fields

### 2.3 Save Configuration

Click **Save** at the bottom of the page.

### 2.4 Configure Mappers (Optional but Recommended)

Mappers help map Microsoft Entra ID user attributes to Keycloak user attributes.

1. In the Identity Provider configuration, click on the **Mappers** tab
2. Click **Create**

#### Email Mapper:
- **Name**: `email`
- **Mapper Type**: `Attribute Importer`
- **Claim**: `email`
- **User Attribute Name**: `email`

#### First Name Mapper:
- **Name**: `firstName`
- **Mapper Type**: `Attribute Importer`
- **Claim**: `given_name`
- **User Attribute Name**: `firstName`

#### Last Name Mapper:
- **Name**: `lastName`
- **Mapper Type**: `Attribute Importer`
- **Claim**: `family_name`
- **User Attribute Name**: `lastName`

#### Username Mapper:
- **Name**: `username`
- **Mapper Type**: `Attribute Importer`
- **Claim**: `preferred_username` or `email`
- **User Attribute Name**: `username`

## Step 3: Test the Integration

### 3.1 Access Login Page

1. Go to your application that uses Keycloak for authentication
2. Or directly access: `https://keycloak.yourdomain.com/realms/{realm-name}/account`

### 3.2 Test Login

1. You should see a **Microsoft** (or your display name) button
2. Click on it
3. You'll be redirected to Microsoft login page
4. Enter your Microsoft Entra ID credentials
5. Grant consent if prompted
6. You should be redirected back to Keycloak/your application

### 3.3 Verify User Creation

1. In Keycloak Admin Console, go to **Users**
2. You should see the new user created from Microsoft Entra ID
3. Check that attributes (email, name, etc.) are correctly mapped

## Step 4: Advanced Configuration

### 4.1 Restrict Access by Group

To only allow specific Microsoft Entra ID groups:

1. In Azure, configure group claims:
   - Go to **Token configuration**
   - Add **groups** claim
   
2. In Keycloak:
   - Create a mapper to import groups
   - Set up authentication flow to check group membership

### 4.2 Configure First Login Flow

Customize what happens when a user logs in for the first time:

1. In Keycloak, go to **Authentication**
2. Select **First Broker Login** flow
3. Customize the flow as needed (e.g., require email verification, review profile)

### 4.3 Enable Multi-Factor Authentication

MFA is handled by Microsoft Entra ID:

1. In Azure Portal, go to **Microsoft Entra ID** > **Security** > **Conditional Access**
2. Create policies to require MFA for specific users/groups
3. This will be enforced when users log in through Keycloak

## Troubleshooting

### Common Issues

#### 1. Redirect URI Mismatch

**Error**: `AADSTS50011: The redirect URI specified in the request does not match`

**Solution**: 
- Verify the Redirect URI in Azure exactly matches: 
  ```
  https://keycloak.yourdomain.com/realms/{realm-name}/broker/microsoft/endpoint
  ```
- Check for trailing slashes, http vs https, correct realm name

#### 2. Invalid Client Secret

**Error**: `Invalid client secret`

**Solution**:
- Verify you copied the secret **value**, not the secret ID
- Check if the secret has expired
- Create a new secret if needed

#### 3. Token Validation Failed

**Error**: `Failed to verify token`

**Solution**:
- Ensure **Validate Signatures** is enabled
- Verify the JWKS URL is correct
- Check that tenant ID in URLs is correct

#### 4. Missing Email or Profile Information

**Solution**:
- Verify API permissions include `email` and `profile`
- Grant admin consent for permissions
- Configure optional claims in Azure
- Check Keycloak mappers are properly configured

#### 5. Users Can't Log In

**Solution**:
- Check user is in correct tenant
- Verify **Supported account types** in Azure matches your users
- Check if conditional access policies are blocking access
- Review Keycloak logs for detailed errors

### Enable Debug Logging

In Keycloak, enable debug logging for identity providers:

1. In Admin Console, go to **Realm Settings** > **Events**
2. Enable **Login events**
3. Check logs at `/var/log/keycloak/keycloak.log` or via `kubectl logs`

## Security Best Practices

1. **Use Client Secrets with Long Expiration**: Set to 24 months and rotate before expiry
2. **Grant Minimal Permissions**: Only request necessary scopes
3. **Enable HTTPS**: Always use HTTPS for production
4. **Validate Tokens**: Keep signature validation enabled
5. **Monitor Access**: Use Azure AD audit logs and Keycloak events
6. **Implement Conditional Access**: Use Microsoft's conditional access policies
7. **Regular Security Reviews**: Review app permissions and user access regularly

## Multi-Tenant Support

If you need to support multiple Azure AD tenants:

1. In Azure: Set **Supported account types** to **Multitenant**
2. Use `common` or `organizations` instead of tenant ID in URLs:
   ```
   https://login.microsoftonline.com/common/oauth2/v2.0/authorize
   ```
3. Configure home realm discovery in Keycloak if needed

## Useful Links

- [Microsoft Identity Platform Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/)
- [Microsoft Entra ID OpenID Connect](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc)
- [Keycloak Identity Brokering Documentation](https://www.keycloak.org/docs/latest/server_admin/#_identity_broker)

## Example Configuration Files

### Azure App Registration (JSON Export)

```json
{
  "displayName": "Keycloak SSO",
  "signInAudience": "AzureADMyOrg",
  "web": {
    "redirectUris": [
      "https://keycloak.yourdomain.com/realms/master/broker/microsoft/endpoint"
    ]
  },
  "requiredResourceAccess": [
    {
      "resourceAppId": "00000003-0000-0000-c000-000000000000",
      "resourceAccess": [
        {
          "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
          "type": "Scope"
        },
        {
          "id": "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0",
          "type": "Scope"
        },
        {
          "id": "14dad69e-099b-42c9-810b-d002981feec1",
          "type": "Scope"
        }
      ]
    }
  ]
}
```

### Keycloak Identity Provider Export (JSON)

```json
{
  "alias": "microsoft",
  "displayName": "Microsoft",
  "providerId": "oidc",
  "enabled": true,
  "trustEmail": true,
  "storeToken": false,
  "addReadTokenRoleOnCreate": false,
  "authenticateByDefault": false,
  "linkOnly": false,
  "firstBrokerLoginFlowAlias": "first broker login",
  "config": {
    "authorizationUrl": "https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/authorize",
    "tokenUrl": "https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token",
    "logoutUrl": "https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/logout",
    "userInfoUrl": "https://graph.microsoft.com/oidc/userinfo",
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "defaultScope": "openid profile email",
    "validateSignature": "true",
    "useJwksUrl": "true",
    "jwksUrl": "https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys"
  }
}
```

## Support

For issues:
- **Azure AD**: [Microsoft Support](https://support.microsoft.com)
- **Keycloak**: [Keycloak Community](https://github.com/keycloak/keycloak/discussions)

## Keycloak 26 notes

- When running behind a reverse proxy (Traefik/Nginx) that terminates TLS (edge proxy), set:
  - `KC_HTTP_ENABLED=true`
  - `KC_PROXY_HEADERS=xforwarded`
  - `KC_HOSTNAME=<your-public-host>`
  - Optionally `KC_HTTP_RELATIVE_PATH=/auth` if your clients still call legacy `/auth/...` URLs.
- Avoid v1 hostname options in v26+ (e.g. `KC_HOSTNAME_URL`, `KC_HOSTNAME_ADMIN_URL`, `KC_HOSTNAME_STRICT_BACKCHANNEL`). Prefer strict hostname via `KC_HOSTNAME` and `keycloak.hostname.strict` in values.

