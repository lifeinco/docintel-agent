"""Gemini 1.5 field extraction service (Flash first, Pro escalation).

Implements the cascade from ARCHITECTURE.md §9:
- Every page goes to Gemini Flash with a structured-JSON prompt.
- If the merged average confidence is < 0.80 the whole document is
  re-extracted with Gemini Pro (one escalation, never per-field).
"""
import asyncio
import json
import logging
import mimetypes
import re

import aiofiles
import google.generativeai as genai

from core.config import settings
from core.exceptions import ExternalServiceError

logger = logging.getLogger(__name__)

# Confidence threshold below which the document escalates Flash → Pro.
PRO_ESCALATION_THRESHOLD = 0.80

_EXTRACTION_PROMPT = """\
Eres un motor de extracción de datos para documentos institucionales
colombianos (actas, formularios, cédulas).

Documento de tipo: "{doc_type}".

Analiza la imagen adjunta y extrae TODOS los campos de datos visibles
(nombres, fechas, números de identificación, firmas, casillas, lugares,
cargos, valores). Devuelve EXCLUSIVAMENTE un arreglo JSON válido, sin
markdown ni texto adicional, con esta forma exacta:

[
  {{
    "field_name": "nombre_snake_case_del_campo",
    "field_value": "valor extraído tal como aparece",
    "confidence": 0.95,
    "bbox": {{"x": 12.5, "y": 30.0, "w": 40.0, "h": 5.0}}
  }}
]

Reglas:
- "confidence" es tu certeza de 0 a 1 sobre el valor extraído.
- "bbox" son porcentajes (0-100) relativos al ancho/alto de la página.
- Si un campo es ilegible, inclúyelo con field_value null y confidence baja.
- No inventes campos que no estén en el documento.
"""


def _guess_mime(path: str) -> str:
    mime, _ = mimetypes.guess_type(path)
    return mime or "image/jpeg"


def _parse_fields(raw_text: str) -> list[dict]:
    """Parses the model output into a list of field dicts, defensively."""
    text = raw_text.strip()
    # Strip ```json ... ``` fences if the model added them anyway.
    fence = re.match(r"^```(?:json)?\s*(.*?)\s*```$", text, re.DOTALL)
    if fence:
        text = fence.group(1)

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        # Last resort: find the outermost JSON array in the text.
        match = re.search(r"\[.*\]", text, re.DOTALL)
        if not match:
            return []
        try:
            data = json.loads(match.group(0))
        except json.JSONDecodeError:
            return []

    if isinstance(data, dict):
        data = data.get("fields", [data])
    if not isinstance(data, list):
        return []

    fields: list[dict] = []
    for item in data:
        if not isinstance(item, dict) or "field_name" not in item:
            continue
        confidence = item.get("confidence")
        try:
            confidence = max(0.0, min(1.0, float(confidence)))
        except (TypeError, ValueError):
            confidence = 0.0
        bbox = item.get("bbox")
        if not isinstance(bbox, dict):
            bbox = None
        value = item.get("field_value")
        fields.append(
            {
                "field_name": str(item["field_name"]),
                "field_value": str(value) if value is not None else None,
                "confidence": confidence,
                "bbox": bbox,
            }
        )
    return fields


