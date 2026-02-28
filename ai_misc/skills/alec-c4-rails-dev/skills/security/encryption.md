# Data Encryption & Protection

> **Gems:** `lockbox`, `blind_index`
> **Goal:** Encrypt sensitive PII (Personally Identifiable Information) at rest.

## 1. Encryption (Lockbox)
Encrypts data in the database so even a dump is useless without the key.

### Model Setup
```ruby
class User < ApplicationRecord
  # Encrypts the 'email_ciphertext' column
  has_encrypted :email, :phone
end
```

### Migration
You need a `_ciphertext` column.
```ruby
add_column :users, :email_ciphertext, :text
remove_column :users, :email # Optional, after migration
```

## 2. Searching Encrypted Data (Blind Index)
Standard encryption prevents `User.find_by(email: ...)`. Blind Index solves this by hashing.

### Model Setup
```ruby
class User < ApplicationRecord
  has_encrypted :email
  blind_index :email
end
```

### Migration
```ruby
add_column :users, :email_bidx, :string
add_index :users, :email_bidx
```

### Usage
```ruby
# Now this works!
User.find_by(email: "test@example.com")
```

## 3. Key Management
- Run `rails lockbox:install` to generate `config/master.key`.
- **NEVER** commit the master key.
- Rotate keys if compromised.
