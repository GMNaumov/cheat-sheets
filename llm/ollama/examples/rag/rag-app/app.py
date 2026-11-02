import os
import uuid
from pathlib import Path

import streamlit as st
from ollama import Client, ResponseError
from pypdf import PdfReader
from qdrant_client import QdrantClient, models

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
CHAT_MODEL = os.getenv("CHAT_MODEL", "qwen3:4b")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "nomic-embed-text")
EMBEDDING_BATCH_SIZE = int(os.getenv("EMBEDDING_BATCH_SIZE", "32"))
if EMBEDDING_BATCH_SIZE < 1:
    raise ValueError("EMBEDDING_BATCH_SIZE должно быть положительным числом.")

COLLECTION_NAME = os.getenv("COLLECTION_NAME", "documents")
DOCS_PATH = Path(os.getenv("DOCS_PATH", "/app/docs"))

ollama = Client(host=OLLAMA_BASE_URL)
qdrant = QdrantClient(url=QDRANT_URL, timeout=30)


def ensure_model(model_name: str) -> None:
    try:
        ollama.show(model_name)
    except ResponseError as error:
        if error.status_code != 404:
            raise
        ollama.pull(model_name)


def split_text(text: str, chunk_size: int = 1200, overlap: int = 200) -> list[str]:
    normalized = " ".join(text.split())
    if not normalized:
        return []

    step = chunk_size - overlap
    return [normalized[start : start + chunk_size] for start in range(0, len(normalized), step)]


def read_chunks() -> list[dict[str, str | int]]:
    chunks: list[dict[str, str | int]] = []
    for pdf_path in sorted(DOCS_PATH.glob("*.pdf")):
        reader = PdfReader(pdf_path)
        for page_number, page in enumerate(reader.pages, start=1):
            for chunk_number, text in enumerate(split_text(page.extract_text() or ""), start=1):
                chunks.append(
                    {
                        "source": pdf_path.name,
                        "page": page_number,
                        "chunk": chunk_number,
                        "text": text,
                    }
                )
    return chunks


def index_documents() -> int:
    chunks = read_chunks()
    if not chunks:
        raise RuntimeError(f"В {DOCS_PATH} не найдено PDF-файлов с извлекаемым текстом.")

    ensure_model(EMBEDDING_MODEL)
    texts = [str(chunk["text"]) for chunk in chunks]
    embeddings = []
    for start in range(0, len(texts), EMBEDDING_BATCH_SIZE):
        batch = texts[start : start + EMBEDDING_BATCH_SIZE]
        embeddings.extend(ollama.embed(model=EMBEDDING_MODEL, input=batch).embeddings)

    if not qdrant.collection_exists(COLLECTION_NAME):
        qdrant.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=models.VectorParams(
                size=len(embeddings[0]),
                distance=models.Distance.COSINE,
            ),
        )

    points = []
    for chunk, vector in zip(chunks, embeddings, strict=True):
        point_key = f'{chunk["source"]}:{chunk["page"]}:{chunk["chunk"]}'
        points.append(
            models.PointStruct(
                id=str(uuid.uuid5(uuid.NAMESPACE_URL, point_key)),
                vector=vector,
                payload=chunk,
            )
        )

    qdrant.upsert(collection_name=COLLECTION_NAME, points=points, wait=True)
    qdrant.delete(
        collection_name=COLLECTION_NAME,
        points_selector=models.FilterSelector(
            filter=models.Filter(
                must_not=[models.HasIdCondition(has_id=[point.id for point in points])],
            ),
        ),
        wait=True,
    )
    return len(points)


def answer_question(question: str) -> tuple[str, list[str]]:
    if not qdrant.collection_exists(COLLECTION_NAME):
        raise RuntimeError("Сначала проиндексируйте документы.")

    ensure_model(EMBEDDING_MODEL)
    query_vector = ollama.embed(model=EMBEDDING_MODEL, input=question).embeddings[0]
    matches = qdrant.query_points(
        collection_name=COLLECTION_NAME,
        query=query_vector,
        limit=4,
        with_payload=True,
    ).points

    context_parts = []
    sources = []
    for match in matches:
        payload = match.payload or {}
        source = f'{payload.get("source", "unknown")}, стр. {payload.get("page", "?")}'
        sources.append(source)
        context_parts.append(f"Источник: {source}\n{payload.get('text', '')}")

    ensure_model(CHAT_MODEL)
    context = "\n\n".join(context_parts)
    prompt = (
        "Ответь на вопрос только на основе приведённого контекста. "
        "Если в контексте нет ответа, прямо сообщи об этом.\n\n"
        f"Контекст:\n{context}\n\n"
        f"Вопрос: {question}"
    )
    response = ollama.chat(
        model=CHAT_MODEL,
        messages=[{"role": "user", "content": prompt}],
        stream=False,
    )
    return response.message.content or "", sources


st.set_page_config(page_title="Локальный RAG", page_icon="📚")
st.title("Локальный RAG")
st.caption(f"Чат: {CHAT_MODEL} · эмбеддинги: {EMBEDDING_MODEL}")

if st.button("Проиндексировать PDF", type="primary"):
    try:
        with st.spinner("Читаю документы, загружаю модель и строю индекс..."):
            count = index_documents()
        st.success(f"Проиндексировано фрагментов: {count}")
    except Exception as error:
        st.error(f"Не удалось построить индекс: {error}")

question = st.chat_input("Задайте вопрос по документам")
if question:
    with st.chat_message("user"):
        st.write(question)

    with st.chat_message("assistant"):
        try:
            with st.spinner("Ищу ответ..."):
                answer, sources = answer_question(question)
            st.write(answer)
            if sources:
                st.caption("Источники: " + "; ".join(dict.fromkeys(sources)))
        except Exception as error:
            st.error(f"Не удалось получить ответ: {error}")
