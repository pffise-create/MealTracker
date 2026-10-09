import assert from "node:assert/strict";
import { test } from "node:test";
import { createServer } from "node:http";
import { once } from "node:events";
import { createApp } from "./index";
import { requestAI, AIError } from "./ai";

const complete = (value: unknown) => new Response(JSON.stringify({ status: "completed", output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify(value) }] }] }));
type AnalysisItem = { name: string; quantity: string; calories: number | null; protein: number | null; fat: number | null; carbohydrates: number | null };
const item = (name: string): AnalysisItem => ({ name, quantity: "1 serving", calories: 100, protein: 5, fat: 4, carbohydrates: 10 });
const analysis = (items: AnalysisItem[], overrides: Record<string, unknown> = {}) => {
  const total = (key: "calories" | "protein" | "fat" | "carbohydrates") => items.some((value) => value[key] === null)
    ? null : items.reduce((sum, value) => sum + (value[key] ?? 0), 0);
  return { name: "Meal", items, calories: total("calories"), protein: total("protein"), fat: total("fat"), carbohydrates: total("carbohydrates"), confidence: "medium", assumptions: [], ...overrides };
};
const correctionItem = (name: string, quantity: string, calories: number | null, protein: number | null, fat: number | null, carbohydrates: number | null) => ({ name, quantity, calories, protein, fat, carbohydrates });
const correction = (items: ReturnType<typeof correctionItem>[], overrides: Record<string, unknown> = {}) => ({
  applied: true,
  name: "Sandwich",
  portionLabel: "1 sandwich",
  items,
  calories: items.reduce((sum, value) => sum + (value.calories ?? 0), 0),
  protein: items.reduce((sum, value) => sum + (value.protein ?? 0), 0),
  fat: items.reduce((sum, value) => sum + (value.fat ?? 0), 0),
  carbohydrates: items.reduce((sum, value) => sum + (value.carbohydrates ?? 0), 0),
  summary: "Updated the sandwich estimate.",
  ...overrides,
});

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

test("meal requests preserve user text, model, budget and a nullable schema without evidence gates", async () => {
  const expected = analysis([item("think! Oreo Protein Bar")]);
  await fixture(async (_url, init) => {
    const body = JSON.parse(init!.body as string);
    assert.equal(body.model, "gpt-4o-mini");
    assert.equal(body.max_output_tokens, 4096);
    assert.equal(body.store, false);
    assert.match(new Headers(init!.headers).get("X-Client-Request-Id")!, /^[0-9a-f-]{36}$/);
    assert.deepEqual(body.input[1].content, [{ type: "input_text", text: "Meal description: two think bars (Oreo)" }]);
    const schema = body.text.format.schema;
    assert.deepEqual([...schema.required].sort(), Object.keys(schema.properties).sort());
    const itemSchema = schema.properties.items.items;
    assert.deepEqual([...itemSchema.required].sort(), Object.keys(itemSchema.properties).sort());
    assert.equal(itemSchema.properties.evidence, undefined);
    assert.equal(schema.properties.items.maxItems, undefined);
    assert.deepEqual(schema.properties.protein.type, ["number", "null"]);
    assert.deepEqual(itemSchema.properties.protein.type, ["number", "null"]);
    const prompt = body.input[0].content[0].text;
    assert.match(prompt, /typed or transcribed speech, shorthand, typos, brands/);
    assert.match(prompt, /Use supplied nutrition numbers and quantities in context/);
    assert.match(prompt, /rather than adding unrelated sides/);
    assert(!prompt.includes("exact contiguous"));
    return complete(expected);
  }, async (call) => {
    const response = await call("meal-analysis", { text: "two think bars (Oreo)" });
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.deepEqual(body.analysis, expected);
    assert.equal(typeof body.provenance, "string");
  });
});

