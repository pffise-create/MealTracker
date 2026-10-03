import assert from "node:assert/strict";
import { test } from "node:test";
import { createServer } from "node:http";
import { once } from "node:events";
import { createApp } from "./index";
import { requestAI, AIError } from "./ai";

const complete = (value: unknown) => new Response(JSON.stringify({ status: "completed", output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify(value) }] }] }));
const item = (name: string, evidence = name) => ({ name, evidence, quantity: "1 serving", calories: 100, protein: 5, fat: 4, carbohydrates: 10 });
const analysis = (items: ReturnType<typeof item>[]) => ({ name: "Meal", items, calories: items.length * 100, protein: items.length * 5, fat: items.length * 4, carbohydrates: items.length * 10, confidence: "medium", assumptions: [] });

async function fixture(upstream: typeof fetch, run: (call: (route: string, body: unknown, token?: string) => Promise<Response>) => Promise<void>, deadlineMs = 1000) {
  process.env.OPENAI_API_KEY = "test-key-never-use-network";
  process.env.MEALTRACKER_BACKEND_TOKEN = "test-token";
  const server = createServer(createApp({ fetchImpl: upstream, deadlineMs }));
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();
  assert(address && typeof address === "object");
  try {
    await run((route, body, token = "test-token") => fetch(`http://127.0.0.1:${address.port}/api/${route}`, { method: "POST", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: JSON.stringify(body) }));
  } finally { server.closeAllConnections(); await new Promise<void>((resolve) => server.close(() => resolve())); }
}

test("meal success preserves contract and sufficient budget; repeated evidence and dish components work", async () => {
  for (const [text, items] of [
    ["beer and beer", [item("beer"), item("beer")]],
    ["burger", [item("beef patty", "burger"), item("bun", "burger")]],
    ["steak quesadilla", [item("steak", "steak quesadilla"), item("tortilla", "steak quesadilla"), item("cheese", "steak quesadilla")]],
    ["Two STEAK   quesadillas", [item("Grilled beef steak", "STEAK   quesadillas"), item("Flour tortillas", "STEAK   quesadillas"), item("Shredded cheese", "STEAK   quesadillas")]],
    ["beer and chicken and rice", [item("beer"), item("chicken"), item("rice")]],
  ] as const) {
    await fixture(async (_url, init) => {
      const body = JSON.parse(init!.body as string);
      assert.equal(body.model, "gpt-4o-mini");
      assert(body.max_output_tokens >= 4000);
      assert.match(new Headers(init!.headers).get("X-Client-Request-Id")!, /^[0-9a-f-]{36}$/);
      return complete(analysis([...items]));
    }, async (call) => {
      const response = await call("meal-analysis", { text });
      assert.equal(response.status, 200);
      const body = await response.json();
      assert.deepEqual(body.analysis.items, items);
      assert.equal(typeof body.provenance, "string");
    });
  }
});

test("beer never accepts invented sides, including sides with a copied beer evidence", async () => {
  for (const items of [[item("beer"), item("chicken"), item("rice")], [item("chicken", "beer"), item("rice", "beer")]]) {
    let calls = 0;
    await fixture(async () => { calls++; return complete(analysis(items)); }, async (call) => {
      const response = await call("meal-analysis", { text: "a beer" });
      assert.equal(response.status, 502);
      const body = await response.json();
      assert.equal(body.code, "ungrounded_ai_response");
      assert.equal(body.requestId, response.headers.get("X-Request-ID"));
      assert.equal(calls, 2);
    });
  }
});

test("grounding accepts ordinary preparation, regional, brand and variety qualifiers", async () => {
  for (const [text, name, evidence] of [
    ["steak quesadilla", "Steak quesadilla with cheddar cheese", "steak quesadilla"],
    ["a beer", "Beer (lager)", "beer"],
    ["siggis yogurt", "Siggi’s Icelandic yogurt", "siggis yogurt"],
    ["burger", "Burger with a toasted bun and ground beef patty", "burger"],
    ["greek yogurt", "Plain nonfat Greek yogurt", "greek yogurt"],
    ["chicken", "Roasted boneless skinless chicken breast", "chicken"],
    ["rice", "Cooked white rice", "rice"],
    ["chicken", "Chicken breast", "chicken"],
    ["coffee", "Black coffee", "coffee"],
  ] as const) {
    await fixture(async () => complete(analysis([item(name, evidence)])), async (call) => {
      const response = await call("meal-analysis", { text });
      assert.equal(response.status, 200, `${text} -> ${name}`);
    });
  }
});

