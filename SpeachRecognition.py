# example.py
from dotenv import load_dotenv
from io import BytesIO
import requests
from elevenlabs.client import ElevenLabs
import os
load_dotenv()
api_key = os.getenv('GEMINI_API_KEY')
elevenlabs = ElevenLabs(api_key="sk_c7b33b317062074638a0e74aee73a6a72c7432da0da0b075")


def speechToText(audioSource):
    audioData = open(audioSource, "rb")

    transcription = elevenlabs.speech_to_text.convert(
        file=audioData,
        model_id="scribe_v2",
    )
    return transcription.text


print(speechToText('nicole.mp3'))