test("Think Oreo brand punctuation, spelling variants and retired evidence do not reject estimates", async () => {
  for (const [text, name, evidence] of [
    ["two think bars (Oreo)", "think! Oreo Protein Bar", undefined],
    ["two think bars (Oreo)", "think! Oreo Protein Bar", "think! bars"],
    ["two think bars (Oreo)", "think! Oreo Protein Bar", "2 think bars"],
    ["two think bars (Oreo)", "think! Oreo Protein Bar", "think! Oreo Protein Bar"],
    ["two think bars (Oreo)", "Oreo-flavored protein bars", ""],
    ["too think baarz oreo", "think! Oreo Protein Bars", undefined],
    ["2 THINK! bars — cookies & cream", "Cookies-and-cream protein bars", undefined],
  ] as const) {
    const expected = analysis([{ ...item(name), quantity: "2 bars" }]);
    let calls = 0;
    await fixture(async () => { calls++; return complete({ ...expected, items: expected.items.map((value) => ({ ...value, evidence })) }); }, async (call) => {
      const response = await call("meal-analysis", { text });
      assert.equal(response.status, 200, text);
      assert.deepEqual((await response.json()).analysis, expected);
      assert.equal(calls, 1);
    });
  }
});

test("meal interpretation is model-led instead of a hard-coded dish or ingredient vocabulary", async () => {
  for (const [text, items] of [
    ["that buttery noodle thing", [item("Pasta"), item("Butter"), item("Parmesan")]],
    ["my usual avo toast", [item("Sourdough bread"), item("Avocado"), item("Olive oil")]],
    ["a turkey sando", [item("Whole wheat bread"), item("Turkey"), item("Mustard")]],
    ["noodles with the green sauce", [item("Linguine"), item("Basil pesto")]],
  ] as const) {
    await fixture(async () => complete(analysis([...items])), async (call) => {
      const response = await call("meal-analysis", { text });
      assert.equal(response.status, 200, text);
      assert.deepEqual((await response.json()).analysis.items, items);
    });
  }
});

test("calorie-only descriptions and unknown macros are accepted without a food-name requirement", async () => {
  for (const text of ["120 calories per serving, I ate 2 servings", "240 calories total", "a snack, calories are on the wrapper but I do not know the macros"]) {
    const expected = analysis([{ name: "Logged snack", quantity: "Amount eaten", calories: 240, protein: null, fat: null, carbohydrates: null }]);
    await fixture(async (_url, init) => {
      const body = JSON.parse(init!.body as string);
      assert.equal(body.input[1].content[0].text, `Meal description: ${text}`);
      return complete(expected);
    }, async (call) => {
      const response = await call("meal-analysis", { text });
      assert.equal(response.status, 200);
      assert.deepEqual((await response.json()).analysis, expected);
    });
  }
});

test("meal-level nutrition is accepted without a fabricated ingredient breakdown", async () => {
  const expected = analysis([], { name: "Logged snack", calories: 240, protein: null, fat: null, carbohydrates: null });
  await fixture(async (_url, init) => {
    const body = JSON.parse(init!.body as string);
    assert.equal(body.text.format.schema.properties.items.minItems, undefined);
    return complete(expected);
  }, async (call) => {
    const response = await call("meal-analysis", { text: "240 calories total; I do not have the ingredient details" });
    assert.equal(response.status, 200);
    assert.deepEqual((await response.json()).analysis, expected);
  });
});

test("meal and correction values above old semantic caps remain valid within the transport budget", async () => {
  const name = "Detailed meal name ".repeat(10).trim();
  const quantity = "A detailed description of the consumed amount ".repeat(3).trim();
  const largeItem = { name, quantity, calories: 12_345, protein: 1_234, fat: 1_111, carbohydrates: 1_345 };
  const items = Array.from({ length: 21 }, () => largeItem);
  const longText = "A material assumption explained in ordinary language. ".repeat(5).trim();
  const meal = analysis(items, { name, assumptions: Array.from({ length: 9 }, () => longText) });
  const edit = correction(items, { name, portionLabel: quantity, summary: longText });
  for (const [route, expected] of [["meal-analysis", meal], ["entry-correction", edit]] as const) {
    await fixture(async () => complete(expected), async (call) => {
      const response = await call(route, { text: "the whole meal", entry: { name: "Meal" }, instruction: "re-estimate everything" });
      assert.equal(response.status, 200, route);
      assert.deepEqual((await response.json())[route === "meal-analysis" ? "analysis" : "correction"], expected);
    });
  }
});

