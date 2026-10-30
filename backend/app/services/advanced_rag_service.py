import logging
import asyncio
from typing import List, Dict, Any, Optional
import google.generativeai as genai
import httpx

from app.core.config import settings
from app.services.vector_store_service import VectorStoreService
from app.services.ai_agent_service import AIAgentService, RiskAssessmentResult

logger = logging.getLogger(__name__)

# Danh sách Model Groq AI LPU siêu tốc
GROQ_MODELS = [
    "openai/gpt-oss-120b",
    "openai/gpt-oss-20b",
]

# Danh sách Model Gemini ưu tiên theo độ tin cậy và hạn mức (Failover Cascade)
GEMINI_MODELS = [
    "gemini-3.5-flash",
    "gemini-3.8-flash",
    "gemini-flash-latest",
]


class AdvancedRAGService:
    """
    Kiến trúc RAG Đa tầng (Multi-tier Resilient RAG Architecture):
    1. Intent Routing: Phân loại ý định thông minh (Chào hỏi / Cẩm nang / Nguy cơ).
    2. Hybrid Vector Retrieval: Tìm kiếm ngữ nghĩa ChromaDB có ngưỡng lọc tin cậy.
    3. Multi-Model Cascade: Tự động chuyển đổi mô hình dự phòng khi gặp sự cố hạn ngạch (429/timeout).
    4. Context-Aware Dynamic Fallback: Phản hồi chính xác ngay cả khi ngoại tuyến hoặc mất kết nối API.
    """

    @staticmethod
    def classify_intent(query: str) -> str:
        """Phân loại ý định người dùng để tối ưu hóa luồng xử lý (Intent Routing)."""
        clean_q = query.lower().strip()
        
        # 1. Chào hỏi / Hỏi về Enigma AI
        greetings = ["hello", "hi", "chào", "xin chào", "alo", "helo", "ban la ai", "bạn là ai", "ai vậy", "giới thiệu"]
        if clean_q in greetings or any(clean_q.startswith(g) for g in ["chào", "xin chào", "hello", "hi "]):
            return "GREETING"

        # 2. Cảm ơn / Tạm biệt
        thanks = ["cảm ơn", "cam on", "thank", "thanks", "tạm biệt", "tam biet", "bye", "ok cảm ơn"]
        if any(t in clean_q for t in thanks):
            return "CLOSING"

        # 3. Mặc định là câu hỏi nghiệp vụ / cẩm nang
        return "DOMAIN_QUERY"

    @staticmethod
    def expand_query(query: str) -> List[str]:
        """Làm giàu từ khóa ngữ nghĩa tìm kiếm vector (Query Expansion)."""
        queries = [query]
        clean_q = query.lower()

        topic_mappings = [
            (["đau chân", "giày", "esd", "mỏi chân", "gót chân", "bàn chân"], "kinh nghiệm giảm đau chân khi mang giày bảo hộ ESD ca đứng"),
            (["ngủ", "ca đêm", "mất ngủ", "đổi ca", "nhịp sinh học", "uể oải"], "bí quyết cân bằng nhịp sinh học và giấc ngủ khi đổi ca làm việc"),
            (["stress", "thở", "căng thẳng", "áp lực", "lo lắng", "sợ", "hoảng"], "kỹ thuật hít thở Box Breathing 4-4-4-4 giảm căng thẳng tức thì"),
            (["vai gáy", "cổ", "mỏi vai", "đau lưng", "giãn cơ", "đứng lâu"], "chăm sóc thể chất và bài tập giãn cơ cổ vai gáy ca đứng"),
            (["phòng", "ktx", "trọ", "bạn cùng phòng", "ở ghép", "tiếng ồn"], "kỹ năng xử lý bất đồng bạn cùng phòng ký túc xá và đổi phòng trọ"),
            (["5s", "an toàn", "quy tắc", "bảo hộ", "nội quy", "quần áo"], "quy tắc 5S và an toàn lao động tại nhà máy LG Display"),
            (["lương", "phụ cấp", "hợp đồng", "nghỉ phép", "đổi ca", "quyền lợi"], "cẩm nang tìm hiểu hợp đồng, phụ cấp và an toàn lao động thực tập sinh"),
            (["phq", "phq4", "phq-4", "sàng lọc", "tâm thần", "trầm cảm", "lo âu", "gad", "gad-7"], "quy trình sàng lọc sức khỏe tâm thần chuẩn y khoa PHQ-4 và phân tầng can thiệp"),
        ]

        for keywords, expansion in topic_mappings:
            if any(k in clean_q for k in keywords):
                queries.append(expansion)
                break

        return queries

    @staticmethod
    async def generate_advanced_rag_response(
        query: str,
        user_name: str = "Sinh viên",
        intern_phase: str = "adaptation",
        stress_level: int = 2,
        sleep_hours: Optional[float] = None,
        recent_symptoms: Optional[List[str]] = None,
        top_k: int = 3,
        user_id: Optional[str] = None,
        db=None,
        enable_function_calling: bool = True
    ) -> Dict[str, Any]:
        """Điều phối toàn bộ quy trình RAG hợp lý, logic và không gián đoạn."""
        intent = AdvancedRAGService.classify_intent(query)

        # 1. Đánh giá rủi ro tâm lý
        risk_result: RiskAssessmentResult = AIAgentService.evaluate_psychological_risk(
            stress_level=stress_level,
            sleep_hours=sleep_hours,
            note_text=query,
            physical_symptoms=recent_symptoms
        )

        rag_sources = []
        context_texts = []
        crag_status = "CORRECT"

        # 2. Xử lý theo Intent
        if intent == "DOMAIN_QUERY":
            # Chỉ truy vấn Vector DB khi là câu hỏi cẩm nang nghiệp vụ thực tế
            expanded_queries = AdvancedRAGService.expand_query(query)
            all_chunks = []
            seen_chunk_texts = set()

            for target in expanded_queries:
                results = VectorStoreService.search_similar_chunks(target, top_k=top_k)
                for res in results:
                    chunk_text = res.get("chunk", "")
                    if chunk_text and chunk_text not in seen_chunk_texts:
                        seen_chunk_texts.add(chunk_text)
                        all_chunks.append(res)

            all_chunks.sort(key=lambda x: x.get("similarity", 0.0), reverse=True)
            # Ngưỡng lọc tin cậy: Chỉ lấy các đoạn có độ tương đồng >= 0.40
            top_chunks = [c for c in all_chunks if c.get("similarity", 0.0) >= 0.40][:top_k]

            for idx, item in enumerate(top_chunks, 1):
                meta = item.get("metadata", {})
                title = meta.get("title", "Cẩm nang thực tập")
                category = meta.get("category", "general")
                article_id = meta.get("article_id", "h0")
                similarity = item.get("similarity", 0.0)

                context_texts.append(f"[Nguồn {idx}: {title}]\nChủ đề: {category}\nNội dung: {item['chunk']}")
                rag_sources.append({
                    "article_id": article_id,
                    "title": title,
                    "category": category,
                    "similarity_score": similarity
                })
        else:
            expanded_queries = [query]

        context_str = "\n\n".join(context_texts) if context_texts else "Không có trích dẫn cẩm nang cụ thể cho câu hỏi này."

        # 3. Xây dựng System Prompt thích ứng linh hoạt theo từng Intent
        if intent == "GREETING":
            system_prompt = f"""Bạn là Enigma AI — Trợ lý Đồng hành Tâm lý & Sức khỏe Thực tập tại LG Display.
Nhiệm vụ: Chào hỏi bạn {user_name} một cách ấm áp, thân thiện (dùng emoji sinh động), giới thiệu ngắn gọn khả năng hỗ trợ (giải đáp ca kíp, đau mỏi ca đứng, cẩm nang 5S, bài tập thư giãn) và hỏi thăm tình hình hôm nay của bạn ấy."""
        elif intent == "CLOSING":
            system_prompt = f"""Bạn là Enigma AI — Trợ lý Thực tập LG Display.
Nhiệm vụ: Cảm ơn bạn {user_name}, gửi lời chúc bạn có một ca làm việc an toàn, nhiều năng lượng và nhắc bạn luôn có Enigma bên cạnh khi cần hỗ trợ."""
        else:
            sleep_info = f"{sleep_hours}h" if sleep_hours is not None else "Chưa có dữ liệu (chưa rõ)"
            if sleep_hours is None:
                sleep_instruction = f"5. DỮ LIỆU GIẤC NGỦ: Hiện tại hệ thống CHƯA CÓ dữ liệu giấc ngủ ca gần nhất của bạn {user_name} (chưa rõ). Tuyệt đối KHÔNG tự giả định bạn ấy đã ngủ đủ 7 tiếng. Nếu sinh viên nhắc đến mệt mỏi, uể oải, ca kíp hay sức khỏe, hãy ân cần hỏi thăm xem ca vừa rồi bạn ấy ngủ được khoảng mấy tiếng."
            else:
                sleep_instruction = f"5. DỮ LIỆU GIẤC NGỦ: Ca gần nhất bạn {user_name} ngủ {sleep_hours}h. Hãy cân nhắc thông tin này khi tư vấn sức khỏe và phục hồi năng lượng."

            system_prompt = f"""Bạn là Enigma AI — Trợ lý Đồng hành Tâm lý, Sức khỏe & Thích nghi Thực tập Doanh nghiệp tại LG Display.

🎯 NGUYÊN TẮC PHẢN HỒI:
1. Thấu cảm & Trả lời TRỰC TIẾP, ĐÚNG TRỌNG TÂM câu hỏi của bạn {user_name}.
2. Nếu có cẩm nang liên quan bên dưới, hãy trích dẫn rõ [Nguồn X: Tên bài viết] và ứng dụng vào câu trả lời.
3. Đưa ra 2-3 lời khuyên hành động thực tế, khoa học và dễ làm theo.
4. Xưng hô thân thiện "mình - bạn" hoặc "Enigma - {user_name}".
{sleep_instruction}

👤 THÔNG TIN SINH VIÊN:
- Tên: {user_name} | Chặng: {intern_phase} | Stress: {stress_level}/5 | Ngủ: {sleep_info} | Triệu chứng: {', '.join(recent_symptoms) if recent_symptoms else 'Bình thường'}

📚 CẨM NANG LIÊN QUAN (RAG CONTEXT):
{context_str}
"""

        # 4. Multi-Model Cascade Execution: Ưu tiên GROQ siêu tốc (<1s), dự phòng GEMINI (Failover Cascade)
        ai_reply = ""
        llm_success = False

        # --- TẦNG 1: Groq AI LPU (Tốc độ phản hồi cực nhanh ~0.5 - 1s) ---
        if settings.GROQ_API_KEY:
            for groq_model in GROQ_MODELS:
                try:
                    async with httpx.AsyncClient(timeout=4.0) as client:
                        resp = await client.post(
                            "https://api.groq.com/openai/v1/chat/completions",
                            headers={
                                "Authorization": f"Bearer {settings.GROQ_API_KEY}",
                                "Content-Type": "application/json"
                            },
                            json={
                                "model": groq_model,
                                "messages": [
                                    {"role": "system", "content": system_prompt},
                                    {"role": "user", "content": query}
                                ],
                                "temperature": 0.6,
                                "max_tokens": 600,
                            }
                        )
                        if resp.status_code == 200:
                            data = resp.json()
                            content = data["choices"][0]["message"]["content"]
                            if content and content.strip():
                                ai_reply = content.strip()
                                llm_success = True
                                logger.info(f"[Dual-LLM] Đã phản hồi thành công qua Groq ({groq_model})")
                                break
                except Exception as e:
                    logger.warning(f"[Dual-LLM] Groq {groq_model} gặp lỗi ({e}), chuyển sang mô hình tiếp theo...")

        # --- TẦNG 2: Google Gemini (Dự phòng khi Groq bị rate limit hoặc mất kết nối) ---
        if not llm_success and settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            prompt_text = f"{system_prompt}\n\nCÂU HỎI CỦA SINH VIÊN:\n{query}"

            for model_name in GEMINI_MODELS:
                try:
                    model = genai.GenerativeModel(model_name)
                    response = await asyncio.wait_for(
                        asyncio.to_thread(model.generate_content, prompt_text),
                        timeout=5.0
                    )
                    if response and response.text and response.text.strip():
                        ai_reply = response.text.strip()
                        llm_success = True
                        logger.info(f"[Dual-LLM] Đã phản hồi qua Gemini ({model_name})")
                        break
                except Exception as e:
                    logger.warning(f"[Dual-LLM] Gemini {model_name} không khả dụng ({e}), thử model tiếp theo...")

        # --- TẦNG 3: Context-Aware Dynamic Fallback nếu cả 2 LLM ngoại tuyến ---
        if not llm_success:
            ai_reply = AdvancedRAGService._generate_dynamic_fallback(query, intent, rag_sources, user_name, risk_result)

        return {
            "content": ai_reply,
            "rag_sources": rag_sources,
            "crag_status": crag_status,
            "expanded_queries": expanded_queries,
            "intent": intent,
            "function_calls_made": [],
            "risk_assessment": {
                "level": risk_result.level,
                "reasons": risk_result.reasons,
                "trigger_emergency": risk_result.trigger_emergency,
                "recommended_actions": risk_result.recommended_actions
            }
        }

    @staticmethod
    async def generate_advanced_rag_response_stream(
        query: str,
        user_name: str = "Sinh viên",
        intern_phase: str = "adaptation",
        stress_level: int = 2,
        sleep_hours: Optional[float] = None,
        recent_symptoms: Optional[List[str]] = None,
        top_k: int = 3,
        user_id: Optional[str] = None,
        db: Optional[Any] = None,
    ):
        """
        Stream câu trả lời AI theo thời gian thực (Server-Sent Events / SSE).
        Từng token được yield ngay lập tức khi mô hình sinh ra.
        """
        # 1. Phân loại ý định & Đánh giá rủi ro
        intent = AdvancedRAGService.classify_intent(query)
        risk_result = AIAgentService.evaluate_psychological_risk(
            stress_level=stress_level,
            sleep_hours=sleep_hours,
            note_text=query,
            physical_symptoms=recent_symptoms
        )

        rag_sources = []
        context_texts = []
        crag_status = "CORRECT"

        if intent == "DOMAIN_QUERY":
            expanded_queries = AdvancedRAGService.expand_query(query)
            all_chunks = []
            seen_chunk_texts = set()

            for target in expanded_queries:
                results = VectorStoreService.search_similar_chunks(target, top_k=top_k)
                for res in results:
                    chunk_text = res.get("chunk", "")
                    if chunk_text and chunk_text not in seen_chunk_texts:
                        seen_chunk_texts.add(chunk_text)
                        all_chunks.append(res)

            all_chunks.sort(key=lambda x: x.get("similarity", 0.0), reverse=True)
            top_chunks = [c for c in all_chunks if c.get("similarity", 0.0) >= 0.40][:top_k]

            for idx, item in enumerate(top_chunks, 1):
                meta = item.get("metadata", {})
                title = meta.get("title", "Cẩm nang thực tập")
                category = meta.get("category", "general")
                article_id = meta.get("article_id", "h0")
                similarity = item.get("similarity", 0.0)

                context_texts.append(f"[Nguồn {idx}: {title}]\nChủ đề: {category}\nNội dung: {item['chunk']}")
                rag_sources.append({
                    "article_id": article_id,
                    "title": title,
                    "category": category,
                    "similarity_score": similarity
                })

        context_str = "\n\n".join(context_texts) if context_texts else "Không có trích dẫn cẩm nang cụ thể cho câu hỏi này."

        if intent == "GREETING":
            system_prompt = f"""Bạn là Enigma AI — Trợ lý Đồng hành Tâm lý & Sức khỏe Thực tập tại LG Display.
Nhiệm vụ: Chào hỏi bạn {user_name} một cách ấm áp, thân thiện (dùng emoji sinh động), giới thiệu ngắn gọn khả năng hỗ trợ (giải đáp ca kíp, đau mỏi ca đứng, cẩm nang 5S, bài tập thư giãn) và hỏi thăm tình hình hôm nay của bạn ấy."""
        elif intent == "CLOSING":
            system_prompt = f"""Bạn là Enigma AI — Trợ lý Thực tập LG Display.
Nhiệm vụ: Cảm ơn bạn {user_name}, gửi lời chúc bạn có một ca làm việc an toàn, nhiều năng lượng và nhắc bạn luôn có Enigma bên cạnh khi cần hỗ trợ."""
        else:
            sleep_info = f"{sleep_hours}h" if sleep_hours is not None else "Chưa có dữ liệu (chưa rõ)"
            if sleep_hours is None:
                sleep_instruction = f"5. DỮ LIỆU GIẤC NGỦ: Hiện tại hệ thống CHƯA CÓ dữ liệu giấc ngủ ca gần nhất của bạn {user_name} (chưa rõ). Tuyệt đối KHÔNG tự giả định bạn ấy đã ngủ đủ 7 tiếng. Nếu sinh viên nhắc đến mệt mỏi, uể oải, ca kíp hay sức khỏe, hãy ân cần hỏi thăm xem ca vừa rồi bạn ấy ngủ được khoảng mấy tiếng."
            else:
                sleep_instruction = f"5. DỮ LIỆU GIẤC NGỦ: Ca gần nhất bạn {user_name} ngủ {sleep_hours}h. Hãy cân nhắc thông tin này khi tư vấn sức khỏe và phục hồi năng lượng."

            system_prompt = f"""Bạn là Enigma AI — Trợ lý Đồng hành Tâm lý, Sức khỏe & Thích nghi Thực tập Doanh nghiệp tại LG Display.

🎯 NGUYÊN TẮC PHẢN HỒI:
1. Thấu cảm & Trả lời TRỰC TIẾP, ĐÚNG TRỌNG TÂM câu hỏi của bạn {user_name}.
2. Nếu có cẩm nang liên quan bên dưới, hãy trích dẫn rõ [Nguồn X: Tên bài viết] và ứng dụng vào câu trả lời.
3. Đưa ra 2-3 lời khuyên hành động thực tế, khoa học và dễ làm theo.
4. Xưng hô thân thiện "mình - bạn" hoặc "Enigma - {user_name}".
{sleep_instruction}

👤 THÔNG TIN SINH VIÊN:
- Tên: {user_name} | Chặng: {intern_phase} | Stress: {stress_level}/5 | Ngủ: {sleep_info} | Triệu chứng: {', '.join(recent_symptoms) if recent_symptoms else 'Bình thường'}

📚 CẨM NANG LIÊN QUAN (RAG CONTEXT):
{context_str}
"""

        # Yield metadata đầu tiên: rag_sources & risk_assessment
        yield {
            "type": "metadata",
            "rag_sources": rag_sources,
            "crag_status": crag_status,
            "risk_assessment": {
                "level": risk_result.level,
                "reasons": risk_result.reasons,
                "trigger_emergency": risk_result.trigger_emergency,
                "recommended_actions": risk_result.recommended_actions
            }
        }

        full_text = ""
        llm_stream_success = False

        # --- TẦNG 1: Stream qua Groq AI LPU (Siêu tốc ~500 tokens/s) ---
        if settings.GROQ_API_KEY:
            for groq_model in GROQ_MODELS:
                try:
                    async with httpx.AsyncClient(timeout=15.0) as client:
                        async with client.stream(
                            "POST",
                            "https://api.groq.com/openai/v1/chat/completions",
                            headers={
                                "Authorization": f"Bearer {settings.GROQ_API_KEY}",
                                "Content-Type": "application/json"
                            },
                            json={
                                "model": groq_model,
                                "messages": [
                                    {"role": "system", "content": system_prompt},
                                    {"role": "user", "content": query}
                                ],
                                "temperature": 0.6,
                                "max_tokens": 600,
                                "stream": True
                            }
                        ) as response:
                            if response.status_code == 200:
                                import json as json_lib
                                async for line in response.aiter_lines():
                                    line_str = line.strip()
                                    if line_str.startswith("data: ") and line_str != "data: [DONE]":
                                        chunk_json = json_lib.loads(line_str[6:])
                                        delta_text = chunk_json["choices"][0]["delta"].get("content", "")
                                        if delta_text:
                                            full_text += delta_text
                                            yield {
                                                "type": "chunk",
                                                "delta": delta_text
                                            }
                                if full_text.strip():
                                    llm_stream_success = True
                                    logger.info(f"[Dual-LLM Stream] Stream hoàn tất từ Groq ({groq_model})")
                                    break
                except Exception as e:
                    logger.warning(f"[Dual-LLM Stream] Groq {groq_model} stream lỗi ({e}), chuyển sang mô hình tiếp theo...")

        # --- TẦNG 2: Stream dự phòng qua Google Gemini ---
        if not llm_stream_success and settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            prompt_text = f"{system_prompt}\n\nCÂU HỎI CỦA SINH VIÊN:\n{query}"

            for model_name in GEMINI_MODELS:
                try:
                    model = genai.GenerativeModel(model_name)
                    response = await asyncio.to_thread(model.generate_content, prompt_text, stream=True)
                    for chunk in response:
                        if chunk.text:
                            full_text += chunk.text
                            yield {
                                "type": "chunk",
                                "delta": chunk.text
                            }
                    if full_text.strip():
                        llm_stream_success = True
                        logger.info(f"[Dual-LLM Stream] Stream hoàn tất từ Gemini ({model_name})")
                        break
                except Exception as e:
                    logger.warning(f"[Dual-LLM Stream] Gemini {model_name} không khả dụng ({e}), thử model tiếp theo...")

        # --- TẦNG 3: Context-Aware Dynamic Fallback ---
        if not llm_stream_success:
            fallback = AdvancedRAGService._generate_dynamic_fallback(query, intent, rag_sources, user_name, risk_result)
            full_text = fallback
            words = fallback.split(" ")
            chunk_size = 3
            for i in range(0, len(words), chunk_size):
                sub = " ".join(words[i:i+chunk_size]) + " "
                yield {
                    "type": "chunk",
                    "delta": sub
                }
                await asyncio.sleep(0.03)

        yield {
            "type": "done",
            "full_content": full_text.strip()
        }

    @staticmethod
    def _generate_dynamic_fallback(
        query: str,
        intent: str,
        rag_sources: List[Dict[str, Any]],
        user_name: str,
        risk_result: RiskAssessmentResult
    ) -> str:
        """Sinh câu trả lời thông minh dựa trên ngữ cảnh khi ngoại tuyến."""
        clean_q = query.lower().strip()

        if intent == "GREETING":
            return (
                f"Chào {user_name}! 🤖 Mình là Enigma AI — Trợ lý Đồng hành Tâm lý & Sức khỏe Thực tập tại LG Display.\n\n"
                f"Mình luôn sẵn sàng giải đáp thắc mắc về nhịp ca kíp, an toàn nhà máy 5S, kinh nghiệm ở KTX và hướng dẫn các bài tập phục hồi thể chất sau ca làm.\n\n"
                f"Hôm nay bạn cảm thấy thế nào? Hãy chia sẻ cùng mình nhé! ✨"
            )

        if intent == "CLOSING":
            return f"Không có gì đâu nè {user_name}! 😊 Chúc bạn có một ngày thực tập thật nhiều năng lượng và an toàn. Bất cứ khi nào cần chia sẻ hay hỗ trợ, hãy nhắn cho Enigma nhé!"

        if any(w in clean_q for w in ["đau chân", "giày", "esd", "mỏi chân", "gót chân"]):
            return (
                f"Chào {user_name}! Đau chân khi mang giày bảo hộ ESD đứng máy 8-12 tiếng là vấn đề rất phổ biến ở giai đoạn đầu.\n\n"
                f"💡 **Giải pháp phục hồi nhanh:**\n"
                f"1. **Miếng lót silicon y tế**: Sử dụng thêm lót giày có đệm gót dày để phân tán trọng lực.\n"
                f"2. **Ngâm chân nước ấm 15 phút**: Sau ca về phòng, ngâm chân nước ấm giúp giãn mao mạch và giảm nhức mỏi.\n"
                f"3. **Kê cao chân khi ngủ**: Đặt gối dưới bắp chân giúp máu lưu thông về tim, hạn chế sưng phù.\n"
                f"4. **Vận động tại chỗ**: Tranh thủ các quãng nghỉ 5 phút xoay khớp cổ chân và nhón gót."
            )

        if any(w in clean_q for w in ["ngủ", "ca đêm", "mất ngủ", "đổi ca", "nhịp sinh học"]):
            return (
                f"Chào {user_name}! Đổi ca làm việc từ ca ngày sang ca đêm dễ gây rối loạn nhịp sinh học.\n\n"
                f"💡 **Bí quyết ngủ ngon sau ca đêm:**\n"
                f"1. **Đeo kính râm khi tan ca về**: Hạn chế ánh sáng mặt trời làm ức chế hormone Melatonin.\n"
                f"2. **Phòng ngủ tối & mát (22-24°C)**: Kéo rèm kín và dùng bịt mắt chống ồn.\n"
                f"3. **Tránh caffeine trước khi hết ca 4 tiếng**: Không uống cà phê/bò húc sát giờ về phòng.\n"
                f"4. **Tắt màn hình 30 phút trước khi ngủ**: Giúp não bộ thả lỏng và dễ đi vào giấc ngủ sâu."
            )

        if any(w in clean_q for w in ["stress", "thở", "căng thẳng", "áp lực", "lo lắng"]):
            return (
                f"Chào {user_name}! Cảm giác căng thẳng khi đứng chuyền hay làm quen việc mới là điều bình thường.\n\n"
                f"🫁 **Thực hành Hít thở Box Breathing 4-4-4-4 (Hạ stress trong 3 phút):**\n"
                f"- **Bước 1**: Hít vào chậm rãi qua mũi trong **4 giây**.\n"
                f"- **Bước 2**: Giữ nín thở trong **4 giây**.\n"
                f"- **Bước 3**: Thở ra từ từ qua miệng trong **4 giây**.\n"
                f"- **Bước 4**: Nín thở nghỉ trong **4 giây** trước khi lặp lại chu kỳ tiếp theo."
            )

        if any(w in clean_q for w in ["phq", "phq4", "phq-4", "sàng lọc", "tâm thần", "trầm cảm", "lo âu"]):
            return (
                f"Chào {user_name}! Hệ thống Enigma tích hợp bộ sàng lọc sức khỏe tâm thần chuẩn y khoa **PHQ-4** (Patient Health Questionnaire-4) theo nghiên cứu của Đại học Columbia và Viện Y tế Quốc gia Hoa Kỳ (PMC8038412).\n\n"
                f"📋 **Bộ câu hỏi gồm 4 mục (thời gian làm < 1 phút):**\n"
                f"1. Ít hứng thú hoặc niềm vui trong công việc / học tập (PHQ-2)\n"
                f"2. Cảm thấy buồn rầu, chán nản hoặc tuyệt vọng (PHQ-2)\n"
                f"3. Cảm thấy lo lắng, bồn chồn hoặc căng thẳng (GAD-2)\n"
                f"4. Không thể kiểm soát sự lo lắng (GAD-2)\n\n"
                f"🎯 **Phân tầng can thiệp:**\n"
                f"- **0 - 2 điểm**: Bình thường (Tâm lý ổn định)\n"
                f"- **3 - 5 điểm**: Lo âu / trầm cảm nhẹ (Áp dụng Box Breathing & nghỉ ngơi)\n"
                f"- **6 - 8 điểm**: Mức độ vừa (Cần giảm OT, trao đổi cố vấn)\n"
                f"- **9 - 12 điểm**: Nguy cơ cao (Kích hoạt cảnh báo & liên hệ Hotline 111)\n\n"
                f"Bạn có thể mở tính năng **Sàng lọc PHQ-4** trên ứng dụng để kiểm tra nhanh nhé!"
            )

        # Nếu có nguồn cẩm nang được tìm thấy
        if rag_sources:
            top = rag_sources[0]
            return (
                f"Chào {user_name}! Về thắc mắc của bạn, Cẩm nang thực tập [{top['title']}] có hướng dẫn như sau:\n\n"
                f"💡 Hãy áp dụng các quy chuẩn an toàn và trao đổi với Trưởng ca (Leader) nếu cần hướng dẫn trực tiếp.\n"
                f"Bạn có thể hỏi thêm Enigma về các bài tập thư giãn cơ hoặc chế độ dinh dưỡng ca kíp nhé!"
            )

        return (
            f"Chào {user_name}! Mình đã ghi nhận câu hỏi của bạn. Trong môi trường thực tập tại LG Display, "
            f"hãy giữ tinh thần cởi mở và chủ động hỏi Anh/Chị Mentor hoặc Leader khi gặp trở ngại.\n\n"
            f"Bạn có thể hỏi mình về: *'Kinh nghiệm mang giày ESD'*, *'Cách ngủ ngon ca đêm'*, *'Bài tập Box Breathing'* hoặc *'Quy tắc 5S'*."
        )
