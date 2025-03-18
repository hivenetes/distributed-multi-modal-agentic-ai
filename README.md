# Distributed Multi-Modal Agentic AI

This application converts spoken descriptions into AI-generated images with automatic captions. It uses state-of-the-art AI models for speech recognition, image generation, and image captioning, while storing the results in both a PostgreSQL database and DigitalOcean Spaces.

## Features

- 🎤 **Speech-to-Text**: Uses OpenAI's Whisper model for accurate speech recognition
- 🎨 **Image Generation**: Generates images from text using Flux Schnell model
- 📝 **Image Captioning**: Automatically generates image descriptions using BLIP model
- 🗄️ **Storage Solutions**:
  - Images stored in DigitalOcean Spaces
  - Metadata stored in PostgreSQL database
- 🌐 **Modern UI**: Built with Gradio for a clean, user-friendly interface
- 🚀 **Infrastructure as Code**: Uses Terraform to provision and manage cloud infrastructure
- 📦 **Containerized Deployment**: Docker-based deployment to Digital Ocean droplets

## Project Structure

```
distributed-multi-modal-agentic-ai/
├── app.py                       # Main application file
├── db_config.py                 # Database configuration and models
├── requirements.txt             # Project dependencies
├── Dockerfile                   # Docker configuration
├── docker-compose.yml           # Local Docker Compose configuration
├── docker-compose.production.yml # Production Docker Compose configuration
├── .env.example                 # Example environment variables
├── .env                         # Environment variables (create from .env.example)
├── infrastructure/              # Terraform infrastructure code
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Terraform variables
│   ├── outputs.tf               # Terraform outputs
│   ├── provider.tf              # Provider configuration
│   ├── vpc.tf                   # VPC configuration
│   ├── postgres.tf              # PostgreSQL database configuration
│   ├── spaces.tf                # DigitalOcean Spaces configuration
│   └── project.tfvars.example   # Example Terraform variables file
└── scripts/                     # Deployment scripts
    └── deploy.sh                # Deployment script for servers
```

## Prerequisites

- Python 3.8+
- Docker and Docker Compose
- Terraform 1.0+
- DigitalOcean account with API token
- Replicate API key
- OpenAI API key
- SSH key for server access

## Setup Guide

### 1. Local Development Setup

1. Clone the repository:

```bash
git clone https://github.com/hivenetes/distributed-multi-modal-agentic-ai.git
cd distributed-multi-modal-agentic-ai
```

2. Install required packages:

```bash
pip install -r requirements.txt
```

3. Create environment file:

```bash
cp .env.example .env
```

4. Edit the `.env` file with your credentials:

```
REPLICATE_API_TOKEN=your_replicate_api_token
OPENAI_API_KEY=your_openai_api_key

# DigitalOcean Spaces Configuration
SPACES_KEY=your_spaces_key
SPACES_SECRET=your_spaces_secret
SPACES_REGION=your_spaces_region
SPACES_BUCKET=your_bucket_name
SPACES_ENDPOINT=your_spaces_endpoint

# PostgreSQL Database Configuration
DB_HOST=your_db_host
DB_PORT=5432
DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASSWORD=your_db_password

# DigitalOcean Registry Access
DO_API_TOKEN=your_digitalocean_api_token
```

5. Run the application locally:

```bash
python app.py
# or using Docker
docker compose up
```

### 2. Infrastructure Setup with Terraform

1. Navigate to the infrastructure directory:

```bash
cd infrastructure
```

2. Create your Terraform variables file:

```bash
cp project.tfvars.example project.tfvars
```

3. Edit `project.tfvars` to configure your DigitalOcean setup:

```
do_token = "your_digitalocean_api_token"
ssh_fingerprint = "your_ssh_key_fingerprint"
droplet_size = "s-2vcpu-4gb"
droplet_count = 2
region = "nyc1"
```

4. Initialize Terraform:

```bash
terraform init
```

5. Preview the infrastructure changes:

```bash
terraform plan -var-file=project.tfvars -out=project.out
```

6. Apply the infrastructure changes:

```bash
terraform apply "project.out"
```

7. After successful application, Terraform will output information about the created resources, including the droplet IPs needed for deployment.

### 3. Docker Image Build and Push

1. Build the Docker image:

```bash
docker build -t registry.digitalocean.com/hivenetes-registry/multi-modal-agents:latest .
```

2. Log in to DigitalOcean Container Registry:

```bash
doctl auth init
doctl registry login
```

3. Push the image to the registry:

```bash
docker push registry.digitalocean.com/hivenetes-registry/multi-modal-agents:latest
```

### 4. Deployment to Servers

1. Make sure your SSH key is properly configured:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ai

# Add key to ssh-agent
ssh-add ~/.ssh/ai
```

2. Run the deployment script:

```bash
cd scripts
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
- Fetch server IPs from Terraform output
- Connect to each server via SSH
- Clean up existing Docker resources
- Copy the necessary configuration files (`.env` and `docker-compose.yml`)
- Log in to the DigitalOcean container registry
- Pull and start the application containers

## Monitoring and Management

After deployment, you can access your application at:

```
http://<server-ip>:7860
```

or

```
http://<server-ip>
```

To manage the running containers on a server:

```bash
ssh -i ~/.ssh/ai root@<server-ip>
cd /root/app
docker compose ps
docker compose logs
```

## Updating the Application

To update the application:

1. Make your code changes
2. Build and push a new Docker image
3. Run the deployment script again to update all servers

## Tearing Down Infrastructure

To remove all infrastructure when no longer needed:

```bash
cd infrastructure
terraform destroy -var-file=project.tfvars
```

## Technical Details

- **Speech Recognition**: Uses OpenAI's Whisper model via the Transformers library
- **Image Generation**: Uses Flux Schnell model via Replicate API
- **Image Captioning**: Uses BLIP model for generating image descriptions
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Cloud Storage**: DigitalOcean Spaces (S3-compatible)
- **Frontend**: Gradio Blocks interface
- **Infrastructure**: DigitalOcean Droplets managed by Terraform
- **Deployment**: Containerized application deployed using Docker and Shell scripts

## Error Handling

The application includes comprehensive error handling for:

- Audio recording/transcription issues
- Image generation failures
- Database connection problems
- Storage upload errors
- Deployment failures

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