test("meal validation still rejects malformed objects, missing nutrients and negative values", async () => {
  const valid = analysis([item("Meal")]);
  for (const invalid of [
    { ...valid, calories: -1 },
    { ...valid, protein: "unknown" },
    { ...valid, fat: undefined },
    { ...valid, name: "" },
    { ...valid, items: [{ ...valid.items[0], quantity: "" }] },
    { ...valid, items: [{ ...valid.items[0], carbohydrates: -3 }] },
    { ...valid, items: [{ ...valid.items[0], protein: undefined }] },
    { ...valid, confidence: "certain" },
    { ...valid, assumptions: "none" },
  ]) {
    await fixture(async () => complete(invalid), async (call) => {
      const response = await call("meal-analysis", { text: "a snack" });
      assert.equal(response.status, 502);
      assert.equal((await response.json()).code, "invalid_ai_response");
    });
  }
});

test("photo captions travel with the image and refine preparation or portion", async () => {
  for (const caption of ["pan-fried in butter", "grilled, no oil", "I ate half"]) {
    const expected = analysis([{
      ...item("Chicken breast"),
      quantity: caption === "I ate half" ? "Half the pictured serving" : "1 serving",
    }]);
    let calls = 0;
    await fixture(async (_url, init) => {
      calls++;
      const request = JSON.parse(init!.body as string);
      assert.deepEqual(request.input[1], { role: "user", content: [
        { type: "input_text", text: `Photo caption: ${caption}` },
        { type: "input_image", image_url: "data:image/jpeg;base64,mock-photo" },
      ] });
      const instructions = request.input[0].content[0].text;
      assert.match(instructions, /Interpret the image and any caption together/);
      assert.match(instructions, /Use explicit user details over visual guesses/);
      assert.match(instructions, /avoid counting the same food or cooking fat twice/);
      assert.match(instructions, /food, packaging, a nutrition label, or a screenshot/);
      assert(!instructions.includes("evidence"));
      return complete(expected);
    }, async (call) => {
      const response = await call("meal-analysis", { text: ` \n ${caption} \n `, imageBase64: "mock-photo", mimeType: "image/jpeg", category: "dinner" });
      assert.equal(response.status, 200, caption);
      assert.deepEqual((await response.json()).analysis, expected);
      assert.equal(calls, 1);
    });
  }
});

test("photo captions may imply ingredients without literal food-name matches", async () => {
  for (const [caption, items] of [
    ["cooked in a little fat", [item("Chicken breast"), item("Butter")]],
    ["the creamy dressing was homemade", [item("Salad greens"), item("Mayonnaise"), item("Olive oil")]],
    ["this is the label, I had the whole packet", [{ ...item("Packaged snack"), quantity: "1 packet", protein: null }]],
  ] as const) {
    const expected = analysis([...items]);
    await fixture(async () => complete(expected), async (call) => {
      const response = await call("meal-analysis", { text: caption, imageBase64: "mock-photo", mimeType: "image/png" });
      assert.equal(response.status, 200);
      assert.deepEqual((await response.json()).analysis, expected);
    });
  }
});

