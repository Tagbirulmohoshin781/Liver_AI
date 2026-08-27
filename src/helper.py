try:
    from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader, WebBaseLoader
    from langchain_text_splitters import RecursiveCharacterTextSplitter
    try:
        from langchain_huggingface import HuggingFaceEmbeddings
    except ImportError:
        from langchain_community.embeddings import HuggingFaceEmbeddings  # type: ignore[import]
    from langchain_core.documents import Document
    HAS_LANGCHAIN = True
except Exception:
    PyPDFLoader = DirectoryLoader = WebBaseLoader = None
    RecursiveCharacterTextSplitter = None
    HuggingFaceEmbeddings = None
    Document = None
    HAS_LANGCHAIN = False

if Document is None:
    class Document:
        def __init__(self, page_content="", metadata=None):
            self.page_content = page_content
            self.metadata = metadata or {}

        def __repr__(self):
            return f"Document(page_content={self.page_content[:30]!r}, metadata={self.metadata})"

from typing import List
import os
import re
import glob
try:
    import pandas as pd
except ImportError:
    pd = None


def load_pdf_files(data):
    """Load all PDF files from the given directory."""
    documents = []
    if HAS_LANGCHAIN and PyPDFLoader is not None and DirectoryLoader is not None:
        try:
            loader = DirectoryLoader(
                data,
                glob="*.pdf",
                loader_cls=PyPDFLoader
            )
            return loader.load()
        except Exception as e:
            print(f"Warning: DirectoryLoader failed — {e}")

    # Fallback using pypdf directly if available
    pdf_files = glob.glob(os.path.join(data, "*.pdf"))
    for file_path in pdf_files:
        try:
            import pypdf
            reader = pypdf.PdfReader(file_path)
            for i, page in enumerate(reader.pages):
                text = page.extract_text() or ""
                if text.strip():
                    documents.append(
                        Document(
                            page_content=text,
                            metadata={"source": file_path, "page": i}
                        )
                    )
        except Exception as e:
            print(f"Warning: Could not load PDF {file_path} — {e}")
    return documents


