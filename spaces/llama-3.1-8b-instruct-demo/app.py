import os
import gradio as gr
from huggingface_hub import InferenceClient

MODEL_ID = "meta-llama/Llama-3.1-8B-Instruct"
HF_TOKEN = os.environ.get("HF_TOKEN") or os.environ.get("HUGGING_FACE_HUB_TOKEN")

client = InferenceClient(model=MODEL_ID, token=HF_TOKEN)

SYSTEM_PERSONAS = {
    "General Assistant": (
        "You are a helpful, respectful, and precise AI assistant powered by Meta Llama 3.1."
    ),
    "Clinical Research Specialist": (
        "You are an expert Clinical Hepatologist and Medical AI Specialist. "
        "Provide evidence-based, mechanistically sound answers grounded in international guidelines (AASLD, EASL)."
    ),
    "Principal Software Architect": (
        "You are a Principal Software Engineer and Systems Architect. "
        "Deliver clean, production-ready code with exhaustive error handling and architectural patterns."
    ),
}

def predict(message, history, persona, custom_system, max_tokens, temperature, top_p):
    system_prompt = custom_system if (custom_system and custom_system.strip()) else SYSTEM_PERSONAS.get(persona, "")
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    
    if history:
        for item in history:
            if isinstance(item, dict):
                messages.append(item)
            elif isinstance(item, (list, tuple)) and len(item) == 2:
                u_msg, a_msg = item
                if u_msg:
                    messages.append({"role": "user", "content": u_msg})
                if a_msg:
                    messages.append({"role": "assistant", "content": a_msg})
                
    messages.append({"role": "user", "content": message})

    response = ""
    try:
        stream = client.chat_completion(
            messages=messages,
            max_tokens=int(max_tokens),
            stream=True,
            temperature=float(temperature),
            top_p=float(top_p),
        )
        for chunk in stream:
            token = chunk.choices[0].delta.content or ""
            response += token
            yield response
    except Exception as e:
        err = str(e)
        if "401" in err or "403" in err or "gated" in err.lower():
            yield (
                f"⚠️ **Access Restricted**: `{MODEL_ID}` is a gated repository.\n\n"
                "1. Accept the terms on the [Llama-3.1-8B-Instruct Model Card](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct).\n"
                "2. Ensure your Hugging Face Token is configured under **Space Settings > Variables and secrets** as `HF_TOKEN`."
            )
        else:
            yield f"⚠️ **Inference Notice**: {err}"

with gr.Blocks(
    title="Meta Llama 3.1 8B Instruct Studio",
    theme=gr.themes.Soft(primary_hue="indigo", secondary_hue="purple")
) as demo:
    gr.Markdown(
        f"# 🦙 Meta Llama 3.1 8B Instruct Studio\n"
        f"Interactive streaming reasoning and conversational interface powered by **[{MODEL_ID}](https://huggingface.co/{MODEL_ID})**."
    )
    
    with gr.Accordion("⚙️ Persona & Generation Parameters", open=False):
        with gr.Row():
            persona_dropdown = gr.Dropdown(
                choices=list(SYSTEM_PERSONAS.keys()),
                value="General Assistant",
                label="System Persona",
                scale=1
            )
            custom_system_box = gr.Textbox(
                label="Custom System Prompt Override",
                placeholder="Leave empty to use persona default...",
                lines=2,
                scale=2
            )
        with gr.Row():
            max_tokens_slider = gr.Slider(64, 4096, value=1024, step=64, label="Max Tokens")
            temp_slider = gr.Slider(0.0, 1.5, value=0.7, step=0.05, label="Temperature")
            top_p_slider = gr.Slider(0.1, 1.0, value=0.9, step=0.05, label="Top-P")

    gr.ChatInterface(
        fn=predict,
        additional_inputs=[persona_dropdown, custom_system_box, max_tokens_slider, temp_slider, top_p_slider],
        examples=[
            ["Deep analysis of MASLD progression in patients with elevated ALT and HbA1c"],
            ["Write a Python script for two-stage BM25 semantic retrieval and reranking."],
            ["Explain the De Ritis ratio (AST:ALT) diagnostic thresholds in hepatology."],
        ],
        cache_examples=False
    )

if __name__ == "__main__":
    demo.launch(mcp_server=True)