test("photo captions remain optional and whitespace captions behave like photo-only requests", async () => {
  for (const caption of [undefined, " \n\t "]) {
    await fixture(async (_url, init) => {
      const request = JSON.parse(init!.body as string);
      assert.deepEqual(request.input[1].content, [
        { type: "input_image", image_url: "data:image/png;base64,mock-photo" },
      ]);
      return complete(analysis([item("Steak")]));
    }, async (call) => {
      assert.equal((await call("meal-analysis", { text: caption, imageBase64: "mock-photo", mimeType: "image/png" })).status, 200);
    });
  }
});

test("text-only requests reach the model unchanged and no-input requests never call it", async () => {
  let calls = 0;
  await fixture(async (_url, init) => {
    calls++;
    const request = JSON.parse(init!.body as string);
    assert.deepEqual(request.input[1].content, [{ type: "input_text", text: "Meal description: a beer" }]);
    assert.match(request.input[0].content[0].text, /rather than adding unrelated sides/);
    return complete(analysis([item("Beer")]));
  }, async (call) => {
    assert.equal((await call("meal-analysis", { text: " a beer " })).status, 200);
    assert.equal((await call("meal-analysis", { text: " \n ", imageBase64: "" })).status, 400);
    assert.equal(calls, 1);
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
  const expected = correction([correctionItem("Beer", "1 can", 150, 1, 0, 13)], { name: "Beer", portionLabel: "1 can", summary: "Updated calories to 150." });
  await fixture(async (_url, init) => {
    const request = JSON.parse(init!.body as string);
    assert(request.input[1].content[0].text.includes(JSON.stringify(entry)));
    assert(request.input[1].content[0].text.includes("make it exactly 150 calories"));
    assert.match(request.input[0].content[0].text, /Honor supplied facts and numbers/);
    assert.match(request.input[0].content[0].text, /An exact calorie-only correction should preserve the other nutrients/);
    return complete(expected);
  }, async (call) => {
    const response = await call("entry-correction", { entry, instruction: "make it exactly 150 calories" });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { correction: expected });
  });
});

test("correction retains unknown baseline nutrients as null with all response keys present", async () => {
  const expected = correction([correctionItem("Meal", "1 serving", 150, null, null, null)], { name: "Meal", portionLabel: "1 serving", protein: null, fat: null, carbohydrates: null, summary: "Updated calories to 150." });
  await fixture(async (_url, init) => {
    const request = JSON.parse(init!.body as string);
    assert(request.input[0].content[0].text.includes("return null"));
    assert.deepEqual(request.text.format.schema.properties.protein.type, ["number", "null"]);
    assert.deepEqual(request.text.format.schema.properties.items.items.properties.protein.type, ["number", "null"]);
    return complete(expected);
  }, async (call) => {
    const response = await call("entry-correction", { entry: { name: "Meal", nutrition: { calories: 140 } }, instruction: "make it exactly 150 calories" });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { correction: expected });
  });
});

test("conversational bread substitutions receive original input and prior corrections, without a phrase whitelist", async () => {
  const entry = {
    name: "Turkey sandwich",
    ingredients: [{ id: "bread", name: "White bread • 2 slices", nutrition: { calories: 150, protein: 5, fat: 2, carbohydrates: 28 } }],
    nutrition: { calories: 340, protein: 26, fat: 10, carbohydrates: 34 },
    portionFactor: 1,
    analysisContext: { originalInput: "a turkey sandwich", corrections: ["no mayo, mustard instead"] },
  };
  const expected = correction([
    correctionItem("Wheat bread", "2 slices", 160, 7, 2, 28),
    correctionItem("Turkey", "3 oz", 90, 18, 1, 2),
    correctionItem("Mustard", "1 tsp", 3, 0, 0, 0),
  ], { name: "Turkey sandwich on wheat", summary: "Changed to wheat bread; kept turkey and mustard, with no mayo." });
  await fixture(async (_url, init) => {
    const request = JSON.parse(init!.body as string);
    const prompt = request.input[0].content[0].text;
    assert.match(prompt, /user's free-form follow-up/);
    assert.match(prompt, /latest correction overrides conflicting earlier details/);
    assert.match(prompt, /without undoing unrelated previous corrections/);
    assert.match(prompt, /Nutrition can increase or decrease/);
    assert.match(prompt, /Freely change foods, ingredients, preparation, amounts, name and nutrition/);
    assert(!prompt.includes("Do not add foods, remove foods, rename the meal, or estimate new nutrition"));
    assert(request.input[1].content[0].text.includes(JSON.stringify(entry)));
    assert(request.input[1].content[0].text.includes("nah it was on whole wheat"));
    assert(request.max_output_tokens >= 4000);
    assert.equal(request.store, false);
    const schema = request.text.format.schema;
    assert.deepEqual([...schema.required].sort(), Object.keys(schema.properties).sort());
    assert.deepEqual([...schema.properties.items.items.required].sort(), Object.keys(schema.properties.items.items.properties).sort());
    return complete(expected);
  }, async (call) => {
    const response = await call("entry-correction", { entry, instruction: "nah it was on whole wheat" });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { correction: expected });
  });
});

