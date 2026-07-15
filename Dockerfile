# Use a lightweight Python base image
FROM python:3.12-slim

# Set working directory inside the container
WORKDIR /app

# Copy the application script
COPY hello.py .

# Run the script when the container starts
CMD ["python", "hello.py"]
