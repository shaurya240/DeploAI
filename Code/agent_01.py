# pip install strands-agents
# pip install 'strands-agents[ollama]'
# pip install strands-agents-tools
# https://github.com/strands-agents/tools

from strands import Agent
from strands.models.ollama import OllamaModel
from strands_tools import file_read, file_write, http_request

# 01: Create an Ollama model instance
ollama_model = OllamaModel(
    host="http://localhost:11434",  # Ollama server address
    model_id="gpt-oss:20b",  # Specify which model to use
)

# 02: Define the system prompt
system_prompt = """
You are a helpful personal assistant capable of performing local file actions and office tasks

Your key capabilities include:
1. Read, understand, and summarise files.
2. Create and write to files.
3. List directory contents and provide information on the files.
4. Summarize the text content of the files. 

You can use the following tools for this task:
- file_read: Read a file and return the content.
- file_write: Write to a file.
"""

# 03: Create an agent using the Ollama model
agent = Agent(
    model=ollama_model, system_prompt=system_prompt, tools=[file_read, file_write]
)

# Use the agent
agent(
    "What is the content of 'gullivers-travels.txt' located in the 'Data' directory? Please summarize it in less than 100 words."
)  # Prints model output to stdout by default