test("corrections support additions, removals, preparation changes, complete replacement and re-estimation", async () => {
  const scenarios = [
    ["add an egg", correction([correctionItem("Sandwich", "1 sandwich", 350, 25, 12, 35), correctionItem("Egg", "1 large", 70, 6, 5, 0)])],
    ["take the cheese out", correction([correctionItem("Bread", "2 slices", 150, 5, 2, 28), correctionItem("Turkey", "3 oz", 90, 18, 1, 2)])],
    ["actually fried in a tablespoon of butter", correction([correctionItem("Sandwich", "1 sandwich", 350, 25, 12, 35), correctionItem("Butter", "1 tbsp", 102, 0, 11.5, 0)])],
    ["no it was a salad, not a sandwich", correction([correctionItem("Mixed greens", "2 cups", 20, 2, 0, 4)], { name: "Mixed green salad", portionLabel: "1 bowl" })],
    ["that looks too low, please re-estimate it as a large deli sandwich", correction([correctionItem("Large deli sandwich", "1 sandwich", 780, 42, 32, 80)])],
  ] as const;
  for (const [instruction, expected] of scenarios) {
    await fixture(async () => complete(expected), async (call) => {
      const response = await call("entry-correction", { entry: { name: "Sandwich", nutrition: { calories: 350 } }, instruction });
      assert.equal(response.status, 200, instruction);
      assert.deepEqual(await response.json(), { correction: expected });
    });
  }
});

test("portion corrections return consumed totals once and allow a zero-food result", async () => {
  for (const [instruction, expected] of [
    ["I only ate half", correction([correctionItem("Sandwich", "1/2 sandwich", 175, 12.5, 6, 17.5)], { portionLabel: "Half a sandwich" })],
    ["actually two sandwiches, not one", correction([correctionItem("Sandwich", "2 sandwiches", 700, 50, 24, 70)], { portionLabel: "2 sandwiches" })],
    ["remove everything, I didn't eat it", correction([], { portionLabel: "None eaten", summary: "Removed the foods; nothing was eaten." })],
  ] as const) {
    await fixture(async (_url, init) => {
      const request = JSON.parse(init!.body as string);
      const prompt = request.input[0].content[0].text;
      assert.match(prompt, /Never apply the existing portionFactor a second time/);
      assert.match(prompt, /halve the currently logged amount once/);
      return complete(expected);
    }, async (call) => {
      const response = await call("entry-correction", { entry: { name: "Sandwich", nutrition: { calories: 350 }, portionFactor: 0.5 }, instruction });
      assert.equal(response.status, 200);
      assert.deepEqual(await response.json(), { correction: expected });
    });
  }
});

