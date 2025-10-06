# pip install strands-agents
# pip install 'strands-agents[ollama]'
# pip install strands-agents-tools
# https://github.com/strands-agents/tools

from strands import Agent
from strands.models.ollama import OllamaModel
from strands_tools import file_read, file_write, http_request, current_time

# 01: Create an Ollama model instance
ollama_model = OllamaModel(
    host="http://localhost:11434",  # Ollama server address
    model_id="gpt-oss:20b",  # Specify which model to use
)

# 02: Define the system prompt
system_prompt = """
You are a weather assistant with HTTP capabilities. You can:

1. Make HTTP requests to the National Weather Service API
2. Process and display weather forecast data
3. Provide weather information for locations in the United States

When retrieving weather information:
1. First get the coordinates or grid information using https://api.weather.gov/points/{latitude},{longitude} or https://api.weather.gov/points/{zipcode}
2. Then use the returned forecast URL to get the actual forecast

When displaying responses:
- Format weather data in a human-readable way
- Highlight important information like temperature, precipitation, and alerts
- Handle errors appropriately
- Convert technical terms to user-friendly language

Always explain the weather conditions clearly and provide context for the forecast.
"""

# 03: Create an agent using the Ollama model

agent = Agent(
    model=ollama_model,
    system_prompt=system_prompt,
    tools=[file_read, file_write, http_request, current_time],
)

# Use the agent
agent(
    "What is the weather in Tempe, AZ right now? Provide it in celsius."
)  # Prints model output to stdout by default
