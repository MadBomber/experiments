# Kamal Deployment Skills

> **Tool:** Kamal (formerly MRSK)
> **Platform:** Any Linux server (Hetzner, AWS, etc.)

## 1. Config Structure (`config/deploy.yml`)
Essential components:
- `service`: app-name
- `image`: docker-registry/app-name
- `servers`: web IPs
- `env`: clear and secret variables

## 2. Secrets Management
- Use `dotenv` or Rails Credentials.
- Never hardcode secrets in `deploy.yml`. Use `env: secret: [KAMAL_DB_PASSWORD]`.

## 3. Accessories
Defining managed services like Redis or Postgres.

```yaml
accessories:
  db:
    image: postgres:17 # Always use the latest stable version
    host: 1.2.3.4
    port: 5432
    env:
      POSTGRES_PASSWORD: <%= ENV["DB_PASSWORD"] %>
```

## 4. Useful Commands
- `kamal deploy`: Full deployment.
- `kamal env push`: Update env variables.
- `kamal app logs -f`: Stream logs.
- `kamal rollback`: Quick revert.
