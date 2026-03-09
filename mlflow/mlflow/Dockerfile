FROM python:3.11-slim

# Set working directory
WORKDIR /mlflow

# Copy requirements first (for better caching)
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
RUN chmod +x *

# Copy any other files

# Expose port for MLflow UI
EXPOSE 5000

ENTRYPOINT ["/mlflow/entrypoint.sh"]