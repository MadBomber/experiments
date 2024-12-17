# README

```shell
thor
```

```
$ thor
Commands:
  thor help [COMMAND]  # Describe available commands or one specific command
  thor install NAME    # Install an optionally named Thor file into your system commands
  thor installed       # List the installed Thor modules and commands
  thor list [SEARCH]   # List the available thor commands (--substring means .*SEARCH)
  thor uninstall NAME  # Uninstall a named Thor module
  thor update NAME     # Update a Thor file from its original location
  thor version         # Show Thor version
```
```shell
thor project
```

```
Commands:
  thor project create NAME     # Create a new project
  thor project delete NAME     # Delete a project
  thor project help [COMMAND]  # Describe subcommands or one specific subcommand
  thor project list            # List all projects

Could not find command "project".
```


```shell
./project_manager.thor help
```

```
Commands:
  project_manager.thor help [COMMAND]              # Describe available commands or on...
  project_manager.thor project SUBCOMMAND ...ARGS  # Manage projects
  project_manager.thor task SUBCOMMAND ...ARGS     # Manage tasks within a project

Options:
  [--verbose], [--no-verbose], [--skip-verbose]
                                                 # Default: false
  [--debug], [--no-debug], [--skip-debug]
                                                 # Default: false

```
