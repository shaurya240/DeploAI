from strands import Agent
from strands.models import BedrockModel
from strands_tools import http_request, current_time
from strands.agent.conversation_manager import SlidingWindowConversationManager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# --- Bedrock LLM ---
llm = BedrockModel(
    model_id="amazon.nova-micro-v1:0",  # Probably the cheapest
    region_name="us-east-1",
)

# --- System Prompt ---
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
- Do not provide forcasts of upcoming days unless user specifically asks for it

Always explain the weather conditions clearly and provide context for the forecast.
"""

# --- Conversation Manager ---
conversation_manager = SlidingWindowConversationManager(
    window_size=10,  # Keep last 20 messages
    should_truncate_results=True,  # Truncate tool results if too long
)

# --- Strands Agent ---
agent = Agent(
    model=llm,
    system_prompt=system_prompt,
    tools=[http_request, current_time],
    conversation_manager=conversation_manager,
)

# --- FastAPI App ---
app = FastAPI(title="Weather Chat Agent")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Or restrict to your S3 domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    user_input: str


class ChatResponse(BaseModel):
    response: str


# --- Chat endpoint ---
@app.post("/chat", response_model=ChatResponse)
def chat_endpoint(msg: ChatRequest):
    # Send user input directly; SlidingWindowConversationManager handles context
    result = agent(msg.user_input)
    response_text = getattr(result, "output_text", str(result))
    return ChatResponse(response=response_text)


# --- Health check ---
@app.get("/health")
def health():
    return {"status": "ok"}
