#!/bin/bash
# ============================================================================
# Generate Configuration - Creates runtime config from environment variables
# ============================================================================
# This script generates a JavaScript configuration file with environment 
# variables that will be available to the frontend at runtime.
# Executed during Amplify build phase.

set -e

CONFIG_FILE="curriculum/config.js"

# Generate config.js with environment variables
cat > "$CONFIG_FILE" << EOF
/**
 * Runtime Configuration
 * Auto-generated during build - DO NOT EDIT MANUALLY
 */
window.__CONFIG__ = {
    API_ENDPOINT: '${API_ENDPOINT:-https://localhost:3000}',
    ENVIRONMENT: '${ENV:-development}'
};
EOF

echo "✅ Configuration generated at $CONFIG_FILE"
echo "API_ENDPOINT: ${API_ENDPOINT}"

