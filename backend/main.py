
import os
import base64
from typing import Literal

from fastapi import FastAPI, UploadFile, File, HTTPException
from openai import AsyncOpenAI, OpenAIError
from pydantic import BaseModel, ValidationError


# ==========================================
# 1. Initialize FastAPI and Doubao Client
# ==========================================

app = FastAPI(title="BlindAssist AI Backend")

ARK_API_KEY = os.getenv("ARK_API_KEY")

if not ARK_API_KEY:
    raise RuntimeError(
        "ARK_API_KEY is not set. "
        "Please configure it before starting the server."
    )

MODEL_NAME = os.getenv(
    "ARK_MODEL",
    "doubao-seed-2-0-lite-260428"
)

client = AsyncOpenAI(
    api_key=ARK_API_KEY,
    base_url="https://ark.cn-beijing.volces.com/api/v3",
    timeout=45.0,
    max_retries=1
)


# ==========================================
# 2. Define Structured Output
# ==========================================

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


# ==========================================
# 3. AI System Prompt
# ==========================================

SYSTEM_PROMPT = """
You are BlindAssist AI, a visual environmental
awareness assistant prototype for people with
visual impairments.

Your task is to analyze the uploaded image and
identify visible obstacles and potential hazards.

Focus on:
- Stairs and sudden changes in floor level
- People and moving objects
- Chairs, boxes and other obstacles
- Doors, walls and narrow passages
- Potentially dangerous objects
- Poor lighting or unclear scenes

IMPORTANT SAFETY RULES:

1. Only describe information visible in the image.
2. Do not invent objects, distances or hazards.
3. Never claim that a walking route is safe.
4. A single image cannot establish safe navigation.
5. If the scene is unclear or uncertain:
   riskLevel = "unknown"
   direction = "unknown"
6. If a serious immediate hazard is visible:
   riskLevel = "high"
   direction = "stop"
7. Do not guess whether a user can safely move
   left, right or forward.
8. Give short, cautious and clear feedback.
9. Focus on the most important visible hazard.

LANGUAGE REQUIREMENTS:

mainObstacle must provide:
- traditionalChinese: Traditional Chinese
- simplifiedChinese: Simplified Chinese
- english: English

spokenResponse must provide:
- traditionalChinese: natural Hong Kong Cantonese
- simplifiedChinese: natural Mandarin Chinese
- english: natural English

Cantonese should be short and conversational.

Example Cantonese:
"前面有樓梯，停低先。"

OUTPUT REQUIREMENTS:

Return one valid JSON object with exactly
these four fields:

{
  "riskLevel": "high",
  "mainObstacle": {
    "traditionalChinese": "前方有樓梯",
    "simplifiedChinese": "前方有楼梯",
    "english": "Stairs ahead"
  },
  "direction": "stop",
  "spokenResponse": {
    "traditionalChinese": "前面有樓梯，停低先。",
    "simplifiedChinese": "前面有楼梯，请先停下。",
    "english": "Stairs ahead. Please stop."
  }
}

Allowed riskLevel values:
low, medium, high, unknown

Allowed direction values:
left, right, forward, slow, stop, unknown

Return JSON only.
Do not include Markdown or explanations.
"""


# ==========================================
# 4. Health Check
# ==========================================

@app.get("/")
async def home():

    return {
        "message": "BlindAssist backend is running",
        "provider": "Doubao",
        "model": MODEL_NAME
    }


# ==========================================
# 5. Analyze Image Endpoint
# ==========================================

@app.post("/analyze", response_model=VisionResult)
async def analyze_image(
    image: UploadFile = File(...)
):

    print("\n===== New Image Analysis =====", flush=True)

    # Step A: Read image data
    max_size = 5 * 1024 * 1024

    image_bytes = await image.read(max_size + 1)

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="Empty image"
        )

    if len(image_bytes) > max_size:
        raise HTTPException(
            status_code=413,
            detail="Image exceeds 5 MB limit"
        )

    # Detect JPEG or PNG from file bytes
    if image_bytes.startswith(b"\xff\xd8\xff"):
        mime_type = "image/jpeg"

    elif image_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        mime_type = "image/png"

    else:
        raise HTTPException(
            status_code=415,
            detail="Only JPEG and PNG images are supported"
        )

    image_size_kb = len(image_bytes) / 1024

    print(
        f"Received image: {image_size_kb:.1f} KB",
        flush=True
    )

    # Step B: Convert image to Base64
    base64_image = base64.b64encode(
        image_bytes
    ).decode("utf-8")

    image_url = (
        f"data:{mime_type};base64,{base64_image}"
    )

    # Step C: Send image to Doubao
    print(
        f"Sending image to Doubao: {MODEL_NAME}",
        flush=True
    )

    try:
        response = await client.chat.completions.create(

            model=MODEL_NAME,

            messages=[
                {
                    "role": "system",
                    "content": SYSTEM_PROMPT
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": (
                                "Analyze the uploaded image. "
                                "Identify visible obstacles and "
                                "potential hazards. Return JSON."
                            )
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": image_url,
                                "detail": "low"
                            }
                        }
                    ]
                }
            ],

            response_format={
                "type": "json_object"
            },

            extra_body={
                "thinking": {
                    "type": "disabled"
                }
            },

            max_tokens=1000
        )

        # Step D: Extract AI response
        if not response.choices:
            raise HTTPException(
                status_code=502,
                detail="Doubao returned no choices"
            )

        raw_json = response.choices[0].message.content

        if not raw_json:
            raise HTTPException(
                status_code=502,
                detail="Doubao returned an empty response"
            )

        print("Raw AI response received", flush=True)

        # Step E: Validate JSON using Pydantic
        try:
            result = VisionResult.model_validate_json(
                raw_json
            )

        except ValidationError as error:
            print(
                "Invalid JSON structure:",
                str(error),
                flush=True
            )

            raise HTTPException(
                status_code=502,
                detail="Invalid AI response format"
            )

        # Step F: Apply basic safety rules
        if result.riskLevel == "high":
            result.direction = "stop"

        elif result.riskLevel == "unknown":
            result.direction = "unknown"

        # Do not treat a single image as proof
        # of a safe walking route.
        if result.direction in ("left", "right", "forward"):
            result.direction = "unknown"

        # Step G: Print final result
        print("\n===== Final AI Result =====", flush=True)

        print(
            result.model_dump_json(indent=2),
            flush=True
        )

        print("===========================\n", flush=True)

        # Step H: Return JSON to iPhone
        return result

    except HTTPException:
        raise

    except OpenAIError as error:
        print(
            "Doubao API error:",
            type(error).__name__,
            str(error),
            flush=True
        )

        raise HTTPException(
            status_code=502,
            detail="Doubao API request failed"
        )