test("grounding rejects fabricated phrases, substring evidence and sides hidden behind a shared food word", async () => {
  for (const [text, items] of [
    ["steak quesadilla", [item("rice", "rice")]],
    ["steak quesadilla", [item("steak"), item("rice", "steak quesadilla")]],
    ["steak quesadilla", [item("cheese fries", "quesadilla")]],
    ["a beer", [item("beer with chicken", "beer")]],
    ["hamburger", [item("ham", "ham")]],
    ["steak quesadilla", [item("steak", "visible in image")]],
    ["beer", [item("rice", "a beer")]],
  ] as const) {
    await fixture(async () => complete(analysis([...items])), async (call) => {
      const response = await call("meal-analysis", { text });
      assert.equal(response.status, 502, text);
      assert.equal((await response.json()).code, "ungrounded_ai_response");
    });
  }
});

test("twenty items and mixed photo/text meals preserve supported items", async () => {
  const items = Array.from({ length: 20 }, () => item("beer"));
  await fixture(async () => complete(analysis(items)), async (call) => {
    const response = await call("meal-analysis", { text: "beer ".repeat(20) });
    assert.equal(response.status, 200);
    assert.equal((await response.json()).analysis.items.length, 20);
  });
  await fixture(async () => complete(analysis([item("beer"), item("steak", "visible in image")])), async (call) => {
    const response = await call("meal-analysis", { text: "beer", imageBase64: "mock-photo", mimeType: "image/jpeg" });
    assert.equal(response.status, 200);
  });
});

test("incomplete, malformed, truncated and empty upstream responses are bounded and classified", async () => {
  const cases = [
    [() => new Response(JSON.stringify({ status: "incomplete", incomplete_details: { reason: "max_output_tokens" } })), "incomplete_ai_response"],
    [() => new Response("{broken"), "invalid_ai_response"],
    [() => new Response(JSON.stringify({ status: "completed", output: [{ content: [{ type: "output_text", text: '{"name":' }] }] })), "invalid_ai_response"],
    [() => new Response(JSON.stringify({ status: "completed", output: [] })), "invalid_ai_response"],
    [() => complete({}), "invalid_ai_response"],
  ] as const;
  for (const [reply, code] of cases) {
    let calls = 0;
    await fixture(async () => { calls++; return reply(); }, async (call) => {
      const response = await call("meal-analysis", { text: "beer" });
      assert.equal(response.status, 502);
      assert.equal((await response.json()).code, code);
      assert.equal(calls, 2);
    });
  }
});

test("transient or incomplete first attempt can recover, refusal and rate limits do not retry", async () => {
  for (const first of [() => new Response("private provider detail", { status: 500 }), () => new Response(JSON.stringify({ status: "incomplete" }))]) {
    let calls = 0;
    await fixture(async () => ++calls === 1 ? first() : complete(analysis([item("beer")])), async (call) => {
      assert.equal((await call("meal-analysis", { text: "beer" })).status, 200);
      assert.equal(calls, 2);
    });
  }
  for (const [reply, code, status] of [
    [() => new Response(JSON.stringify({ status: "completed", output: [{ content: [{ type: "refusal", refusal: "private refusal" }] }] })), "ai_refusal", 422],
    [() => new Response("private quota message", { status: 429 }), "upstream_rate_limited", 503],
  ] as const) {
    let calls = 0;
    await fixture(async () => { calls++; return reply(); }, async (call) => {
      const response = await call("meal-analysis", { text: "beer" });
      assert.equal(response.status, status);
      assert.equal((await response.json()).code, code);
      assert.equal(calls, 1);
    });
  }
});

test("both meal and correction requests terminate on deadline even for a stuck upstream", async () => {
  for (const route of ["meal-analysis", "entry-correction"]) {
    let calls = 0;
    await fixture(async () => { calls++; return new Promise<Response>(() => {}); }, async (call) => {
      const response = await call(route, { text: "beer", entry: { calories: 100 }, instruction: "make it 150 calories" });
      assert.equal(response.status, 504);
      assert.equal((await response.json()).code, "upstream_timeout");
      assert.equal(calls, 1);
    }, 20);
  }
});