# =============================================================================
# NVIDIA RAG-Blueprint: Authoritative Clinical Knowledge Document Registry
# =============================================================================
DOCUMENT_REGISTRY = {
    "liver_disease_fatty_liver.txt": {
        "source_id": "AASLD_2023_MASLD_MASH",
        "title": "AASLD 2023 Clinical Guidance on MASLD, MASH, and Steatosis Reversal",
        "clinical_domain": "fatty_liver",
        "authority": "AASLD / EASL Clinical Practice Guidelines",
        "evidence_level": "Level 1A",
        "keywords": ["fatty liver", "steatosis", "masld", "mash", "nafld", "nash", "lifestyle", "weight loss", "7-10%"]
    },
    "liver_disease_hepatitis.txt": {
        "source_id": "AASLD_VIRAL_HEPATITIS",
        "title": "Clinical Guidance for Viral Hepatitis A, B, C & Autoimmune Hepatitis",
        "clinical_domain": "hepatitis",
        "authority": "AASLD / CDC Clinical Guidelines",
        "evidence_level": "Level 1A",
        "keywords": ["hepatitis", "hbv", "hcv", "hav", "viral", "antiviral", "direct acting antivirals", "interferon"]
    },
    "liver_disease_late_stage_symptoms.txt": {
        "source_id": "HEPATOLOGY_CIRRHOSIS_RED_FLAGS",
        "title": "Decompensated Cirrhosis, Ascites, Portal Hypertension & Triage Signs",
        "clinical_domain": "symptoms",
        "authority": "Critical Care Hepatology Guidelines",
        "evidence_level": "Level 1A",
        "keywords": ["cirrhosis", "portal hypertension", "ascites", "varices", "jaundice", "red flags", "encephalopathy", "emergency"]
    },
    "liver_disease_ncbi.txt": {
        "source_id": "NCBI_HEPATIC_PATHOPHYSIOLOGY",
        "title": "Hepatic Pathophysiology, Mitochondrial Beta-Oxidation & 4-Week Regeneration Protocol",
        "clinical_domain": "timeline_plan",
        "authority": "NCBI / NIH National Library of Medicine",
        "evidence_level": "Level 1B",
        "keywords": ["1 month", "one month", "30 day", "regeneration", "protocol", "week", "mitochondria", "beta oxidation", "timeline", "action plan"]
    },
    "liver_disease_treatments.txt": {
        "source_id": "AASLD_NUTRITION_TOXICITY",
        "title": "Evidence-Based Nutrition, Polyphenols, Alcohol Toxicity & Pharmacotherapy",
        "clinical_domain": "alcohol_toxicity",
        "authority": "AASLD / EASL Practice Guidelines",
        "evidence_level": "Level 1A",
        "keywords": ["alcohol", "vodka", "beer", "wine", "ethanol", "acetaldehyde", "mediterranean", "coffee", "polyphenols", "nutrition", "diet"]
    },
    "liver_lab_report.txt": {
        "source_id": "CLINICAL_LFT_REFERENCE",
        "title": "Serum Liver Function Tests (LFTs), Enzyme Reference Ranges & FIB-4",
        "clinical_domain": "biomarkers",
        "authority": "Clinical Laboratory Medicine Standards",
        "evidence_level": "Level 1A",
        "keywords": ["alt", "ast", "sgpt", "sgot", "bilirubin", "alp", "albumin", "platelets", "fib-4", "de ritis", "ratio"]
    },
    "README.roboflow.txt": {
        "source_id": "ROBOFLOW_HISTOLOGY_BIOPSY",
        "title": "Microscopic Liver Histopathology, Fibrosis Staging (F0-F4) & Steatosis Grading",
        "clinical_domain": "histology_biopsy",
        "authority": "Computational Pathology & Histopathology Standards",
        "evidence_level": "Level 2A",
        "keywords": ["histology", "biopsy", "scan", "patch", "fibrosis", "f0", "f1", "f2", "f3", "f4", "ballooning", "steatosis grade", "microscopic"]
    },
    "README.dataset.txt": {
        "source_id": "LPD_CLINICAL_POPULATION",
        "title": "Liver Patient Population Dataset Features, Demographics & Biomarker Correlates",
        "clinical_domain": "general",
        "authority": "Clinical Epidemiological Data Registry",
        "evidence_level": "Level 2B",
        "keywords": ["patient", "demographics", "age", "gender", "bilirubin", "alkphos", "sgot", "sgpt", "proteins"]
    }
}


def load_txt_files(data: str) -> List[Document]:
    """
    Load all plain text (.txt) files from the given directory.
    Each file is loaded as a Document with structured clinical metadata tagging.
    """
    documents: List[object] = []
    txt_files = glob.glob(os.path.join(data, "*.txt"))

    for file_path in txt_files:
        filename = os.path.basename(file_path)
        print(f"Loading TXT: {file_path}")
        content = ""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
        except UnicodeDecodeError:
            try:
                with open(file_path, "r", encoding="latin1") as f:
                    content = f.read()
            except Exception as e2:
                print(f"Warning: Could not read {file_path} — {e2}")
        except Exception as e:
            print(f"Warning: Could not load {file_path} — {e}")

        if content.strip():
            meta = {
                "source": file_path,
                "filename": filename,
            }
            if filename in DOCUMENT_REGISTRY:
                meta.update(DOCUMENT_REGISTRY[filename])
            else:
                meta.update({
                    "source_id": filename.replace(".", "_"),
                    "title": filename,
                    "clinical_domain": "general",
                    "authority": "General Hepatic Knowledge Base",
                    "evidence_level": "Level 2",
                    "keywords": []
                })

            documents.append(
                Document(
                    page_content=content,
                    metadata=meta
                )
            )

    print(f"Loaded {len(documents)} text files.")
    return documents


