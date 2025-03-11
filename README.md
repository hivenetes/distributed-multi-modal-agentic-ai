# Audio to Image Generator with Description

This application converts spoken descriptions into AI-generated images with automatic captions. It uses state-of-the-art AI models for speech recognition, image generation, and image captioning, while storing the results in both a PostgreSQL database and DigitalOcean Spaces.

## Features

- 🎤 **Speech-to-Text**: Uses OpenAI's Whisper model for accurate speech recognition
- 🎨 **Image Generation**: Generates images from text using Flux Schnell model
- 📝 **Image Captioning**: Automatically generates image descriptions using BLIP model
- 🗄️ **Storage Solutions**: 
  - Images stored in DigitalOcean Spaces
  - Metadata stored in PostgreSQL database
- 🌐 **Modern UI**: Built with Gradio for a clean, user-friendly interface

## Prerequisites

- Python 3.8+
- PostgreSQL database
- DigitalOcean Spaces account
- Replicate API key

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd gen-img-desc
```

2. Install required packages:
```bash
pip install -r requirements.txt
```

3. Copy `.env.example` and create a `.env` file in the project root with the following variables:
```env
# Database Configuration
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_HOST=your_db_host
DB_PORT=5432
DB_NAME=your_db_name

# DigitalOcean Spaces Configuration
SPACES_KEY=your_spaces_key
SPACES_SECRET=your_spaces_secret
SPACES_REGION=your_spaces_region
SPACES_ENDPOINT=your_spaces_endpoint
SPACES_BUCKET=your_bucket_name

# Replicate API Configuration
REPLICATE_API_TOKEN=your_replicate_api_token
```

## Project Structure

```
gen-img-desc/
├── app.py              # Main application file
├── db_config.py        # Database configuration and models
├── spaces.py           # DigitalOcean Spaces utilities
├── requirements.txt    # Project dependencies
├── images/            # Local image storage
└── README.md          # This file
```

## Usage

1. Start the application:
```bash
python app.py
```

2. Open your web browser and navigate to the provided URL (typically http://localhost:7860)

3. Use the interface to:
   - Record audio describing the image you want to generate
   - Click "Submit" to transcribe the audio
   - Click "Generate Image" to create the image
   - Click "Generate Caption" to get an AI-generated description
   - Click "Store Image and Caption" to save everything to the database and cloud storage

## Technical Details

- **Speech Recognition**: Uses OpenAI's Whisper model via the Transformers library
- **Image Generation**: Uses Flux Schnell model via Replicate API
- **Image Captioning**: Uses BLIP model for generating image descriptions
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Cloud Storage**: DigitalOcean Spaces (S3-compatible)
- **Frontend**: Gradio Blocks interface

## Database Schema

The `image_records` table stores:
- `id`: Primary key
- `prompt`: Original text prompt
- `image_filename`: Name of the stored image file
- `description`: AI-generated image caption
- `created_at`: Timestamp of record creation

## Error Handling

The application includes comprehensive error handling for:
- Audio recording/transcription issues
- Image generation failures
- Database connection problems
- Storage upload errors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE) 