# Game Server

A lightweight game server framework built on [Skynet](https://github.com/cloudwu/skynet), featuring WebSocket support for real-time client connections.

## Project Structure

```
Game/
├── etc/              # Configuration files
│   ├── config        # Main server configuration
│   ├── config.client # Client configuration
│   └── config.path   # Path configuration
├── lualib/           # Shared Lua libraries
│   ├── batch.lua     # Batch processing utilities
│   ├── logger.lua    # Logging utilities
│   ├── timer.lua     # Timer utilities
│   └── utils/        # Additional utility modules
├── module/           # Game modules
│   ├── ws_agent/     # WebSocket agent module
│   └── ws_watchdog/  # WebSocket watchdog module
├── service/          # Skynet services
│   ├── main.lua      # Main entry point
│   ├── log.lua       # Logging service
│   ├── ws_agent.lua  # WebSocket agent service
│   ├── ws_gate.lua   # WebSocket gate service
│   └── ws_watchdog.lua # WebSocket watchdog service
└── test/             # Test files
    ├── client.lua    # Test client
    ├── mng.lua       # Test manager
    └── cmds/         # Test commands
```

## Configuration

The main configuration file is located at [`etc/config`](etc/config). Key settings include:

| Setting | Default | Description |
|---------|---------|-------------|
| `ws_watchdog_port` | 8080 | WebSocket server port |
| `ws_watchdog_max_online_client` | 1024 | Maximum concurrent client connections |
| `ws_watchdog_protocol` | ws | WebSocket protocol type |
| `debug_console_port` | 4040 | Debug console port |

## Getting Started

1. Make sure you have [Skynet](https://github.com/cloudwu/skynet) installed and configured.

2. Start the server:

```bash
./skynet etc/config
```

The WebSocket server will listen on port 8080 by default.

## License

See the project repository for license information.