test("existing half and large portions normalize ingredient macros once without scaling aggregate or losing context", async () => {
  for (const factor of [0.5, 1.5]) {
    const baseNutrition = { calories: 200, protein: 8, fat: null, carbohydrates: 30 };
    const consumedNutrition = { calories: 200 * factor, protein: 8 * factor, fat: null, carbohydrates: 30 * factor };
    const context = { originalInput: "a sandwich", corrections: ["no cheese"] };
    const entry = {
      name: "Sandwich",
      ingredients: [{ id: "bread", name: "White bread • 2 slices", nutrition: baseNutrition }],
      nutrition: consumedNutrition,
      portionFactor: factor,
      portionLabel: factor === 0.5 ? "Half" : "Large",
      analysisContext: context,
    };
    const expected = correction([correctionItem("Wheat bread", `${2 * factor} slices`, 210 * factor, 10 * factor, 2 * factor, 30 * factor)], { portionLabel: entry.portionLabel });
    await fixture(async (_url, init) => {
      const request = JSON.parse(init!.body as string);
      const prompt = request.input[0].content[0].text;
      assert.match(prompt, /server has normalized existing ingredient nutrition to the consumed amount/);
      assert.match(prompt, /do not multiply any nutrition/);
      const payload = request.input[1].content[0].text;
      const baseline = JSON.parse(payload.slice("Existing meal entry:\n".length).split("\n\nCorrection note:")[0]);
      assert.equal(baseline.portionFactor, 1);
      assert.equal(baseline.originalPortionFactor, factor);
      assert.deepEqual(baseline.nutrition, consumedNutrition);
      assert.deepEqual(baseline.ingredients[0].nutrition, consumedNutrition);
      assert.equal(baseline.ingredients[0].name, entry.ingredients[0].name);
      assert.deepEqual(baseline.analysisContext, context);
      return complete(expected);
    }, async (call) => {
      const response = await call("entry-correction", { entry, instruction: "it was on wheat bread" });
      assert.equal(response.status, 200);
      assert.deepEqual(await response.json(), { correction: expected });
      assert.deepEqual(entry.ingredients[0].nutrition, baseNutrition);
    });
  }
});

test("non-actionable correction returns a clarification without changing the baseline", async () => {
  const expected = correction([correctionItem("Sandwich", "1 sandwich", 350, 25, 12, 35)], { applied: false, summary: "What should change about this sandwich?" });
  await fixture(async () => complete(expected), async (call) => {
    const response = await call("entry-correction", { entry: { name: "Sandwich", nutrition: { calories: 350 } }, instruction: "what is the weather?" });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { correction: expected });
  });
});

test("full correction validation rejects negative nutrition and malformed or incomplete breakdowns", async () => {
  const valid = correction([correctionItem("Sandwich", "1 sandwich", 350, 25, 12, 35)]);
  for (const invalid of [
    { ...valid, calories: -1 },
    { ...valid, name: "" },
    { ...valid, portionLabel: "" },
    { ...valid, items: [{ ...valid.items[0], fat: -2 }] },
    { ...valid, items: [{ ...valid.items[0], quantity: "" }] },
    { ...valid, items: [{ ...valid.items[0], carbohydrates: undefined }] },
    { ...valid, items: undefined },
  ]) {
    let calls = 0;
    await fixture(async () => { calls++; return complete(invalid); }, async (call) => {
      const response = await call("entry-correction", { entry: { name: "Sandwich" }, instruction: "on wheat instead" });
      assert.equal(response.status, 502);
      assert.equal((await response.json()).code, "invalid_ai_response");
      assert.equal(calls, 2);
    });
  }
});

test("empty correction instructions and invalid entries never call the model", async () => {
  let calls = 0;
  await fixture(async () => { calls++; return complete({}); }, async (call) => {
    for (const body of [
      { entry: { name: "Sandwich" }, instruction: " \n " },
      { instruction: "use wheat bread" },
      { entry: [], instruction: "use wheat bread" },
      { entry: "sandwich", instruction: "use wheat bread" },
    ]) {
      assert.equal((await call("entry-correction", body)).status, 400);
    }
    assert.equal(calls, 0);
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
