export class AIError extends Error {
  constructor(public code: string, public status = 502, public retryable = false) {
    super(code);
  }
}

export type AIOptions = { fetchImpl?: typeof fetch; deadlineMs?: number };

async function upstreamFailure(response: Response): Promise<AIError> {
  if (response.status === 429) {
    // Inspect only known machine-readable categories. Never retain or expose
    // provider messages: those can contain credentials or private meal text.
    let error: { code?: unknown; type?: unknown } | undefined;
    try { error = (await response.json())?.error; } catch { /* Non-JSON rate limit response. */ }
    const billingCodes = new Set([
      "insufficient_quota", "credit_balance_exhausted", "billing_hard_limit_reached",
      "organization_spend_limit_exceeded", "project_spend_limit_exceeded", "organization_usage_limit_exceeded",
    ]);
    if (error?.type === "insufficient_quota" || (typeof error?.code === "string" && billingCodes.has(error.code))) {
      return new AIError("upstream_quota_exceeded", 503);
    }
    return new AIError("upstream_rate_limited", 503);
  }
  void response.body?.cancel().catch(() => {});
  if (response.status === 401 || response.status === 403) {
    return new AIError("upstream_authentication_failed", 503);
  }
  if ([400, 404, 422].includes(response.status)) {
    return new AIError("upstream_request_rejected", 502);
  }
  return new AIError("upstream_unavailable", 502, response.status >= 500);
}

function outputText(payload: any): string {
  if (payload?.incomplete_details?.reason === "content_filter") throw new AIError("ai_refusal", 422);
  if (payload?.status === "incomplete") throw new AIError("incomplete_ai_response", 502, true);
  if (payload?.status !== "completed") throw new AIError("invalid_ai_response", 502, true);
  const content = Array.isArray(payload.output)
    ? payload.output.flatMap((item: any) => Array.isArray(item?.content) ? item.content : []) : [];
  if (content.some((item: any) => item?.type === "refusal")) throw new AIError("ai_refusal", 422);
  const text = content.filter((item: any) => item?.type === "output_text" && typeof item.text === "string")
    .map((item: any) => item.text).join("");
  if (!text) throw new AIError("invalid_ai_response", 502, true);
  return text;
}

// The deadline covers both attempts AND reading the response body. Never log
// provider error bodies: they can echo the user's private input.
export async function requestAI<T>(apiKey: string, requestId: string, body: Record<string, unknown>, validate: (value: unknown) => T, options: AIOptions = {}): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), options.deadlineMs ?? 45_000);
  const aborted = new Promise<never>((_, reject) => {
    controller.signal.addEventListener("abort", () => reject(new AIError("upstream_timeout", 504)), { once: true });
  });
  try {
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        return await Promise.race([aborted, (async () => {
          const response = await (options.fetchImpl ?? fetch)("https://api.openai.com/v1/responses", {
            method: "POST",
            headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json", "X-Client-Request-Id": requestId },
            body: JSON.stringify(body), signal: controller.signal,
          });
          if (!response.ok) {
            throw await upstreamFailure(response);
          }
          let payload;
          try { payload = await response.json(); } catch { throw new AIError("invalid_ai_response", 502, true); }
          const text = outputText(payload);
          try { return validate(JSON.parse(text)); } catch (error) {
            if (error instanceof AIError) throw error;
            throw new AIError("invalid_ai_response", 502, true);
          }
        })()]);
      } catch (error) {
        if (controller.signal.aborted) throw new AIError("upstream_timeout", 504);
        const failure = error instanceof AIError ? error : new AIError("upstream_unavailable", 502, true);
        if (!failure.retryable || attempt === 1) throw failure;
        if (failure.code === "incomplete_ai_response" && typeof body.max_output_tokens === "number") {
          body = { ...body, max_output_tokens: Math.min(body.max_output_tokens * 2, 12_000) };
        }
      }
    }
    throw new AIError("upstream_unavailable");
  } finally { clearTimeout(timer); }
}
