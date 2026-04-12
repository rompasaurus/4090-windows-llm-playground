# Set environment variables for the current session
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
$env:ANTHROPIC_AUTH_TOKEN = "ollama"

# Start Claude with the specified model
claude --model gemma4:31b
