from typing import Any

import numpy as np
import spacy
from catboost import CatBoostClassifier

from app.core.constants import INTENT_MAP, MODEL_PATH, SPACY_MODEL_NAME


class IntentService:
    def __init__(self) -> None:
        self._model = CatBoostClassifier()
        self._model.load_model(str(MODEL_PATH))
        try:
            self._nlp = spacy.load(SPACY_MODEL_NAME)
        except Exception as err:  # noqa: BLE001
            raise RuntimeError(
                f"spaCy model '{SPACY_MODEL_NAME}' is not installed. "
                f"Run: python -m spacy download {SPACY_MODEL_NAME}"
            ) from err

    def predict(self, text: str) -> tuple[int, str, float]:
        vector = np.array(self._nlp(text).vector, dtype=np.float32).reshape(1, -1)
        candidates: list[Any] = [vector, vector.tolist()]
        last_error: Exception | None = None

        for candidate in candidates:
            try:
                pred_raw = self._model.predict(candidate)
                proba_raw = self._model.predict_proba(candidate)
                intent_id = int(pred_raw[0])
                confidence = float(max(proba_raw[0]))
                intent_name = INTENT_MAP.get(intent_id, "other")
                return intent_id, intent_name, confidence
            except Exception as err:  # noqa: BLE001
                last_error = err

        raise RuntimeError(
            f"Model inference failed for all input formats: {last_error}"
        )


intent_service = IntentService()