test("deadline includes reading the response body", async () => {
  await assert.rejects(requestAI("key", "id", {}, (value) => value, {
    deadlineMs: 20,
    fetchImpl: async () => new Response(new ReadableStream({ start() {} })),
  }), (error: unknown) => error instanceof AIError && error.code === "upstream_timeout");
});

test("permanent provider configuration and quota failures are classified without retries or private details", async () => {
  const cases = [
    [401, {}, "upstream_authentication_failed", 503],
    [403, {}, "upstream_authentication_failed", 503],
    [400, {}, "upstream_request_rejected", 502],
    [404, {}, "upstream_request_rejected", 502],
    [429, { code: "insufficient_quota" }, "upstream_quota_exceeded", 503],
    [429, { code: "credit_balance_exhausted" }, "upstream_quota_exceeded", 503],
    [429, { code: "project_spend_limit_exceeded" }, "upstream_quota_exceeded", 503],
    [429, { type: "insufficient_quota" }, "upstream_quota_exceeded", 503],
    [429, { code: "rate_limit_exceeded" }, "upstream_rate_limited", 503],
  ] as const;
  for (const [status, details, code, expectedStatus] of cases) {
    let calls = 0;
    await fixture(async () => {
      calls++;
      return new Response(JSON.stringify({ error: { ...details, message: "PRIVATE PROVIDER CONTENT" } }), { status });
    }, async (call) => {
      const response = await call("meal-analysis", { text: "steak quesadilla" });
      assert.equal(response.status, expectedStatus);
      const body = await response.json();
      assert.equal(body.code, code);
      assert.equal(body.requestId, response.headers.get("X-Request-ID"));
      assert(!JSON.stringify(body).includes("PRIVATE"));
      assert.equal(calls, 1);
    });
  }
});

test("deadline also covers stalled provider error bodies", async () => {
  await assert.rejects(requestAI("key", "id", {}, (value) => value, {
    deadlineMs: 20,
    fetchImpl: async () => new Response(new ReadableStream({ start() {} }), { status: 429 }),
  }), (error: unknown) => error instanceof AIError && error.code === "upstream_timeout");
});

test("correction sends exact note and baseline, preserves returned precise nutrition contract", async () => {
  const entry = { name: "Beer", nutrition: { calories: 140, protein: 1, fat: 0, carbohydrates: 13 } };
  const correction = { applied: true, calories: 150, protein: 1, fat: 0, carbohydrates: 13, summary: "Updated calories to 150." };
  await fixture(async (_url, init) => {
    const request = JSON.parse(init!.body as string);
    assert(request.input[1].content[0].text.includes(JSON.stringify(entry)));
    assert(request.input[1].content[0].text.includes("make it exactly 150 calories"));
    assert(request.input[0].content[0].text.includes("Preserve every nutrient"));
    return complete(correction);
  }, async (call) => {
    const response = await call("entry-correction", { entry, instruction: "make it exactly 150 calories" });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { correction });
  });
});

test("correction retains unknown baseline nutrients as null with all response keys present", async () => {
  const correction = { applied: true, calories: 150, protein: null, fat: null, carbohydrates: null, summary: "Updated calories to 150." };
  await fixture(async (_url, init) => {
    const request = JSON.parse(init!.body as string);
    assert(request.input[0].content[0].text.includes("return null"));
    assert.deepEqual(request.text.format.schema.properties.protein.type, ["number", "null"]);
    return complete(correction);
  }, async (call) => {
    const response = await call("entry-correction", { entry: { name: "Meal", nutrition: { calories: 140 } }, instruction: "make it exactly 150 calories" });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { correction });
  });
});

test("authorization remains required and failures never expose upstream contents", async () => {
  let calls = 0;
  const messages: string[] = [];
  const original = console.info;
  console.info = (message) => { messages.push(message); };
  try {
    await fixture(async () => { calls++; return new Response("SENSITIVE MODEL OUTPUT", { status: 400 }); }, async (call) => {
      assert.equal((await call("meal-analysis", { text: "PRIVATE MEAL" }, "wrong")).status, 401);
      assert.equal(calls, 0);
      const response = await call("meal-analysis", { text: "PRIVATE MEAL" });
      assert.equal(response.status, 502);
      assert(!(await response.text()).includes("SENSITIVE"));
    });
    assert(messages.length > 0);
    assert(!messages.join("").match(/SENSITIVE|PRIVATE|test-key|test-token/));
  } finally { console.info = original; }
});
