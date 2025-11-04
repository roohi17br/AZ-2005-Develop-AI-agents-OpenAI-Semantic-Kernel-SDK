import os
from flask import Flask, request, jsonify
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

app = Flask(__name__)

# Initialize Semantic Kernel
kernel = Kernel()
kernel.add_service(
    AzureChatCompletion(
        deployment_name=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"),
        endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        api_key=os.getenv("AZURE_OPENAI_API_KEY")
    )
)

@app.route('/chat', methods=['POST'])
async def chat():
    data = request.json
    message = data.get('message')
    
    chat_service = kernel.get_service(type=AzureChatCompletion)
    response = await chat_service.get_chat_message_content(message)
    
    return jsonify({'response': str(response)})

@app.route('/', methods=['GET'])
def health():
    return jsonify({
        'message': 'Python Chat application is running. POST to /chat with a message to interact.',
        'example': 'POST /chat { "message": "Hello!" }'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
