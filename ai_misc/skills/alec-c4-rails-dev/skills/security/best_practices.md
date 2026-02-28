# Security Best Practices

> **Goal:** OWASP Top 10 Compliance.
> **Tools:** Brakeman, Bundler Audit.

## 1. Automated Scanning
- **Brakeman:** Run `brakeman -q` before every commit. Address strict warnings immediately.
- **Bundler Audit:** Run `bundle audit check --update` to find vulnerable gems.

## 2. Common Vulnerabilities

### SQL Injection (SQLi)
**BAD:**
```ruby
User.where("name = '#{params[:name]}'")
```
**GOOD:**
```ruby
User.where(name: params[:name])
# OR
User.where("name = ?", params[:name])
```

### Cross-Site Scripting (XSS)
**BAD:**
```erb
<%= raw @comment.body %>
<%= @comment.body.html_safe %>
```
**GOOD:**
```erb
<%= @comment.body %>
<%# OR sanitization %>
<%= sanitize @comment.body, tags: %w(b i) %>
```

### Mass Assignment
**BAD:**
```ruby
User.create(params[:user])
```
**GOOD:**
```ruby
User.create(user_params)

def user_params
  params.require(:user).permit(:name, :email) # Explicit whitelist
end
```

## 3. Headers & Config
- **Force SSL:** `config.force_ssl = true` in Production.
- **CSP:** Configure `Content-Security-Policy` to block unauthorized scripts.
- **Cookies:** Ensure `Secure` and `HttpOnly` flags are set (Rails default).
