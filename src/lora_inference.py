"""
src/lora_inference.py
======================
Inference module for fine-tuned LoRA model (microsoft/Phi-3-mini-4k-instruct + models/liver-lora).

Features:
  - Loads base model and LoRA adapter weights from models/liver-lora/
  - Supports CPU and CUDA hardware backends
  - Generates responses with system context and prompt templates
  - Provides a CLI interface for rapid testing
"""

import os
import sys
try:
    import torch
    HAS_TORCH = True
except ImportError:
    torch = None
    HAS_TORCH = False
from typing import Optional, Dict, Any

# Path settings
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LORA_MODEL_PATH = os.path.join(BASE_DIR, "models", "liver-lora")
DEFAULT_BASE_MODEL = "microsoft/Phi-3-mini-4k-instruct"


class LiverLoraModel:
    """Wrapper class for Phi-3 + Liver LoRA model loading and generation."""

    def __init__(self, adapter_path: str = LORA_MODEL_PATH, base_model_name: str = DEFAULT_BASE_MODEL):
        self.adapter_path = adapter_path
        self.base_model_name = base_model_name
        self.tokenizer = None
        self.model = None
        self.device = "cuda" if (HAS_TORCH and torch and torch.cuda.is_available()) else "cpu"
        self._is_loaded = False

    def load_model(self):
        """Loads base model and attaches the fine-tuned LoRA adapter."""
        if self._is_loaded:
            return

        print(f"[LiverLora] Loading tokenizer from {self.adapter_path} (or fallback {self.base_model_name})...")
        from transformers import AutoTokenizer, AutoModelForCausalLM
        from peft import PeftModel

        try:
            self.tokenizer = AutoTokenizer.from_pretrained(self.adapter_path, trust_remote_code=True)
        except Exception:
            self.tokenizer = AutoTokenizer.from_pretrained(self.base_model_name, trust_remote_code=True)

        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token

        print(f"[LiverLora] Loading base model '{self.base_model_name}' on device '{self.device}'...")
        torch_dtype = torch.float16 if torch.cuda.is_available() else torch.float32

        base_model = AutoModelForCausalLM.from_pretrained(
            self.base_model_name,
            torch_dtype=torch_dtype,
            device_map="auto" if torch.cuda.is_available() else None,
            trust_remote_code=True,
        )

        print(f"[LiverLora] Applying LoRA adapter from {self.adapter_path}...")
        self.model = PeftModel.from_pretrained(base_model, self.adapter_path)
        if not torch.cuda.is_available():
            self.model.to(self.device)
        self.model.eval()

        self._is_loaded = True
        print("[LiverLora] Model loaded and ready for inference ✓")

    def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        context: Optional[str] = None,
        max_new_tokens: int = 512,
        temperature: float = 0.7,
        top_p: float = 0.9,
    ) -> str:
        """Generates answer using the fine-tuned LoRA model."""
        if not self._is_loaded:
            self.load_model()

        messages = []
        if system_prompt:
            sys_content = system_prompt
            if context:
                sys_content += f"\n\nContext:\n{context}"
            messages.append({"role": "system", "content": sys_content})
        elif context:
            messages.append({"role": "system", "content": f"Use the following context to answer the user request:\n{context}"})

        messages.append({"role": "user", "content": prompt})

        if hasattr(self.tokenizer, "apply_chat_template"):
            formatted_prompt = self.tokenizer.apply_chat_template(
                messages, tokenize=False, add_generation_prompt=True
            )
        else:
            formatted_prompt = f"<|user|>\n{prompt}<|end|>\n<|assistant|>\n"

        inputs = self.tokenizer(formatted_prompt, return_tensors="pt").to(self.device)

        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                temperature=temperature,
                top_p=top_p,
                do_sample=temperature > 0.0,
                pad_token_id=self.tokenizer.pad_token_id,
                eos_token_id=self.tokenizer.eos_token_id,
            )

        input_len = inputs["input_ids"].shape[1]
        generated_tokens = outputs[0][input_len:]
        response = self.tokenizer.decode(generated_tokens, skip_special_tokens=True)
        return response.strip()


def is_lora_available() -> bool:
    """Check whether fine-tuned LoRA adapter files exist on disk."""
    adapter_cfg = os.path.join(LORA_MODEL_PATH, "adapter_config.json")
    return os.path.exists(adapter_cfg)


# Global singleton instance
_lora_instance: Optional[LiverLoraModel] = None


def get_lora_model() -> LiverLoraModel:
    global _lora_instance
    if _lora_instance is None:
        _lora_instance = LiverLoraModel()
    return _lora_instance


def generate_lora_answer(
    prompt: str,
    context: str = "",
    system_prompt: str = ""
) -> str:
    """High-level entry point for calling Liver LoRA inference."""
    if not is_lora_available():
        print(f"[LiverLora Warning] Adapter directory {LORA_MODEL_PATH} not found.")
        return ""
    try:
        model = get_lora_model()
        return model.generate(prompt=prompt, system_prompt=system_prompt, context=context)
    except Exception as exc:
        print(f"[LiverLora Error] Inference failed: {exc}")
        return ""


if __name__ == "__main__":
    print("Testing Liver LoRA Inference Module...")
    test_question = "What are the early symptoms of liver cirrhosis?"
    print(f"Question: {test_question}")
    try:
        model = get_lora_model()
        model.load_model()
        answer = model.generate(test_question)
        print("\nGenerated Response:")
        print(answer)
    except Exception as exc:
        print(f"Error during LoRA inference test: {exc}")
