import os
from dotenv import load_dotenv
from src.helper import load_all_files, filter_to_minimal_docs, text_split, download_embeddings
from langchain_pinecone import PineconeVectorStore
from pinecone import Pinecone, ServerlessSpec
import time

# Load environment variables
load_dotenv()

PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY

index_name = "chatbot-store"

# 1. Load all files from Data/ folder (PDF, TXT, CSV, Excel)
print("=" * 60)
print("STEP 1: Loading all data files from 'Data/' folder...")
print("=" * 60)
raw_docs = load_all_files("Data")

# 2. Filter and split the text into chunks
print("\nSTEP 2: Processing and splitting text into chunks...")
minimal_docs = filter_to_minimal_docs(raw_docs)
text_chunks = text_split(minimal_docs)
print(f"Total chunks created: {len(text_chunks)}")

# 3. Download the embedding model
print("\nSTEP 3: Loading embedding model...")
embeddings = download_embeddings()
print("Embedding model loaded.")

# 4. Connect to Pinecone and recreate the index
print("\nSTEP 4: Connecting to Pinecone...")
pc = Pinecone(api_key=PINECONE_API_KEY)

# Delete existing index if it exists, then wait until fully removed
if index_name in pc.list_indexes().names():
    print(f"Deleting existing index '{index_name}'...")
    pc.delete_index(index_name)
    print("Waiting for index deletion to propagate...")
    for _ in range(60):          # wait up to 60 seconds
        time.sleep(2)
        if index_name not in pc.list_indexes().names():
            print("Index deleted successfully.")
            break
    else:
        raise RuntimeError(f"Index '{index_name}' still exists after 120 s — aborting.")

print(f"Creating new index '{index_name}'...")
pc.create_index(
    name=index_name,
    dimension=384,
    metric="cosine",
    spec=ServerlessSpec(cloud="aws", region="us-east-1")
)

# Wait for index to be ready
print("Waiting for new index to become ready...")
while not pc.describe_index(index_name).status['ready']:
    print("  ...still initialising...")
    time.sleep(2)

print("Index ready!")

# 5. Push all chunks to Pinecone
print(f"\nSTEP 5: Uploading {len(text_chunks)} chunks to Pinecone...")
print("This may take several minutes...")
docsearch = PineconeVectorStore.from_documents(
    documents=text_chunks,
    index_name=index_name,
    embedding=embeddings
)

print("\n" + "=" * 60)
print("SUCCESS! Knowledge base uploaded to Pinecone.")
print(f"Total documents indexed: {len(text_chunks)} chunks")
print("You can now run app.py")
print("=" * 60)