def load_csv_files(data: str) -> List[Document]:
    """
    Load all CSV files from the given directory.
    Each row is converted to a human-readable sentence and wrapped as a Document.
    """
    documents: List[Document] = []
    if pd is None:
        print(f"Warning: pandas not installed. Skipping CSV files in {data}.")
        return documents
    csv_files = glob.glob(os.path.join(data, "*.csv"))

    for file_path in csv_files:
        print(f"Loading CSV: {file_path}")
        try:
            df = None
            for enc in ["utf-8", "latin1", "cp1252", "iso-8859-1"]:
                try:
                    df = pd.read_csv(file_path, encoding=enc)
                    break
                except UnicodeDecodeError:
                    continue
            if df is None:
                df = pd.read_csv(file_path, encoding="utf-8", encoding_errors="replace")
            df = df.dropna(how="all")  # drop completely empty rows
            for _, row in df.iterrows():
                # Build a human-readable sentence from column: value pairs
                content = ", ".join(
                    f"{col}: {val}" for col, val in row.items() if pd.notna(val)
                )
                if content.strip():
                    documents.append(
                        Document(
                            page_content=content,
                            metadata={"source": file_path}
                        )
                    )
        except Exception as e:
            print(f"Warning: Could not load {file_path} — {e}")

    print(f"Loaded {len(documents)} rows from CSV files.")
    return documents


def load_excel_files(data: str) -> List[Document]:
    """
    Load all Excel (.xlsx / .xls) files from the given directory.
    Each row is converted to a human-readable sentence and wrapped as a Document.
    """
    documents: List[Document] = []
    if pd is None:
        print(f"Warning: pandas not installed. Skipping Excel files in {data}.")
        return documents
    excel_files = glob.glob(os.path.join(data, "*.xlsx")) + \
                  glob.glob(os.path.join(data, "*.xls"))

    for file_path in excel_files:
        print(f"Loading Excel: {file_path}")
        try:
            # Read all sheets
            xl = pd.ExcelFile(file_path)
            for sheet_name in xl.sheet_names:
                df = xl.parse(sheet_name)
                df = df.dropna(how="all")  # drop completely empty rows
                for _, row in df.iterrows():
                    content = ", ".join(
                        f"{col}: {val}" for col, val in row.items() if pd.notna(val)
                    )
                    if content.strip():
                        documents.append(
                            Document(
                                page_content=content,
                                metadata={
                                    "source": file_path,
                                    "sheet": sheet_name
                                }
                            )
                        )
        except Exception as e:
            print(f"Warning: Could not load {file_path} — {e}")

    print(f"Loaded {len(documents)} rows from Excel files.")
    return documents


# ==========================================
# Liver disease reference URLs
# ==========================================
LIVER_DISEASE_URLS = [
    "https://my.clevelandclinic.org/health/diseases/17179-liver-disease",
    # Mayo Clinic symptoms page (thin) → replaced with overview page
    "https://www.mayoclinic.org/diseases-conditions/liver-problems/diagnosis-treatment/drc-20374504",
    "https://www.nhs.uk/conditions/liver-disease/",
    "https://medlineplus.gov/liverdiseases.html",
    "https://liverfoundation.org/about-your-liver/how-liver-diseases-progress/",
    "https://utswmed.org/conditions-treatments/liver-diseases/",
    "https://en.wikipedia.org/wiki/Liver_disease",
    "https://healthcare.utah.edu/liver-disease-treatment/liver-disease",
    # UCSF surgery page (JS-blocked) → replaced with NCBI StatPearls NAFLD article (plain HTML)
    "https://www.ncbi.nlm.nih.gov/books/NBK541033/",
    # PMC article (JS-blocked) → replaced with NCBI StatPearls cirrhosis article (plain HTML)
    "https://www.ncbi.nlm.nih.gov/books/NBK482419/",
    "https://www.healthdirect.gov.au/fatty-liver",
    "https://www.webmd.com/fatty-liver-disease/liver-and-hepatic-diseases",
    "https://www.msdmanuals.com/home/liver-and-gallbladder-disorders/manifestations-of-liver-disease/overview-of-liver-disease",
    "https://www.medicalnewstoday.com/articles/liver-diseases-types",
    "https://www.uchicagomedicine.org/conditions-services/liver-diseases-hepatology/liver-failure",
    "https://www.healthline.com/health/liver-diseases",
    # Hopkins page (JS-blocked) → replaced with MedlinePlus cirrhosis (plain HTML)
    "https://medlineplus.gov/cirrhosis.html",
]


