usage: hermes [-h] [--version] [-z PROMPT] [-m MODEL] [--provider PROVIDER]
              [-t TOOLSETS] [--resume SESSION] [--continue [SESSION_NAME]]
              [--worktree] [--accept-hooks] [--skills SKILLS] [--yolo]
              [--pass-session-id] [--ignore-user-config] [--ignore-rules]
              [--tui] [--dev]
              {chat,model,fallback,gateway,setup,whatsapp,slack,login,logout,auth,status,cron,webhook,hooks,doctor,dump,debug,backup,import,config,pairing,skills,plugins,curator,memory,tools,mcp,sessions,insights,claw,version,update,uninstall,acp,profile,completion,dashboard,logs} ...

Hermes Agent - AI assistant with tool-calling capabilities

positional arguments:
  {chat,model,fallback,gateway,setup,whatsapp,slack,login,logout,auth,status,cron,webhook,hooks,doctor,dump,debug,backup,import,config,pairing,skills,plugins,curator,memory,tools,mcp,sessions,insights,claw,version,update,uninstall,acp,profile,completion,dashboard,logs}
                        Command to run
    chat                Interactive chat with the agent
    model               Select default model and provider
    fallback            Manage fallback providers (tried when the primary
                        model fails)
    gateway             Messaging gateway management
    setup               Interactive setup wizard
    whatsapp            Set up WhatsApp integration
    slack               Slack integration helpers (manifest generation, etc.)
    login               Authenticate with an inference provider
    logout              Clear authentication for an inference provider
    auth                Manage pooled provider credentials
    status              Show status of all components
    cron                Cron job management
    webhook             Manage dynamic webhook subscriptions
    hooks               Inspect and manage shell-script hooks
    doctor              Check configuration and dependencies
    dump                Dump setup summary for support/debugging
    debug               Debug tools — upload logs and system info for support
    backup              Back up Hermes home directory to a zip file
    import              Restore a Hermes backup from a zip file
    config              View and edit configuration
    pairing             Manage DM pairing codes for user authorization
    skills              Search, install, configure, and manage skills
    plugins             Manage plugins — install, update, remove, list
    curator             Background skill maintenance (curator) — status, run,
                        pause, pin
    memory              Configure external memory provider
    tools               Configure which tools are enabled per platform
    mcp                 Manage MCP servers and run Hermes as an MCP server
    sessions            Manage session history (list, rename, export, prune,
                        delete)
    insights            Show usage insights and analytics
    claw                OpenClaw migration tools
    version             Show version information
    update              Update Hermes Agent to the latest version
    uninstall           Uninstall Hermes Agent
    acp                 Run Hermes Agent as an ACP (Agent Client Protocol)
                        server
    profile             Manage profiles — multiple isolated Hermes instances
    completion          Print shell completion script (bash, zsh, or fish)
    dashboard           Start the web UI dashboard
    logs                View and filter Hermes log files

options:
  -h, --help            show this help message and exit
  --version, -V         Show version and exit
  -z, --oneshot PROMPT  One-shot mode: send a single prompt and print ONLY the
                        final response text to stdout. No banner, no spinner,
                        no tool previews, no session_id line. Tools, memory,
                        rules, and AGENTS.md in the CWD are loaded as normal;
                        approvals are auto-bypassed. Intended for scripts /
                        pipes.
  -m, --model MODEL     Model override for this invocation (e.g.
                        anthropic/claude-sonnet-4.6). Applies to -z/--oneshot
                        and --tui. Also settable via HERMES_INFERENCE_MODEL
                        env var.
  --provider PROVIDER   Provider override for this invocation (e.g.
                        openrouter, anthropic). Applies to -z/--oneshot and
                        --tui. Also settable via HERMES_INFERENCE_PROVIDER env
                        var.
  -t, --toolsets TOOLSETS
                        Comma-separated toolsets to enable for this
                        invocation. Applies to -z/--oneshot and --tui.
  --resume, -r SESSION  Resume a previous session by ID or title
  --continue, -c [SESSION_NAME]
                        Resume a session by name, or the most recent if no
                        name given
  --worktree, -w        Run in an isolated git worktree (for parallel agents)
  --accept-hooks        Auto-approve any unseen shell hooks declared in
                        config.yaml without a TTY prompt. Equivalent to
                        HERMES_ACCEPT_HOOKS=1 or hooks_auto_accept: true in
                        config.yaml. Use on CI / headless runs that can't
                        prompt.
  --skills, -s SKILLS   Preload one or more skills for the session (repeat
                        flag or comma-separate)
  --yolo                Bypass all dangerous command approval prompts (use at
                        your own risk)
  --pass-session-id     Include the session ID in the agent's system prompt
  --ignore-user-config  Ignore ~/.hermes/config.yaml and fall back to built-in
                        defaults (credentials in .env are still loaded)
  --ignore-rules        Skip auto-injection of AGENTS.md, SOUL.md,
                        .cursorrules, memory, and preloaded skills
  --tui                 Launch the modern TUI instead of the classic REPL
  --dev                 With --tui: run TypeScript sources via tsx (skip dist
                        build)

Examples:
    hermes                        Start interactive chat
    hermes chat -q "Hello"        Single query mode
    hermes -c                     Resume the most recent session
    hermes -c "my project"        Resume a session by name (latest in lineage)
    hermes --resume <session_id>  Resume a specific session by ID
    hermes setup                  Run setup wizard
    hermes logout                 Clear stored authentication
    hermes auth add <provider>    Add a pooled credential
    hermes auth list              List pooled credentials
    hermes auth remove <p> <t>    Remove pooled credential by index, id, or label
    hermes auth reset <provider>  Clear exhaustion status for a provider
    hermes model                  Select default model
    hermes fallback [list]        Show fallback provider chain
    hermes fallback add           Add a fallback provider (same picker as `hermes model`)
    hermes fallback remove        Remove a fallback provider from the chain
    hermes config                 View configuration
    hermes config edit            Edit config in $EDITOR
    hermes config set model gpt-4 Set a config value
    hermes gateway                Run messaging gateway
    hermes -s hermes-agent-dev,github-auth
    hermes -w                     Start in isolated git worktree
    hermes gateway install        Install gateway background service
    hermes sessions list          List past sessions
    hermes sessions browse        Interactive session picker
    hermes sessions rename ID T   Rename/title a session
    hermes logs                   View agent.log (last 50 lines)
    hermes logs -f                Follow agent.log in real time
    hermes logs errors            View errors.log
    hermes logs --since 1h        Lines from the last hour
    hermes debug share             Upload debug report for support
    hermes update                 Update to latest version

For more help on a command:
    hermes <command> --help
