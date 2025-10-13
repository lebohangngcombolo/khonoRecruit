import os
import requests
import json
import logging
import time
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY")
OPENROUTER_URL = os.environ.get(
    "OPENROUTER_URL", "https://openrouter.ai/api/v1/chat/completions"
)
DEFAULT_MODEL = os.environ.get("OPENROUTER_MODEL", "openai/gpt-4o-mini")


class AIService:
    def __init__(
        self,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
        timeout: int = 60,
        retries: int = 3,
        backoff: int = 5,
    ):
        self.api_key = api_key or OPENROUTER_API_KEY
        self.model = model or DEFAULT_MODEL
        self.timeout = timeout
        self.retries = retries
        self.backoff = backoff

        if not self.api_key:
            logger.warning(
                "No OPENROUTER_API_KEY found in environment. AI calls will fail without a key."
            )

    def _call_generation(
        self, prompt: str, temperature: float = 0.7, max_output_tokens: int = 512
    ) -> str:
        if not self.api_key:
            raise RuntimeError("OPENROUTER_API_KEY not set")

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": "You are an expert recruitment assistant."},
                {"role": "user", "content": prompt},
            ],
            "temperature": temperature,
            "max_tokens": max_output_tokens,
        }

        for attempt in range(1, self.retries + 1):
            try:
                resp = requests.post(
                    OPENROUTER_URL, headers=headers, json=payload, timeout=self.timeout
                )
                if resp.status_code != 200:
                    logger.error(
                        "OpenRouter API error [%s]: %s", resp.status_code, resp.text
                    )
                    raise RuntimeError(
                        f"OpenRouter API error: {resp.status_code} {resp.text}"
                    )
                data = resp.json()
                return data["choices"][0]["message"]["content"]
            except requests.exceptions.Timeout:
                logger.warning(
                    "Timeout on attempt %d/%d, retrying in %d seconds...",
                    attempt,
                    self.retries,
                    self.backoff,
                )
                time.sleep(self.backoff)
            except requests.exceptions.RequestException as e:
                logger.error(
                    "RequestException on attempt %d/%d: %s", attempt, self.retries, e
                )
                time.sleep(self.backoff)
            except Exception as e:
                logger.exception(
                    "Unexpected error on attempt %d/%d: %s", attempt, self.retries, e
                )
                time.sleep(self.backoff)

        raise RuntimeError("Failed to call OpenRouter API after multiple retries")

    def chat(self, message: str, temperature: float = 0.2) -> str:
        prompt = f"User:\n{message}\n\nAssistant:"
        return self._call_generation(prompt, temperature=temperature, max_output_tokens=400)

    def analyze_cv_vs_job(
        self, cv_text: str, job_description: str, want_json: bool = True
    ) -> Dict[str, Any]:
        prompt = f"""
You are a hiring assistant specializing in parsing resumes and comparing them to job descriptions.
Please analyze the candidate CV below and the job description below.

JOB DESCRIPTION:
\"\"\"{job_description}\"\"\"

CANDIDATE CV:
\"\"\"{cv_text}\"\"\"

Task:
1) Compare candidate qualifications with the job description. Produce:
 - a numeric match_score (0-100).
 - a list "missing_skills".
 - a list "suggestions".
 - a list "interview_questions".

Return the response strictly as JSON.
"""
        out = self._call_generation(prompt, temperature=0.0, max_output_tokens=700)

        # Try to parse JSON safely
        import re

        try:
            match = re.search(r"(\{.*\})", out, flags=re.DOTALL)
            json_text = match.group(1) if match else out
            parsed = json.loads(json_text)
        except Exception:
            logger.exception("Failed to parse JSON, returning raw text")
            parsed = {
                "match_score": 0,
                "missing_skills": [],
                "suggestions": [],
                "interview_questions": [],
                "raw_output": out,
            }

        # Normalize match_score
        try:
            ms = parsed.get("match_score", parsed.get("score", 0))
            parsed["match_score"] = max(0, min(100, int(round(float(ms)))))
        except Exception:
            parsed["match_score"] = 0

        for key in ("missing_skills", "suggestions", "interview_questions"):
            if key not in parsed or not isinstance(parsed[key], list):
                parsed[key] = []

        return parsed
