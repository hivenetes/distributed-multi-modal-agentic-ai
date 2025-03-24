import gradio as gr
from dotenv import load_dotenv
import os
import replicate
import requests
import os 
import boto3
from db_config import SessionLocal, ImageRecord
import soundfile as sf
import tempfile
from openai import OpenAI
from fastapi import FastAPI
from fastapi.responses import FileResponse
import pathlib

load_dotenv()

# Create FastAPI app
app = FastAPI()

# Create the architecture diagram route
@app.get("/arch")
async def get_architecture():
    arch_path = "assets/architecture.png"  # Use existing file directly
    if os.path.exists(arch_path):
        return FileResponse(arch_path)
    else:
        return {"error": "Architecture diagram not found"}

def save_audio(audio):
    if audio is None:
        gr.Warning('No audio provided. Please record audio and try again.')
        return None
    
    try:        
        # Create a temporary file to store the audio
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            temp_path = temp_file.name
            sr, y = audio
            
            # Convert to mono if stereo
            if y.ndim > 1:
                y = y.mean(axis=1)
            
            # Save the audio to temporary file
            sf.write(temp_path, y, sr)
            
            transcribed_text = transcribe(temp_path)
            return temp_path, transcribed_text
            
    except Exception as e:
        gr.Warning(f'Error saving audio: {str(e)}')
        return "None", "None"

def transcribe(audio_file_path):    
    if audio_file_path is None:
        gr.Warning('No audio provided. Please record audio and try again.')
    else:
        try:
            client = OpenAI()

            audio_file= open(audio_file_path, "rb")
            transcription = client.audio.transcriptions.create(
                model="whisper-1", 
                file=audio_file
            )

            return transcription.text
        except Exception as e:
            gr.Warning(f'Error in transcription: {str(e)}')
            print(f'Error in transcription: {str(e)}')
            return ""

def generate_image(text_prompt):    
    if text_prompt is None or text_prompt.strip() == "":
        gr.Warning('No text prompt provided. Please record audio and try again.')
        return None, None, None
    else:
        try:
            output = replicate.run(
                "black-forest-labs/flux-schnell",
                input={
                    "prompt": text_prompt,
                    "go_fast": True,
                    "megapixels": "1",
                    "num_outputs": 1,
                    "aspect_ratio": "1:1",
                    "output_format": "webp",
                    "output_quality": 80,
                    "num_inference_steps": 4
                }
            )

            replicate_image_url = str(output[0])

            # Generate image caption
            caption, image_file_name = generate_image_caption(text_prompt, replicate_image_url)

            #save details
            save_details(replicate_image_url, image_file_name, text_prompt, caption)

            return replicate_image_url, caption, replicate_image_url

        except Exception as e:
            print(f"Error in image generation: {str(e)}")  # Debug print
            return None, None, None

def generate_image_caption(text_prompt, replicate_image_url):    
    if text_prompt is None or replicate_image_url is None:
        gr.Warning('No text prompt or image URL provided. Please record audio and try again.')
    else:
        try:
            image_file_name = text_prompt.strip().replace(" ", "_").replace(".", "")
            image_file_name = image_file_name + ".jpg"

            output = replicate.run(
                "salesforce/blip:2e1dddc8621f72155f24cf2e0adbde548458d3cab9f00c0139eea840d0ac4746",
                input={
                    "task": "image_captioning",
                    "image": replicate_image_url
                }
            )
            caption = output.replace("Caption:", "").strip()
            return caption, image_file_name
        except Exception as e:
            return f"Error in caption generation: {str(e)}", ""

