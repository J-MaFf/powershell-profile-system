# Memory MCP Server Configuration

This repository is configured to use the Memory MCP server with workspace-local knowledge graph storage.

## ✅ Automatic Configuration (Already Done)

The following files are already configured in this repository:

1. **`.vscode/mcp.json`** - Workspace-level MCP server configuration
2. **`.gitignore`** - Configured to track `knowledge-graph.jsonl`
3. **`.vscode/settings.json`** - Cleared of invalid `chat.mcp.serverSampling` entries

## 🔧 Manual Setup Required

### Remove Memory Server from Global MCP Config

To prevent conflicts and ensure workspace-local storage works correctly, you need to remove any Memory server configuration from your global MCP settings:

**Location:** `~/.vscode/User/profiles/[your-profile]/mcp.json`

**Steps:**
1. Open the global MCP configuration file
2. Remove the `"memory"` entry from the `"servers"` or `"mcpServers"` section
3. Save the file

**Example - Before:**
```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "other-server": { ... }
  }
}
```

**Example - After:**
```json
{
  "mcpServers": {
    "other-server": { ... }
  }
}
```

> **Why?** Global MCP configuration takes precedence over workspace settings. By removing the global Memory server configuration, the workspace-level configuration in `.vscode/mcp.json` will be used instead, enabling per-repository knowledge graphs.

## 📝 How It Works

### Configuration Hierarchy
1. **Workspace-level** (`.vscode/mcp.json`) - Used when global config doesn't define the same server
2. **Global-level** (`~/.vscode/User/profiles/[profile]/mcp.json`) - Takes precedence if server is defined

### Workspace Configuration
The `.vscode/mcp.json` file configures the Memory MCP server with:
- **`servers`** key (not `mcpServers`) for proper MCP protocol
- **`type: "stdio"`** for standard input/output communication
- **`MEMORY_FILE_PATH`** pointing to `${workspaceFolder}/knowledge-graph.jsonl`

```json
{
  "servers": {
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "${workspaceFolder}/knowledge-graph.jsonl"
      }
    }
  }
}
```

## ✨ Benefits

- **🗂️ Workspace-local storage**: Each repository has its own `knowledge-graph.jsonl`
- **🔄 Git backup**: Knowledge graph is tracked in git for backup and sync
- **🌍 Cross-machine sync**: Pull the repository on another machine and get the knowledge graph
- **🚫 No contamination**: Knowledge from one project doesn't leak into another
- **✅ Variable expansion**: `${workspaceFolder}` properly expands to the workspace path

## 🐛 Troubleshooting

### Memory Server Not Using Workspace Storage

**Symptom:** Changes are not being saved to `knowledge-graph.jsonl` in the workspace

**Solution:**
1. Verify you removed the Memory server from global MCP config (see above)
2. Restart VS Code to reload configurations
3. Check that `.vscode/mcp.json` exists in the workspace

### Invalid Configuration Error

**Symptom:** VS Code shows "Invalid MCP configuration" error

**Possible causes:**
- Using `mcpServers` instead of `servers` in `.vscode/mcp.json`
- Missing `type: "stdio"` in the server configuration
- JSON syntax errors in `.vscode/mcp.json`

**Solution:** Verify `.vscode/mcp.json` matches the format shown above

### Knowledge Graph Not Tracked in Git

**Symptom:** `knowledge-graph.jsonl` appears in `.gitignore`

**Solution:** The file should NOT be in `.gitignore`. Check that `.gitignore` has the comment noting it's intentionally tracked:
```
# Note: knowledge-graph.jsonl is intentionally NOT ignored
# It will be tracked in Git for backup and sync purposes
```

## 📚 References

- **File Format:** JSONL (JSON Lines) - one JSON object per line
- **MCP Protocol:** Model Context Protocol for AI tool integration
- **Variable Expansion:** VS Code workspace variables like `${workspaceFolder}`

## 🤝 Contributing

If you find issues with the Memory MCP server configuration, please open an issue with:
- Description of the problem
- Your VS Code version
- Contents of your global MCP config (sanitized)
- Any error messages from VS Code
