# Sleep Helper Backend

Minimal FastAPI backend for the mobile chat client.

## Run

```powershell
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m spacy download ru_core_news_lg
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

- `GET /health` - service health check
- `POST /messages` - accept a chat message and return model prediction

### Request example

```json
{
  "message": "Hi backend"
}
```

### Response example

```json
{
  "response": "Ответ модели: insomnia_now",
  "intent_id": 0,
  "intent_name": "insomnia_now",
  "confidence": 0.93
}
```