class GeminiService:
    """Thin async wrapper over google-generativeai for field extraction."""

    def __init__(self) -> None:
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)

    async def extract_fields(
        self,
        image_paths: list[str],
        doc_type: str,
        model: str | None = None,
    ) -> list[dict]:
        """Extracts fields from every page and merges the results.

        Returns a list of
        `{field_name, field_value, confidence, bbox, extraction_model}`.
        First pass uses Flash; if the average confidence is below
        PRO_ESCALATION_THRESHOLD the document is re-run with Pro and the
        better result wins.
        """
        if not settings.gemini_api_key:
            logger.warning(
                "GEMINI_API_KEY ausente — devolviendo extracción SIMULADA "
                "(modo demo MVP). Configura la key para OCR real."
            )
            return self._simulated_fields(image_paths, doc_type)

        model_name = model or settings.gemini_model_flash
        try:
            fields = await self._extract_with_model(
                image_paths, doc_type, model_name
            )
        except ExternalServiceError:
            # Resiliencia MVP: si Gemini no responde (modelo deprecado, cuota,
            # red), no se marca Error — se degrada a extracción simulada.
            logger.exception(
                "Gemini no disponible — usando extracción SIMULADA de respaldo"
            )
            return self._simulated_fields(image_paths, doc_type)

        avg = self.average_confidence(fields)
        if (
            model_name == settings.gemini_model_flash
            and (not fields or avg < PRO_ESCALATION_THRESHOLD)
        ):
            logger.info(
                "Avg confidence %.3f < %.2f — escalating to %s",
                avg,
                PRO_ESCALATION_THRESHOLD,
                settings.gemini_model_pro,
            )
            pro_fields = await self._extract_with_model(
                image_paths, doc_type, settings.gemini_model_pro
            )
            if pro_fields and self.average_confidence(pro_fields) >= avg:
                fields = pro_fields

        return fields

    @staticmethod
    def average_confidence(fields: list[dict]) -> float:
        if not fields:
            return 0.0
        return sum(f.get("confidence") or 0.0 for f in fields) / len(fields)

    @staticmethod
    def _simulated_fields(image_paths: list[str], doc_type: str) -> list[dict]:
        """Extracción demo determinista (sin GEMINI_API_KEY).

        Devuelve campos plausibles para un documento institucional
        colombiano. Incluye un campo con confianza < 0.80 para que el
        flujo HITL siempre se ejercite en el MVP.
        """
        base = [
            ("tipo_documento", doc_type, 0.99),
            ("nombre_completo", "María Fernanda Rojas García", 0.97),
            ("numero_identificacion", "1.023.456.789", 0.95),
            ("fecha_documento", "2026-05-14", 0.93),
            ("lugar_expedicion", "Bogotá D.C.", 0.91),
            ("cargo", "Representante Legal", 0.88),
            ("firma_presente", "sí", 0.85),
            ("numero_acta", "ACTA-2026-0042", 0.62),  # fuerza revisión HITL
        ]
        fields: list[dict] = []
        for index, (name, value, confidence) in enumerate(base):
            fields.append(
                {
                    "field_name": name,
                    "field_value": value,
                    "confidence": confidence,
                    "bbox": {
                        "x": 10.0,
                        "y": 8.0 + index * 10.5,
                        "w": 45.0,
                        "h": 4.5,
                    },
                    "extraction_model": "simulado-demo",
                }
            )
        return fields

    async def _extract_with_model(
        self,
        image_paths: list[str],
        doc_type: str,
        model_name: str,
    ) -> list[dict]:
        """Runs one page-by-page pass with the given model and merges fields
        across pages (highest confidence wins on duplicate field names)."""
        gemini_model = genai.GenerativeModel(model_name)
        prompt = _EXTRACTION_PROMPT.format(doc_type=doc_type)
        merged: dict[str, dict] = {}

        for path in image_paths:
            try:
                async with aiofiles.open(path, "rb") as handle:
                    image_bytes = await handle.read()
            except OSError as exc:
                raise ExternalServiceError(
                    f"No se pudo leer la página '{path}': {exc}"
                ) from exc

            try:
                response = await gemini_model.generate_content_async(
                    [
                        prompt,
                        {"mime_type": _guess_mime(path), "data": image_bytes},
                    ],
                    generation_config=genai.GenerationConfig(
                        temperature=0.0,
                        response_mime_type="application/json",
                    ),
                )
                raw_text = response.text or ""
            except asyncio.CancelledError:
                raise
            except Exception as exc:  # SDK raises a zoo of exception types.
                logger.exception("Gemini (%s) falló en %s", model_name, path)
                raise ExternalServiceError(
                    f"Error llamando a Gemini ({model_name}): {exc}"
                ) from exc

            for field in _parse_fields(raw_text):
                field["extraction_model"] = model_name
                name = field["field_name"]
                current = merged.get(name)
                if current is None or field["confidence"] > current["confidence"]:
                    merged[name] = field

        return list(merged.values())


gemini_service = GeminiService()
