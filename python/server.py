import asyncio
import json
import websockets
import vosk

# Set up the Vosk model and recognizer
model = vosk.Model(lang="en-us")
rec = vosk.KaldiRecognizer(model, 16000)


# Define the WebSocket server handler function
async def audio_websocket(websocket, path):
    print("WebSocket connection established.")
    audio_data = None
    while True:
        # Receive audio data from the client
        try:
            audio_data = await websocket.recv()

            # Parse the audio data and feed it into the Vosk recognizer
            if audio_data:
                if rec.AcceptWaveform(audio_data):
                    result = json.loads(rec.Result())["text"]
                    if result != "":
                        await websocket.send(result)
            else:
                break

        except websockets.WebSocketException:
            print("WebSocket connection closed.")
            break


# Start the WebSocket server
start_server = websockets.serve(audio_websocket, "192.168.100.43", 5000)

print("WebSocket server started.")


def run():
    try:
        asyncio.get_event_loop().run_until_complete(start_server)
        asyncio.get_event_loop().run_forever()
    except KeyboardInterrupt:
        print("WebSocket server stopped.")
    except Exception:
        print("WebSocket server stopped with exception")


if __name__ == "__main__":
    run()
