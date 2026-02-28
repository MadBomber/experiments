# Best MCP Servers for Claude Code

Comprehensive guide to MCP (Model Context Protocol) servers, ranked by value for software development workflows with Claude Code.

> **Key constraint:** Keep under 10 active servers / 80 tools total. Too many shrinks your context window from 200K to ~70K.

## Tier 1: Essential

### GitHub MCP Server (Official by GitHub)
- **What:** Full GitHub API — issues, PRs, commits, code search, CI/CD triggers, repo management
- **Stars:** ~16k
- **Maintained by:** GitHub (in collaboration with Anthropic)
- **GitHub:** https://github.com/github/github-mcp-server
- **Install:**
  ```
  claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
    --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" -s user
  ```

### Context7 (Documentation Lookup)
- **What:** Fetches up-to-date, version-specific documentation and code examples for thousands of libraries
- **Stars:** ~20k
- **Maintained by:** Upstash (free to use)
- **GitHub:** https://github.com/upstash/context7
- **Install:**
  ```
  claude mcp add context7 -- npx -y @upstash/context7-mcp@latest -s user
  ```

### Sequential Thinking
- **What:** Structured step-by-step reasoning for complex problems, architecture decisions, debugging
- **Maintained by:** Anthropic (official reference server)
- **GitHub:** https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking
- **Install:**
  ```
  claude mcp add sequential-thinking -s user -- npx -y @modelcontextprotocol/server-sequential-thinking
  ```

### Memory / Knowledge Graph
- **What:** Persistent memory using a local knowledge graph (JSONL). Stores entities, relations, observations across conversations
- **Maintained by:** Anthropic (official reference server)
- **GitHub:** https://github.com/modelcontextprotocol/servers/tree/main/src/memory
- **Install:**
  ```
  claude mcp add --scope project memory \
    -e MEMORY_FILE_PATH=./.claude/memory.json \
    -- npx -y @modelcontextprotocol/server-memory
  ```

### Playwright MCP (Browser Automation)
- **What:** Full browser automation — navigate, click, fill forms, screenshots, extract text/HTML, execute JS
- **Stars:** ~8k
- **Maintained by:** Microsoft
- **GitHub:** https://github.com/microsoft/playwright-mcp
- **Install:**
  ```
  claude mcp add playwright -- npx -y @anthropic-ai/mcp-playwright
  ```

---

## Tier 2: Highly Recommended for Dev Workflows

### Brave Search
- **What:** Web search via Brave's independent index. Free tier: 2,000 queries/month
- **Maintained by:** Anthropic (officially recommended search MCP)
- **Install:**
  ```
  claude mcp add brave-search -s user \
    -e BRAVE_API_KEY=your-key-here \
    -- npx -y @modelcontextprotocol/server-brave-search
  ```

### Tavily (AI-Optimized Search)
- **What:** Search engine designed for AI agents. Excels at technical/code queries. Free tier: 1,000 queries/month
- **Stars:** ~1.5k
- **GitHub:** https://github.com/tavily-ai/tavily-mcp
- **Install:**
  ```
  claude mcp add tavily -s user \
    -e TAVILY_API_KEY=your-key-here \
    -- npx -y tavily-mcp@latest
  ```

### Fetch
- **What:** Lightweight web content retrieval, converts to markdown for LLM consumption
- **Maintained by:** Anthropic (official reference server)
- **Install:**
  ```
  claude mcp add fetch -- npx -y @modelcontextprotocol/server-fetch
  ```

### Git
- **What:** Deep Git repository analysis — diffs, logs, blame, branches
- **Maintained by:** Anthropic (official reference server)
- **Install:**
  ```
  claude mcp add git -- npx -y @modelcontextprotocol/server-git
  ```

### Filesystem
- **What:** Secure file system operations with configurable access controls
- **Maintained by:** Anthropic (official reference server)
- **Install:**
  ```
  claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /path/to/allowed/dir
  ```

---

## Tier 3: Database Access

### DBHub by Bytebase (Multi-Database)
- **What:** PostgreSQL, MySQL, SQL Server, MariaDB, SQLite. Only 2 MCP tools — maximizes context window
- **Stars:** ~1k
- **GitHub:** https://github.com/bytebase/dbhub
- **Install:**
  ```
  claude mcp add db -- npx -y @bytebase/dbhub --dsn "postgresql://user:pass@host:5432/dbname"
  ```

### PostgreSQL
- **What:** Direct Postgres with schema introspection — PKs, FKs, indexes, column types, constraints
- **Maintained by:** Anthropic (official)
- **Install:**
  ```
  claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres "postgresql://user:pass@host/db"
  ```

### SQLite
- **What:** Read/write access to SQLite databases with schema exploration
- **Maintained by:** Anthropic (official)
- **Install:**
  ```
  claude mcp add sqlite -- npx -y @modelcontextprotocol/server-sqlite /path/to/db.sqlite
  ```

### Supabase (Official)
- **What:** 20+ tools for table design, migrations, SQL queries, database branching, project management
- **GitHub:** https://github.com/supabase-community/supabase-mcp
- **Install:**
  ```
  claude mcp add supabase -- npx -y @supabase/mcp-server-supabase@latest \
    --access-token YOUR_SUPABASE_TOKEN
  ```

### Upstash (Redis)
- **What:** Manage Redis instances, execute commands, manage backups
- **GitHub:** https://github.com/upstash/mcp-server
- **Install:**
  ```
  claude mcp add upstash -- npx -y @upstash/mcp-server@latest \
    --email YOUR_EMAIL --api-key YOUR_API_KEY
  ```