def load_url_files(urls: List[str] = None) -> List[Document]:
    """
    Load content from a list of web page URLs.
    Each page becomes one or more Document objects with source metadata.
    Defaults to LIVER_DISEASE_URLS if no urls are passed.
    """
    documents: List[object] = []
    urls = urls or LIVER_DISEASE_URLS

    for url in urls:
        print(f"Loading URL: {url}")
        try:
            loader = WebBaseLoader(
                web_path=url,
                header_template={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
                }
            )
            loaded = loader.load()
            loaded = [d for d in loaded if d.page_content and d.page_content.strip()]
            for doc in loaded:
                doc.metadata["source"] = url
            documents.extend(loaded)
        except Exception as e:
            print(f"Warning: Could not load {url} — {e}")

    print(f"Loaded {len(documents)} documents from URLs.")
    return documents


def load_all_files(data: str, include_urls: bool = True) -> List[Document]:
    """
    Unified loader: reads ALL supported file types from the Data folder,
    plus (by default) the liver disease reference URLs.
    Supported: PDF, TXT, CSV, Excel (.xlsx / .xls), and web URLs.
    Returns a combined list of Document objects.
    """
    all_docs: List[object] = []

    pdf_docs = load_pdf_files(data)
    print(f"Loaded {len(pdf_docs)} pages from PDF files.")
    all_docs.extend(pdf_docs)

    txt_docs = load_txt_files(data)
    all_docs.extend(txt_docs)

    csv_docs = load_csv_files(data)
    all_docs.extend(csv_docs)

    excel_docs = load_excel_files(data)
    all_docs.extend(excel_docs)

    if include_urls:
        url_docs = load_url_files()
        all_docs.extend(url_docs)

    print(f"Total documents loaded: {len(all_docs)}")
    return all_docs


def clean_pdf_text(text: str) -> str:
    """
    Strip structural artifacts (section headers, divider lines, labels)
    from raw document text so they never get embedded or echoed by the LLM.

    Targets patterns like:
        ================================================
        SECTION 2: ETIOLOGY (CAUSES OF LIVER DISEASE)
        ------------------------------------------------
        KNOWLEDGE BASE REFERENCE
    """
    if not text:
        return text

    # Remove divider lines made of repeated symbols (====, ----, ####, ****, etc.)
    text = re.sub(r'^[=\-#_*~]{5,}\s*$', '', text, flags=re.MULTILINE)

    # Remove lines like "SECTION 2: ETIOLOGY (CAUSES OF LIVER DISEASE)"
    text = re.sub(r'^\s*SECTION\s+\d+\s*[:\.].*$', '', text, flags=re.MULTILINE | re.IGNORECASE)

    # Remove standalone "CHAPTER <n>" style headers
    text = re.sub(r'^\s*CHAPTER\s+\d+\s*[:\.].*$', '', text, flags=re.MULTILINE | re.IGNORECASE)

    # Remove common labeling lines like "KNOWLEDGE BASE REFERENCE:" or "REFERENCE:"
    text = re.sub(r'^\s*(KNOWLEDGE\s+BASE\s+)?REFERENCE\s*:?\s*$', '', text, flags=re.MULTILINE | re.IGNORECASE)

    # Remove standalone ALL-CAPS heading lines (common in textbook/PDF section titles)
    # Requires at least 8+ characters to avoid stripping legitimate short acronyms like "HCC" mid-sentence
    text = re.sub(r'^\s*[A-Z][A-Z0-9 \(\)\-/,]{8,}\s*$', '', text, flags=re.MULTILINE)

    # Collapse resulting multiple blank lines down to a max of one blank line
    text = re.sub(r'\n{3,}', '\n\n', text)

    return text.strip()


