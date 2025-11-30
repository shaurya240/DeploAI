# Use slim Python 3.13 base image
FROM python:3.13-slim
#FROM python:3.10.4-slim-bullseye

# Set working directory
WORKDIR /app

# Install system dependencies (curl useful for debugging)
# Commented for compatibility
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY ./app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy application code
COPY ./app /app

# Expose FastAPI port
EXPOSE 8000

# Run with Uvicorn
CMD ["uvicorn", "weather_ai_agent:app", "--host", "0.0.0.0", "--port", "8000"]