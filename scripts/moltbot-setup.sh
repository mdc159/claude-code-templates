#!/bin/bash
# Moltbot EC2 Configuration Script
# Created: 2026-01-28
#
# Usage:
#   ./moltbot-setup.sh
#
# Requires: SSH key at ~/.ssh/cldy.pem

set -e

EC2_HOST="ubuntu@18.227.161.31"
SSH_KEY="~/.ssh/cldy.pem"

echo "=== Moltbot EC2 Setup ==="
echo ""

# Check for API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    read -p "Enter your Anthropic API key: " ANTHROPIC_API_KEY
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: API key required"
    exit 1
fi

echo ""
echo "Configuring moltbot on EC2..."

ssh -i $SSH_KEY $EC2_HOST << REMOTE
sudo docker exec moltbot sh -c 'cat > /root/.clawdbot/clawdbot.json << CONFIG
{
  "gateway": { 
    "mode": "local" 
  },
  "models": {
    "providers": {
      "anthropic": { 
        "apiKey": "${ANTHROPIC_API_KEY}" 
      }
    }
  },
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "scope": "session",
        "workspaceAccess": "none"
      },
      "memorySearch": {
        "enabled": true,
        "provider": "anthropic"
      }
    }
  },
  "tools": {
    "deny": ["elevated"]
  },
  "approvals": {
    "exec": {
      "security": "deny",
      "askFallback": "deny"
    }
  }
}
CONFIG'

sudo docker restart moltbot
sleep 3
sudo docker logs moltbot --tail 10
REMOTE

echo ""
echo "=== Moltbot configured ==="
echo ""
echo "Gateway: http://18.227.161.31:18789"
echo ""
echo "Security:"
echo "  - All tools sandboxed (Docker)"
echo "  - No elevated/host access"
echo "  - Exec commands blocked"
echo "  - Memory search enabled"
echo ""
echo "Next: Connect a channel"
echo "  ssh -i ~/.ssh/cldy.pem ubuntu@18.227.161.31"
echo "  sudo docker exec -it moltbot node dist/entry.js channels login whatsapp"
echo ""
