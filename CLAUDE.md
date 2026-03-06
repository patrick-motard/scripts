# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal scripts repository containing shell scripts, Ruby scripts, and related utilities for development workflow automation.

## Important: Keep Scripts Generic

**CRITICAL**: This repository must remain generic and free of company-specific information. Never include:
- Company names, URLs, or domain names (e.g., company.com, company.atlassian.net)
- Specific repository names (e.g., company-backend, internal-tools)
- Employee names or email addresses
- Passwords, API keys, tokens, or credentials
- Environment variable values specific to a company
- Any proprietary or confidential information

When creating examples or default configurations:
- Use placeholder values like `example.com`, `user@example.com`, `my-repo`
- Make patterns configurable via config files (e.g., `~/.config/tool-name/config.yml`)
- Provide clear comments showing users where to customize for their environment
- Use generic project/repo names in examples: `MYPROJECT`, `my-repo`, `repo-one`

## Script Creation Conventions

When creating new scripts:
- Use `#!/usr/bin/env zsh` shebang (prefer zsh over bash)
- Include a `usage` variable with NAME, SYNOPSIS, DESCRIPTION, ARGUMENTS, and EXAMPLES sections
- Use `while/case` pattern for argument parsing
- Make scripts executable after creation (`chmod +x`)
- Match the style of existing scripts like `compress-video` or `new_script`

Example structure:
```zsh
#!/usr/bin/env zsh

usage="NAME
      script-name - brief description

SYNOPSIS
      script-name [-h] [-o OPTION] input

DESCRIPTION
      Longer description of what the script does.

ARGUMENTS
      input
          Description of input argument.

      -o, --option VALUE
          Description of option.

      -h, --help
          Show this help message.

EXAMPLES
      script-name input.txt
      script-name -o value input.txt
"

# Argument parsing with while/case
while (( $# > 0 )); do
    case "$1" in
    -h | --help)
        echo "$usage"
        exit 0
        ;;
    -o | --option)
        option=$2
        shift 2
        ;;
    -*)
        echo "Unknown option: $1" >&2
        echo "$usage" >&2
        exit 1
        ;;
    *)
        break
        ;;
    esac
done
```

## Key Scripts

### GitHub PR Tools (`github/`)
Interactive PR management system using fzf:
- `pr-select` - Main entry point, interactive PR selector with preview
- `team-open-prs` - Fetches PRs from configured repos (supports `--format json|markdown`, `--age`, `--user`, `--cache-ttl`)
- `pr-cache-refresh` - Background cache refresh for PRs
- `select-repos` / `select-contributors` - Configure watched repos and users
- `.pr-config` - Shared config loader (sources this, then use `get_config key default`)

Config files stored in `~/.config/gh-pr-select/`:
- `repos.txt` - Watched repositories
- `contributors.txt` - Watched GitHub users
- `config.yml` - Settings (age_days, cache_ttl_minutes, refresh_interval_minutes)

### Other Notable Scripts
- `gh-watch-pr` - Ruby script to watch GitHub Actions status for current branch's PR
- `compress-video` - Compress video files for GitHub uploads (ffmpeg)
- `new_script` - Create new scripts with boilerplate
- `squash` - Git workflow helper to squash branch commits

## Dependencies

Scripts commonly depend on:
- `gh` (GitHub CLI) - PR operations
- `fzf` - Interactive selection
- `jq` / `yq` - JSON/YAML parsing
- `ffmpeg` - Video compression

## Commit Messages

Never use emojis, co-authoring mentions, or AI generation notes in commit messages.