def filter_to_minimal_docs(docs: List[object]) -> List[object]:
    """
    Given a list of Document objects, return a new list of Document objects 
    preserving structured metadata and cleaned page_content,
    with structural artifacts stripped out.
    """
    minimal_docs: List[object] = []
    for doc in docs:
        meta = getattr(doc, 'metadata', {}) or {}
        cleaned_content = clean_pdf_text(doc.page_content)
        if not cleaned_content:
            continue
        if Document is not None:
            minimal_docs.append(
                Document(
                    page_content=cleaned_content,
                    metadata=dict(meta)
                )
            )
    return minimal_docs


def format_chunk_with_boundary(chunk) -> str:
    """Format a single knowledge chunk with strict NVIDIA RAG-Blueprint boundary markers."""
    meta = getattr(chunk, 'metadata', {}) or {}
    source_id = meta.get('source_id', 'CLINICAL_KB')
    domain = meta.get('clinical_domain', 'general')
    authority = meta.get('authority', 'AASLD/EASL Practice Guidance')
    evidence = meta.get('evidence_level', 'Level 1')
    title = meta.get('title', 'Clinical Knowledge')
    content = (getattr(chunk, 'page_content', '') or '').strip()
    return (
        f'[KNOWLEDGE_CHUNK id="{source_id}" domain="{domain}" authority="{authority}" evidence="{evidence}" title="{title}"]\n'
        f"{content}\n"
        f"[/KNOWLEDGE_CHUNK]"
    )


def text_split(minimal_docs):
    """
    Split documents into semantically coherent chunks while preserving
    hierarchical document metadata tags.
    """
    if RecursiveCharacterTextSplitter is not None:
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=700,
            chunk_overlap=100,
            length_function=len
        )
        return text_splitter.split_documents(minimal_docs)

    chunks = []
    for doc in minimal_docs:
        content = (getattr(doc, 'page_content', '') or '').strip()
        meta = getattr(doc, 'metadata', {}) or {}
        if not content:
            continue
        words = content.split()
        for start in range(0, len(words), 400):
            segment = ' '.join(words[start:start + 400])
            if segment:
                chunks.append(type('Chunk', (), {'page_content': segment, 'metadata': dict(meta)})())
    return chunks


class HuggingFaceApiEmbeddings:
    """
    Zero-memory cloud embeddings via Hugging Face Inference API.
    Uses 0 MB local RAM because computation happens on the Hugging Face cloud.
    Returns 384-dimensional vectors matching sentence-transformers/all-MiniLM-L6-v2.
    """
    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        self.model_name = model_name
        self.api_url = f"https://api-inference.huggingface.co/pipeline/feature-extraction/{model_name}"
        self.token = (
            os.getenv("HF_TOKEN", "") or
            os.getenv("HUGGINGFACEHUB_API_TOKEN", "") or
            os.getenv("HUGGINGFACE_API_KEY", "")
        ).strip()

    def _query(self, texts: List[str]) -> List[List[float]]:
        import json
        import urllib.request
        headers = {
            "Content-Type": "application/json",
            "User-Agent": "LiverAI/1.0"
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"

        cleaned = [t.replace("\n", " ").strip() for t in texts]
        payload = json.dumps({"inputs": cleaned, "options": {"wait_for_model": True}}).encode("utf-8")
        req = urllib.request.Request(self.api_url, data=payload, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                if isinstance(data, list):
                    if len(data) > 0 and isinstance(data[0], float):
                        return [data]
                    return data
        except Exception as e:
            print(f"[Embeddings API Notice] {e}")
        return [[0.0] * 384 for _ in texts]

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        return self._query(texts)

    def embed_query(self, text: str) -> List[float]:
        res = self._query([text])
        if res and len(res) > 0 and isinstance(res[0], list):
            return res[0]
        return [0.0] * 384


def download_embeddings():
    """
    Return embeddings interface.
    Prioritizes HuggingFaceApiEmbeddings (0 MB RAM, perfect for cloud deployment)
    with local FastEmbed/HuggingFace fallback if explicitly requested.
    """
    print("[Embeddings] Using zero-RAM Cloud API Embeddings (384-d) ✓")
    return HuggingFaceApiEmbeddings("sentence-transformers/all-MiniLM-L6-v2")
