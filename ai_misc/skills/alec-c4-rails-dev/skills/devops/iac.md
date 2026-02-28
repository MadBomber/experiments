# Infrastructure as Code (Terraform & Ansible)

> **Goal:** Reproducible, immutable infrastructure.

## 1. Terraform (Provisioning)
Use for creating resources (Servers, Load Balancers, Databases, S3).

**State Management:**
- Store `terraform.tfstate` in a remote backend (S3/GCS) with locking (DynamoDB).
- **Never** commit `.tfstate` to git.

**Structure:**
```hcl
resource "hcloud_server" "web" {
  name        = "web-1"
  image       = "ubuntu-24.04"
  server_type = "cx22"
  location    = "hel1"
  ssh_keys    = [data.hcloud_ssh_key.default.id]
}
```

## 2. Ansible (Configuration)
Use for configuring the OS *inside* the servers (Security, Docker install, Users).

**Roles Pattern:**
- `roles/security` (UFW, Fail2Ban)
- `roles/docker` (Install Docker Engine)
- `roles/users` (Add sudo users)

**Playbook:**
```yaml
- hosts: web
  become: true
  roles:
    - security
    - docker
```

## 3. Best Practices
- **Idempotency:** Scripts should run multiple times without side effects.
- **Secrets:** Use `ansible-vault` or Terraform variables (TF_VAR_) for sensitive data.
- **Versions:** Pin provider versions in `required_providers`.