def store_image_in_spaces(image_url, image_file_name):
    if image_url is None or image_file_name is None:
        gr.Warning('No image URL or image file name provided. Please generate image and try again.')
    else:   
        try:
            session = boto3.session.Session()
            client = session.client('s3',
                        region_name=os.getenv('SPACES_REGION'),
                        endpoint_url=os.getenv('SPACES_ENDPOINT'),
                        aws_access_key_id=os.getenv('SPACES_KEY'),
                        aws_secret_access_key=os.getenv('SPACES_SECRET'))
            
            # Download the image
            response = requests.get(image_url)
            response.raise_for_status()  # Raise an error for bad responses

            # Save the image to a temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
                temp_file.write(response.content)
                temp_path = temp_file.name

            # Upload the temporary file to Spaces
            client.upload_file(temp_path, os.getenv('SPACES_BUCKET'), image_file_name)

            # Clean up the temporary file
            os.unlink(temp_path)

            return "Image stored successfully in Spaces"
        except Exception as e:
            return f"Error in storing image in spaces: {str(e)}"

def store_image_record_in_database(text_prompt, image_filename, description):
    try:
        # Create a new database session
        db = SessionLocal()
        
        try:
            # Create new image record
            db_record = ImageRecord(
                prompt=text_prompt,
                image_filename=image_filename,
                description=description
            )
            
            # Add and commit the record
            db.add(db_record)
            db.commit()
            db.refresh(db_record)
            
            return f"Image record stored successfully with ID: {db_record.id}"
        except Exception as e:
            # Rollback in case of error
            db.rollback()
            raise e
        finally:
            # Always close the session
            db.close()
    except Exception as e:
        return f"Error in database operation: {str(e)}"
    
def save_details(image_url, image_file_name, text_prompt, caption):
    if image_url is None or image_file_name is None or text_prompt is None or caption is None:
        gr.Warning('Please generate image and try again.')
    else:
        try:
            store_image_in_spaces(image_url, image_file_name)
            store_image_record_in_database(text_prompt, image_file_name, caption)
            return "Details saved successfully"
        except Exception as e:
            return f"Error in saving details: {str(e)}"

with gr.Blocks(
    title="Hivenetes",
    analytics_enabled=False,
    css="""
        .gradio-container {max-width: 100% !important} 
        .footer {display: none !important} 
        footer {display: none !important}
        #custom-footer {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            text-align: center;
            padding: 20px;
            background-color: black;
        }
        .primary-btn {
            background-color: #2196F3 !important;
        }
        button.primary-btn:hover {
            background-color: #1976D2 !important;
        }
    """
) as demo:
    gr.Markdown(
        """
        # Hivenetes: Distributed Multi-Modal Agentic AI Framework
        Breaking Conversational Barriers since 2025
        """
    )
    
    with gr.Row():
        with gr.Column(scale=1):
            audio_input = gr.Microphone(label="Record Audio")
            audio_file_path = gr.Textbox(label="Audio File Name", lines=1, visible=False)
        
        with gr.Column(scale=2):
            with gr.Group():
                transcribed_text = gr.Textbox(label="Transcribed Text", lines=1)
    
    with gr.Row():
        with gr.Column(scale=1):
            invisible_replicate_image_url = gr.Textbox(label="Invisible Text", lines=1, visible=False)

    with gr.Row():
        with gr.Column(scale=1):
            generate_image_btn = gr.Button("Generate Image", elem_classes="primary-btn")
                
    with gr.Row():
        with gr.Column(scale=2):
            image_output = gr.Image(label="Generated Image", type="filepath")

    with gr.Row():    
        with gr.Column(scale=2):
            caption_output = gr.Textbox(label="Image Caption", lines=2)
            invisible_image_file_name = gr.Textbox(label="Invisible Text", lines=1, visible=False)
    
    # Add footer with an id
    gr.Markdown(
        """
        <div id="custom-footer">
            Built with ❤️ by Abhi (dabhey.com) & Narsi
        </div>
        """
    )

    audio_input.change(
        fn=save_audio,
        inputs=[audio_input],
        outputs=[audio_file_path, transcribed_text]
    )

    generate_image_btn.click(
        fn=generate_image,
        inputs=[transcribed_text],
        outputs=[image_output, caption_output, invisible_replicate_image_url]
    )

if __name__ == "__main__":
    # Mount Gradio app to FastAPI
    app = gr.mount_gradio_app(app, demo, path="/")
    
    # Run the FastAPI app
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7860) 