---

## Tier 4: Infrastructure & DevOps

### Terraform (Official HashiCorp)
- **What:** Provider schemas, modules, documentation, Terraform Cloud workspaces
- **GitHub:** https://github.com/hashicorp/terraform-mcp-server
- **Install:**
  ```
  claude mcp add terraform -- npx -y @hashicorp/terraform-mcp-server
  ```

### Kubernetes
- **What:** Pod/deployment management, logs, namespaces
- **GitHub:** https://github.com/containers/kubernetes-mcp-server
- **Install:**
  ```
  claude mcp add k8s -- npx -y @anthropic-ai/mcp-kubernetes
  ```

### Docker MCP Toolkit
- **What:** 200+ pre-built containerized MCP servers with one-click deployment
- **Reference:** https://www.docker.com/blog/add-mcp-servers-to-claude-code-with-mcp-toolkit/

### AWS MCP Servers (Official AWS Labs)
- **What:** 45+ specialized servers for S3, Lambda, DynamoDB, CloudFormation, EC2, etc.
- **Reference:** https://awslabs.github.io/mcp/

---

## Tier 5: Monitoring & Observability

### Sentry (Official)
- **What:** Issues, errors, stack traces, projects, Seer analysis
- **GitHub:** https://github.com/getsentry/sentry-mcp
- **Install:**
  ```
  claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
  ```

### Datadog (Official)
- **What:** APM, alerting, database monitoring, error tracking, feature flags
- **Reference:** https://docs.datadoghq.com/bits_ai/mcp_server/
- **Install:**
  ```
  claude mcp add --transport http datadog https://mcp.datadoghq.com/mcp \
    --header "DD-API-KEY: YOUR_KEY"
  ```

---

## Tier 6: Communication & Project Management

### Slack (Official)
- **What:** Search/send messages, read channel history, thread conversations, reminders
- **Reference:** https://docs.slack.dev/ai/slack-mcp-server/
- **Install:**
  ```
  claude mcp add --transport http slack https://mcp.slack.com/sse
  ```

### Notion (Official)
- **What:** Search, read, create, update pages and databases
- **Reference:** https://developers.notion.com/guides/mcp/mcp
- **Install:**
  ```
  claude mcp add --transport http notion https://mcp.notion.com/mcp
  ```

### Linear
- **What:** Create/update/query issues, projects, cycles
- **Status:** Community maintained; multiple implementations available

### Jira/Atlassian (Official)
- **What:** Jira work items and Confluence pages
- **Status:** Official Atlassian integration

### Figma (Official)
- **What:** Read designs, extract components, design tokens
- **GitHub:** https://github.com/figma/mcp-server-guide
- **Install:**
  ```
  claude mcp add --transport http figma https://mcp.figma.com/mcp
  ```

---

## Ruby/Rails-Specific

### Rails MCP Server
- **What:** Models, routes, controllers, AR associations, Stimulus controllers, view hierarchies. Uses progressive tool discovery (4 bootstrap tools) to minimize context usage
- **Stars:** ~194
- **GitHub:** https://github.com/maquina-app/rails-mcp-server
- **Install:**
  ```
  gem install rails-mcp-server
  rails-mcp-server init
  claude mcp add rails-mcp -- rails-mcp-server start
  ```

### Claude on Rails
- **What:** Development framework for Rails + Claude Code. Rails-specific CLAUDE.md conventions, agent skills, workflows
- **Maintained by:** Obie Fernandez
- **GitHub:** https://github.com/obie/claude-on-rails

### MCP-Rails
- **What:** Alternative Ruby gem for MCP in Rails applications
- **GitHub:** https://github.com/Tonksthebear/mcp-rails

---

## All Official Anthropic Reference Servers

From https://github.com/modelcontextprotocol/servers (~79k stars):

| Server | Purpose |
|---|---|
| Everything | Reference/test server (all MCP features) |
| Fetch | Web content fetching and markdown conversion |
| Filesystem | Secure file operations with access controls |
| Git | Git repository read, search, and manipulation |
| Memory | Knowledge graph persistent memory |
| Sequential Thinking | Step-by-step problem solving |
| Time | Time and timezone conversion |

---

## Best Practices

1. **Keep under 10 active servers / 80 tools** — context window shrinks dramatically with more
2. **Scope wisely:** `-s user` for universal servers (search, memory); `--scope project` for repo-specific (database, Rails)
3. **Use Claude Code's tool search / lazy loading** to reduce context usage by up to 95%
4. **Verify Node.js >= 18** before installing npm-based servers
5. **Store tokens in environment variables**, not in config files
6. **Manage with:** `claude mcp list` / `claude mcp remove <name>`

---

## Resource Links

- [Official MCP Servers Repo](https://github.com/modelcontextprotocol/servers) — 79k stars
- [Awesome MCP Servers (wong2)](https://github.com/wong2/awesome-mcp-servers) — Curated list
- [Awesome MCP Servers (punkpeye)](https://github.com/punkpeye/awesome-mcp-servers) — Large collection
- [Best-of MCP Servers (ranked)](https://github.com/tolkonepiu/best-of-mcp-servers) — 410+ ranked by quality
- [MCP Market Leaderboard](https://mcpmarket.com/leaderboards) — Top 100 by stars
- [Official MCP Registry](https://registry.modelcontextprotocol.io/) — Canonical registry
- [Claude Code MCP Docs](https://code.claude.com/docs/en/mcp) — Official setup guide
- [MCP Servers Directory](https://mcpservers.org/) — Searchable directory
