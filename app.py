import gradio as gr
from dotenv import load_dotenv
import os
import torch
import numpy as np
from transformers import pipeline
import replicate
from transformers import BlipProcessor, BlipForConditionalGeneration
from PIL import Image
import requests
from io import BytesIO
import os
import boto3
from db_config import SessionLocal, ImageRecord

load_dotenv()

# Get the API token from the environment variable
api_token = os.getenv("REPLICATE_API_TOKEN")
device = "cuda:0" if torch.cuda.is_available() else "cpu"
torch_dtype = torch.float16 if torch.cuda.is_available() else torch.float32
device_idx = 0 if torch.cuda.is_available() else -1

transcriber = pipeline("automatic-speech-recognition", model="openai/whisper-large-v3-turbo")

def transcribe(audio):    
    if audio is None:
        gr.Warning('No audio provided. Please record audio and try again.')
    else:
        try:
            sr, y = audio
            
            # Convert to mono if stereo
            if y.ndim > 1:
                y = y.mean(axis=1)
                
            y = y.astype(np.float32)
            y /= np.max(np.abs(y))

            # Force English language and transcription task
            transcript = transcriber({"sampling_rate": sr, "raw": y})["text"]  
            return transcript
        except Exception as e:
            gr.Warning(f'Error in transcription: {str(e)}')
            return ""

def generate_image(text_prompt):
    
    if text_prompt is None:
        gr.Warning('No text prompt provided. Please record audio and try again.')
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

            return str(output[0]), str(output[0])
        except Exception as e:
            return f"Error in image generation: {str(e)}", ""

def generate_image_caption(text_prompt, replicate_image_url):    
    if text_prompt is None or replicate_image_url is None:
        gr.Warning('No text prompt or image URL provided. Please record audio and try again.')
    else:
        try:
            # Create images directory if it doesn't exist
            if not os.path.exists('images'):
                os.makedirs('images')
                
            # Download the image from URL
            response = requests.get(replicate_image_url)
            if response.status_code != 200:
                raise Exception(f"Failed to download image: HTTP {response.status_code}")
            
            # Open the image from bytes
            image = Image.open(BytesIO(response.content))
            image_file_name = text_prompt.strip().replace(" ", "_").replace(".", "")
            image_file_name = image_file_name + ".jpg"
            image.save(f"images/{image_file_name}")
            
            # Convert to RGB if necessary
            if image.mode != "RGB":
                image = image.convert("RGB")
            
            processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
            model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")
            
            # Generate caption
            inputs = processor(image, return_tensors="pt")
            out = model.generate(**inputs)
            caption = processor.decode(out[0], skip_special_tokens=True)
            return caption, image_file_name
        except Exception as e:
            return f"Error in caption generation: {str(e)}", ""

def store_image_in_spaces(image_url, image_file_name):
    
    print(image_url)
    print(image_file_name)
    
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
            response = client.upload_file(image_url, os.getenv('SPACES_BUCKET'), image_file_name)
            return response
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

with gr.Blocks(title="Audio to Image Generator with Description") as demo:
    gr.Markdown(
        """
        # Audio to Image Generator with Description
        Record audio to generate an image and get its description. The image will be stored in Digital Ocean Spaces.
        """
    )
    
    with gr.Row():
        with gr.Column(scale=1):
            audio_input = gr.Microphone(label="Record Audio")
            submit_btn = gr.Button("Submit", variant="primary")
        
        with gr.Column(scale=2):
            with gr.Group():
                transcribed_text = gr.Textbox(label="Transcribed Text", lines=1)
    
    with gr.Row():
        with gr.Column(scale=1):
            invisible_replicate_image_url = gr.Textbox(label="Invisible Text", lines=1, visible=False)

    with gr.Row():
        with gr.Column(scale=1):
            generate_image_btn = gr.Button("Generate Image", variant="primary")
        with gr.Column(scale=2):
            image_output = gr.Image(label="Generated Image", type="filepath")
            
    with gr.Row():
        with gr.Column(scale=1):
            generate_caption_btn = gr.Button("Generate Caption", variant="primary")
        with gr.Column(scale=2):
            caption_output = gr.Textbox(label="Image Caption", lines=2)
            invisible_image_file_name = gr.Textbox(label="Invisible Text", lines=1, visible=False)
    
    with gr.Row():
        with gr.Column(scale=2):
            store_image_btn = gr.Button("Save Image and Caption", variant="primary")

    # Connect the components
    submit_btn.click(
        fn=transcribe,
        inputs=[audio_input],
        outputs=[transcribed_text]
    )

    generate_image_btn.click(
        fn=generate_image,
        inputs=[transcribed_text],
        outputs=[image_output, invisible_replicate_image_url]
    )

    generate_caption_btn.click(
        fn=generate_image_caption,
        inputs=[transcribed_text, invisible_replicate_image_url],
        outputs=[caption_output, invisible_image_file_name]
    )

    store_image_btn.click(
        fn=save_details,
        inputs=[image_output, invisible_image_file_name, transcribed_text, caption_output],
        outputs=[store_image_btn]
    )

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",  # Critical for Docker - allows external connections
        server_port=7860,       # Specify the port explicitly
        share=False,            # Don't create a public URL
        debug=True             # Show detailed errors
    ) 