---
name: code_review
type: repo
version: 1.0.0
agent: CodeActAgent
triggers:
  - git commit
  - code review
  - review code
  - 代码审查
  - 审查代码
---

# Code Review Microagent

This microagent is responsible for reviewing code commits in the Game server repository.

## Repository Overview

This is a lightweight game server framework built on [Skynet](https://github.com/cloudwu/skynet), featuring WebSocket support for real-time client connections.

### Project Structure

- `etc/` - Configuration files
  - `config` - Main server configuration
  - `config.client` - Client configuration
  - `config.path` - Path configuration
- `lualib/` - Shared Lua libraries
  - `batch.lua` - Batch processing utilities
  - `logger.lua` - Logging utilities
  - `timer.lua` - Timer utilities
  - `utils/` - Additional utility modules
- `module/` - Game modules
  - `ws_agent/` - WebSocket agent module
  - `ws_watchdog/` - WebSocket watchdog module
- `service/` - Skynet services
  - `main.lua` - Main entry point
  - `log.lua` - Logging service
  - `ws_agent.lua` - WebSocket agent service
  - `ws_gate.lua` - WebSocket gate service
  - `ws_watchdog.lua` - WebSocket watchdog service
- `test/` - Test files
  - `client.lua` - Test client
  - `mng.lua` - Test manager
  - `cmds/` - Test commands

## Code Review Guidelines

When reviewing code commits, please follow these guidelines:

### 1. Code Quality
- Check for proper Lua syntax and coding conventions
- Ensure consistent code style throughout the codebase
- Look for potential bugs or logic errors
- Verify proper error handling

### 2. Skynet-Specific Checks
- Verify correct usage of Skynet APIs
- Check for proper service lifecycle management
- Ensure message passing is handled correctly
- Review coroutine usage and potential deadlocks

### 3. WebSocket Implementation
- Verify WebSocket protocol compliance
- Check for proper connection handling
- Review message serialization/deserialization
- Ensure proper cleanup on disconnection

### 4. Configuration
- Verify configuration changes are backward compatible
- Check for proper default values
- Ensure sensitive information is not hardcoded

### 5. Performance
- Look for potential performance bottlenecks
- Check for memory leaks
- Review resource cleanup

### 6. Security
- Check for input validation
- Review authentication/authorization logic
- Look for potential injection vulnerabilities

## Review Process

1. Use `git log` to view recent commits
2. Use `git diff` or `git show` to examine changes
3. Analyze the code changes against the guidelines above
4. Provide constructive feedback with specific suggestions
5. Highlight both issues and good practices
