import os
from typing import Iterator, List, Dict, Any, Tuple
import gradio as gr
from huggingface_hub import InferenceClient

MODEL_ID = "Qwen/Qwen2.5-7B-Instruct"

# Initialize Inference Client (supports free HF serverless inference & custom tokens)
HF_TOKEN = os.getenv("HF_TOKEN") or os.getenv("HUGGINGFACE_API_KEY") or None
client = InferenceClient(model=MODEL_ID, token=HF_TOKEN)

PERSONAS = {
    "🧠 General Assistant": "You are Qwen2.5, a helpful, precise, polite, and honest AI assistant developed by Alibaba Cloud.",
    "💻 Software Engineer": "You are an expert full-stack software engineer and system architect. Provide clean, secure, idiomatic, and highly maintainable code with clear technical rationale.",
    "🔬 Clinical & Biomedical Analyst": "You are a clinical AI specialist and biomedical informatics researcher. Provide structured, evidence-grounded medical analysis citing AASLD, EASL, and WHO guidelines where applicable with strict clinical disclaimers.",
    "📐 Mathematics & Logic Tutor": "You are a mathematical reasoning tutor. Break down problems step-by-step using clear logical deductions, formulas in LaTeX notation, and intermediate proofs.",
    "✍️ Technical Writer": "You are a senior technical writer and editor. Craft concise, high-signal, engaging prose free of fluff or generic clichés."
}

def update_persona(persona_name: str) -> str:
    """Returns the default system prompt corresponding to the selected persona."""
    return PERSONAS.get(persona_name, PERSONAS["🧠 General Assistant"])

def chat_stream(
    message: str,
    history: List[Tuple[str, str]],
    system_prompt: str,
    temperature: float,
    max_new_tokens: int,
    top_p: float
) -> Iterator[str]:
    """
    Streams conversational reasoning responses from Qwen2.5-7B-Instruct.
    
    Args:
        message: The user's input message.
        history: Previous conversation turns as (user_msg, assistant_msg) tuples.
        system_prompt: Guiding system instruction.
        temperature: Sampling temperature (higher = more creative, lower = more deterministic).
        max_new_tokens: Maximum tokens to generate.
        top_p: Nucleus sampling threshold.
        
    Yields:
        Accumulated text stream from the model.
    """
    messages: List[Dict[str, str]] = []
    
    if system_prompt and system_prompt.strip():
        messages.append({"role": "system", "content": system_prompt.strip()})
        
    for user_msg, assistant_msg in history:
        if user_msg:
            messages.append({"role": "user", "content": user_msg})
        if assistant_msg:
            messages.append({"role": "assistant", "content": assistant_msg})
            
    messages.append({"role": "user", "content": message})
    
    try:
        accumulated_text = ""
        for chunk in client.chat_completion(
            messages=messages,
            max_tokens=int(max_new_tokens),
            temperature=float(temperature),
            top_p=float(top_p),
            stream=True
        ):
            delta = chunk.choices[0].delta.content or ""
            accumulated_text += delta
            yield accumulated_text
    except Exception as e:
        err_msg = str(e)
        if "Authorization" in err_msg or "token" in err_msg.lower():
            yield (
                "⚠️ **Authentication Note**: Hugging Face serverless rate limits reached. "
                "Please configure an `HF_TOKEN` secret in your Space settings for unlimited high-speed inference.\n\n"
                f"*Details: {err_msg}*"
            )
        else:
            yield f"⚠️ **Inference Notice**: {err_msg}"


# --- UI Construction ---

custom_css = """
#main-container { max-width: 1100px; margin: 0 auto; }
.chatbot-container { border-radius: 12px; }
"""

with gr.Blocks(
    title="Qwen2.5-7B-Instruct Studio",
    theme=gr.themes.Soft(primary_hue="indigo", secondary_hue="purple"),
    css=custom_css
) as demo:
    
    with gr.Column(elem_id="main-container"):
        gr.Markdown(
            """
            # 🤖 Qwen2.5-7B-Instruct Interactive Studio
            ### High-Efficiency Reasoning, Code Synthesis, and Multilingual Chat
            
            Powered by **[Qwen/Qwen2.5-7B-Instruct](https://huggingface.co/Qwen/Qwen2.5-7B-Instruct)** by Alibaba Cloud.
            """
        )
        
        with gr.Accordion("⚙️ Persona & Generation Parameters", open=False):
            with gr.Row():
                persona_dropdown = gr.Dropdown(
                    choices=list(PERSONAS.keys()),
                    value="🧠 General Assistant",
                    label="Preset Persona",
                    scale=1
                )
                system_box = gr.Textbox(
                    value=PERSONAS["🧠 General Assistant"],
                    label="System Instructions",
                    lines=2,
                    scale=2
                )
            
            with gr.Row():
                temp_slider = gr.Slider(
                    minimum=0.0,
                    maximum=1.5,
                    value=0.7,
                    step=0.05,
                    label="Temperature"
                )
                tokens_slider = gr.Slider(
                    minimum=128,
                    maximum=4096,
                    value=1536,
                    step=128,
                    label="Max New Tokens"
                )
                top_p_slider = gr.Slider(
                    minimum=0.05,
                    maximum=1.0,
                    value=0.9,
                    step=0.05,
                    label="Top-P"
                )
                
            persona_dropdown.change(
                fn=update_persona,
                inputs=[persona_dropdown],
                outputs=[system_box]
            )

        chatbot_widget = gr.Chatbot(
            height=540,
            show_copy_button=True,
            render_markdown=True,
            elem_classes=["chatbot-container"]
        )
        
        chat_interface = gr.ChatInterface(
            fn=chat_stream,
            chatbot=chatbot_widget,
            additional_inputs=[system_box, temp_slider, tokens_slider, top_p_slider],
            examples=[
                ["Write a clean Python script using asyncio to concurrently fetch multiple URLs with exponential backoff retry."],
                ["Explain the pathophysiological differences between MASLD (steatosis) and MASH (steatohepatitis)."],
                ["Solve this math problem step-by-step: If $f(x) = x^3 - 3x + 2$, find the local extrema and inflection points."],
                ["Translate and explain the meaning of this sentence in French, German, and Japanese: 'Consistency is the foundation of mastery.'"]
            ],
            cache_examples=False
        )

        gr.Markdown(
            """
            ---
            💡 **Model Reference**: [Qwen/Qwen2.5-7B-Instruct](https://huggingface.co/Qwen/Qwen2.5-7B-Instruct) | Built with Gradio & ready for Hugging Face Spaces.
            """
        )

if __name__ == "__main__":
    demo.launch(mcp_server=True)
