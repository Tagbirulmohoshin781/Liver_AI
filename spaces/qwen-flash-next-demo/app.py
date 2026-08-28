import os
from typing import Iterator
import gradio as gr
from huggingface_hub import InferenceClient

MODEL_ID = 'Qwen/Qwen3.8-Flash-Next'
HF_TOKEN = os.getenv('HF_TOKEN') or os.getenv('HUGGINGFACE_API_KEY') or ''
client = InferenceClient(model=MODEL_ID, token=HF_TOKEN if HF_TOKEN else None)
DEFAULT_SYSTEM_PROMPT = 'You are Qwen, a helpful, precise, and fast AI assistant created by Alibaba Cloud.'

def chat_stream(message, history, system_prompt, temperature, max_new_tokens, top_p):
    messages = []
    if system_prompt:
        messages.append({'role': 'system', 'content': system_prompt})
    for u, a in history:
        if u: messages.append({'role': 'user', 'content': u})
        if a: messages.append({'role': 'assistant', 'content': a})
    messages.append({'role': 'user', 'content': message})
    try:
        response = ''
        for chunk in client.chat_completion(messages=messages, max_tokens=max_new_tokens, temperature=temperature, top_p=top_p, stream=True):
            delta = chunk.choices[0].delta.content or ''
            response += delta
            yield response
    except Exception as e:
        yield f'Inference Notice: {str(e)}'

with gr.Blocks(theme=gr.themes.Soft(primary_hue='indigo')) as demo:
    gr.Markdown('# Qwen3.8-Flash-Next Demo\n### Low-Latency, High-Throughput Reasoning')
    with gr.Accordion('Parameters', open=False):
        sys_box = gr.Textbox(value=DEFAULT_SYSTEM_PROMPT, label='System Prompt')
        with gr.Row():
            temp_s = gr.Slider(0.0, 1.5, 0.7, label='Temperature')
            tokens_s = gr.Slider(64, 4096, 1024, label='Max Tokens')
            top_p_s = gr.Slider(0.1, 1.0, 0.9, label='Top-p')
    cb = gr.Chatbot(height=520)
    gr.ChatInterface(fn=chat_stream, chatbot=cb, additional_inputs=[sys_box, temp_s, tokens_s, top_p_s])

if __name__ == '__main__':
    demo.launch(mcp_server=True)
