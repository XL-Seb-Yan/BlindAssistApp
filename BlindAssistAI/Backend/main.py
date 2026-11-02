import base64
from typing import Literal

from fastapi import FastAPI, UploadFile, File, HTTPException
from openai import AsyncOpenAI
from pydantic import BaseModel


app = FastAPI()
client = AsyncOpenAI()


class LocalizedText(BaseModel):
    traditionalChinese: str
    simplifiedChinese: str
    english: str


class VisionResult(BaseModel):
    riskLevel: Literal[
        "low",
        "medium",
        "high",
        "unknown"
    ]

    mainObstacle: LocalizedText

    direction: Literal[
        "left",
        "right",
        "forward",
        "slow",
        "stop",
        "unknown"
    ]

    spokenResponse: LocalizedText


@app.get("/")
def home():
    return {
        "message": "BlindAssist backend is running"
    }


@app.post("/analyze")
async def analyze_image(
    image: UploadFile = File(...)
):
    image_bytes = await image.read()

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="Empty image"
        )

    print(
        f"Received image: "
        f"{len(image_bytes) / 1024:.1f} KB"
    )

    base64_image = base64.b64encode(
        image_bytes
    ).decode("utf-8")

    response = await client.responses.parse(
        model="gpt-6-astra",

        input=[
            {
                "role": "system",
                "content": """
You are the vision analysis component of BlindAssist,
an environmental awareness prototype for blind and
visually impaired users.

Analyze only what is clearly visible in the image.

Safety rules:
1. Be conservative.
2. Never invent an obstacle or safe route.
3. If the image is unclear, dark, ambiguous, or you are
   not confident, use riskLevel = "unknown" and
   direction = "unknown".
4. If there is an immediate serious hazard, use
   riskLevel = "high" and direction = "stop".
5. Do not claim precise distances unless they are clearly
   inferable from the image.
6. Focus on the single most important immediate hazard.
7. spokenResponse must be short and action-oriented.
8. traditionalChinese spokenResponse should use natural,
   concise Hong Kong Cantonese.
9. simplifiedChinese should use natural Mandarin Chinese.
10. English should be concise.

This is an assistive awareness tool, not a replacement
for a white cane, guide dog, orientation and mobility
training, or human assistance.
"""
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text":
                        "Analyze the environment ahead."
                    },
                    {
                        "type": "input_image",
                        "image_url":
                            "data:image/jpeg;base64,"
                            + base64_image,
                        "detail": "low"
                    }
                ]
            }
        ],

        text_format=VisionResult
    )

    result = response.output_parsed

    if result is None:
        raise HTTPException(
            status_code=502,
            detail="AI returned no structured result"
        )

    print(result.model_dump_json(indent=2))

    return result
