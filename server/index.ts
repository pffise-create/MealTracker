import express from "express";
import { createServer } from "http";
import path from "path";
import { fileURLToPath } from "url";
import { z } from "zod";
import { randomUUID } from "node:crypto";
import { AIError, requestAI, type AIOptions } from "./ai";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

type AnalysisRequest = {
  category?: unknown;
  text?: unknown;
  imageBase64?: unknown;
  mimeType?: unknown;
};

type RestaurantMenuRequest = {
  name?: unknown;
  subtitle?: unknown;
  latitude?: unknown;
  longitude?: unknown;
};

type EntryCorrectionRequest = {
  entry?: unknown;
  instruction?: unknown;
};

const nutritionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["name", "items", "calories", "protein", "fat", "carbohydrates", "confidence", "assumptions"],
  properties: {
    name: { type: "string" },
    items: {
      type: "array",
      minItems: 1,
      maxItems: 20,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "quantity", "evidence", "calories", "protein", "fat", "carbohydrates"],
        properties: {
          name: { type: "string" },
          quantity: { type: "string" },
          evidence: { type: "string" },
          calories: { type: "number" },
          protein: { type: "number" },
          fat: { type: "number" },
          carbohydrates: { type: "number" },
        },
      },
    },
    calories: { type: "number" },
    protein: { type: "number" },
    fat: { type: "number" },
    carbohydrates: { type: "number" },
    confidence: { type: "string", enum: ["low", "medium", "high"] },
    assumptions: { type: "array", items: { type: "string" } },
  },
};

const mealAnalysisValidator = z.object({
  name: z.string().trim().min(1).max(120),
  items: z.array(z.object({
    name: z.string().trim().min(1).max(120),
    quantity: z.string().trim().min(1).max(80),
    evidence: z.string().trim().min(1).max(120),
    calories: z.number().finite().min(0).max(10_000),
    protein: z.number().finite().min(0).max(1_000),
    fat: z.number().finite().min(0).max(1_000),
    carbohydrates: z.number().finite().min(0).max(1_000),
  }).strict()).min(1).max(20),
  calories: z.number().finite().min(0).max(10_000),
  protein: z.number().finite().min(0).max(1_000),
  fat: z.number().finite().min(0).max(1_000),
  carbohydrates: z.number().finite().min(0).max(1_000),
  confidence: z.enum(["low", "medium", "high"]),
  assumptions: z.array(z.string().trim().min(1).max(180)).max(8),
}).strict();

type ValidatedMealAnalysis = z.infer<typeof mealAnalysisValidator>;

const restaurantMenuSchema = {
  type: "object",
  additionalProperties: false,
  required: ["found", "venueName", "sourceTitle", "sourceURL", "items"],
  properties: {
    found: { type: "boolean" },
    venueName: { type: "string" },
    sourceTitle: { type: "string" },
    sourceURL: { type: "string" },
    items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "description", "calories", "protein", "fat", "carbohydrates", "nutritionSource"],
        properties: {
          name: { type: "string" },
          description: { type: "string" },
          calories: { type: "number" },
          protein: { type: "number" },
          fat: { type: "number" },
          carbohydrates: { type: "number" },
          nutritionSource: { type: "string", enum: ["official", "estimated"] },
        },
      },
    },
  },
};

const restaurantMenuValidator = z.object({
  found: z.boolean(),
  venueName: z.string().trim().max(160),
  sourceTitle: z.string().trim().max(200),
  sourceURL: z.string().trim().max(2_000),
  items: z.array(z.object({
    name: z.string().trim().min(1).max(160),
    description: z.string().trim().max(500),
    calories: z.number().finite().min(0).max(10_000),
    protein: z.number().finite().min(0).max(1_000),
    fat: z.number().finite().min(0).max(1_000),
    carbohydrates: z.number().finite().min(0).max(1_000),
    nutritionSource: z.enum(["official", "estimated"]),
  }).strict()).max(40),
}).strict().superRefine((menu, context) => {
  if (!menu.found) return;
  if (menu.items.length === 0) {
    context.addIssue({ code: "custom", message: "A found menu must contain items", path: ["items"] });
  }
  try {
    const url = new URL(menu.sourceURL);
    if (url.protocol !== "https:") throw new Error("Source URL must use HTTPS");
  } catch {
    context.addIssue({ code: "custom", message: "A found menu must have a valid HTTPS source", path: ["sourceURL"] });
  }
});

const entryCorrectionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["applied", "calories", "protein", "fat", "carbohydrates", "summary"],
  properties: {
    applied: { type: "boolean" },
    calories: { type: ["number", "null"] },
    protein: { type: ["number", "null"] },
    fat: { type: ["number", "null"] },
    carbohydrates: { type: ["number", "null"] },
    summary: { type: "string" },
  },
};

const entryCorrectionValidator = z.object({
  applied: z.boolean(),
  calories: z.number().finite().min(0).max(10_000).nullable(),
  protein: z.number().finite().min(0).max(1_000).nullable(),
  fat: z.number().finite().min(0).max(1_000).nullable(),
  carbohydrates: z.number().finite().min(0).max(1_000).nullable(),
  summary: z.string().trim().min(1).max(200),
}).strict();

function normalizedEvidence(value: string) {
  return value.toLocaleLowerCase("en-US").replace(/\s+/g, " ").trim();
}

function hasGroundedTextItems(analysis: ValidatedMealAnalysis, description: string) {
  const source = normalizedEvidence(description);
  // Repeated foods and components can share a phrase. Require both a verbatim
  // phrase and a food-name link; merely citing "beer" cannot justify chicken.
  const components: Record<string, string[]> = {
    burger: ["bun", "bread", "beef", "patty", "lettuce", "tomato", "onion", "pickle", "cheese"],
    hamburger: ["bun", "bread", "beef", "patty", "lettuce", "tomato", "onion", "pickle"],
    cheeseburger: ["bun", "bread", "beef", "patty", "cheese", "lettuce", "tomato", "onion", "pickle"],
    quesadilla: ["tortilla", "cheese"],
    pizza: ["crust", "dough", "cheese", "tomato", "sauce"],
    steak: ["beef"],
  };
  const words = (value: string) => normalizedEvidence(value).match(new RegExp("[\\p{L}\\p{N}]+", "gu")) ?? [];
  const singular = (word: string) => word.endsWith("s") ? word.slice(0, -1) : word;
  const varieties: Record<string, string> = { lager: "beer", ale: "beer", cheddar: "cheese", mozzarella: "cheese" };
  const identity = (word: string) => varieties[singular(word)] ?? singular(word);
  // This is a bounded check for common unrelated foods, not a vocabulary of
  // all permitted adjectives. Unknown brand/preparation/type words must not
  // turn an otherwise grounded meal into an unavailable error.
  const knownFoods = new Set([
    ...Object.keys(components), ...Object.values(components).flat(),
    "beer", "chicken", "rice", "fries", "ham", "pork", "fish", "salmon",
    "pasta", "salad", "soup", "beans", "yogurt", "coffee",
  ].map(identity));
  const sourceWords = words(source);
  const generic = new Set(["a", "an", "the", "and", "with", "of", "in", "on", "for", "one", "two", "small", "large", "medium", "serving", "cup", "oz", "g", "grilled", "cooked", "fried", "fresh", "baked", "roasted", "steamed", "sliced", "shredded", "melted", "diced", "chopped", "flour"]);
  return analysis.items.every((item) => {
    const phrase = normalizedEvidence(item.evidence);
    if (!source.includes(phrase)) return false;
    const phraseWords = words(phrase);
    // Evidence is a complete word sequence, not a substring such as "ham"
    // extracted from "hamburger".
    if (!sourceWords.some((_, start) => phraseWords.every((word, offset) => sourceWords[start + offset] === word))) return false;
    const foodWords = (value: string[]) => value.filter((word) => !generic.has(word) && !/^\d+$/.test(word)).map(identity);
    const evidenceWords = foodWords(phraseWords);
    const supported = new Set(evidenceWords.flatMap((word) => [word, ...(components[word] ?? [])]));
    const itemWords = foodWords(words(item.name));
    // Retain a food-name anchor while allowing "white rice", "chicken breast",
    // brand spellings and varieties. Still reject recognizable unrelated foods
    // such as "cheese fries" for a quesadilla or "beer with chicken" for beer.
    return itemWords.some((word) => supported.has(word))
      && itemWords.every((word) => !knownFoods.has(word) || supported.has(word));
  });
}

function category(value: unknown) {
  return typeof value === "string" && ["breakfast", "lunch", "dinner", "snacks"].includes(value)
    ? value
    : "snacks";
}

export function createApp(options: AIOptions = {}) {
  const app = express();

  app.use((req, res, next) => {
    const startedAt = Date.now();
    const requestId = randomUUID();
    res.locals.requestId = requestId;
    res.set("X-Request-ID", requestId);
    const json = res.json.bind(res);
    res.json = (body) => {
      if (body && typeof body.error === "string") {
        const defaults: Record<number, string> = { 400: "invalid_request", 401: "unauthorized", 503: "not_configured" };
        body = { ...body, code: body.code ?? defaults[res.statusCode] ?? "upstream_unavailable", requestId };
        res.locals.errorCode = body.code;
      }
      return json(body);
    };
    res.on("finish", () => {
      if (!req.path.startsWith("/api/")) return;
      // Keep enough operational detail to diagnose failed mobile calls without
      // recording meal text, photos, credentials, or model output.
      console.info(JSON.stringify({
        event: "api_request",
        route: req.route?.path ?? "unmatched",
        requestId,
        code: res.locals.errorCode,
        status: res.statusCode,
        durationMs: Date.now() - startedAt,
      }));
    });
    next();
  });
  app.use(express.json({ limit: "12mb" }));
  app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    // Body-parser's default HTML error can echo fragments of private input.
    const status = (error as { status?: number })?.status === 413 ? 413 : 400;
    res.status(status).json({ error: status === 413 ? "The request is too large." : "Provide a valid JSON request.", code: "invalid_request" });
  });
  app.use((req, res, next) => {
    if (req.method === "POST" && req.path.startsWith("/api/") && (!req.body || typeof req.body !== "object" || Array.isArray(req.body))) {
      res.status(400).json({ error: "Provide a valid JSON request.", code: "invalid_request" });
      return;
    }
    next();
  });

  app.post("/api/meal-analysis", async (req, res) => {
    const apiKey = process.env.OPENAI_API_KEY;
    const backendToken = process.env.MEALTRACKER_BACKEND_TOKEN;
    if (!apiKey || !backendToken) {
      res.status(503).json({ error: "Meal analysis is not configured on this server." });
      return;
    }
    if (req.get("Authorization") !== `Bearer ${backendToken}`) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    const body = req.body as AnalysisRequest;
    const text = typeof body.text === "string" ? body.text.trim() : "";
    const imageBase64 = typeof body.imageBase64 === "string" ? body.imageBase64 : "";
    const mimeType = body.mimeType === "image/png" || body.mimeType === "image/jpeg" ? body.mimeType : "image/jpeg";
    if (!text && !imageBase64) {
      res.status(400).json({ error: "Provide a meal description or photo." });
      return;
    }

    const instructions = `Estimate nutrition only for foods and drinks explicitly supplied by the user. The meal category (${category(body.category)}) is labeling metadata, never evidence of additional food. Do not complete a meal, add typical sides, recommend pairings, or invent foods that were not named or visible. Prefer one item per named food or composite dish (for example, one steak quesadilla). You may infer a reasonable quantity or preparation only for an item that is actually present in the input. Never return an empty items array: every non-empty text description must produce at least one item. For every text-described item, set evidence to the shortest exact contiguous phrase from the meal description that supports that item. Repeated foods or constituent ingredients of the same named dish may share evidence, but never use it to justify an unrelated side. Include the original food or dish name in the item name. For image-only items, set evidence to "visible in image". If the description is "a beer", return exactly one beer item. Name the result from the supplied items rather than using a generic category name. Calculate item macros and ensure the top-level totals equal their sum. Use non-negative finite numbers and keep assumptions short and material.`;
    const content: Array<Record<string, string>> = [];
    if (text) content.push({ type: "input_text", text: `Meal description: ${text}` });
    if (imageBase64) content.push({ type: "input_image", image_url: `data:${mimeType};base64,${imageBase64}` });

    try {
      const analysis = await requestAI(apiKey, res.locals.requestId, {
          model: "gpt-4o-mini",
          input: [
            { role: "developer", content: [{ type: "input_text", text: instructions }] },
            { role: "user", content },
          ],
          text: {
            format: {
              type: "json_schema",
              name: "meal_nutrition",
              strict: true,
              schema: nutritionSchema,
            },
          },
          max_output_tokens: 4_096,
          temperature: 0.2,
          store: false,
        }, (value) => {
          const analysis = mealAnalysisValidator.parse(value);
          const textItems = imageBase64 ? analysis.items.filter((item) => normalizedEvidence(item.evidence) !== "visible in image") : analysis.items;
          if (text && !hasGroundedTextItems({ ...analysis, items: textItems }, text)) {
            throw new AIError("ungrounded_ai_response", 502, true);
          }
          return analysis;
        }, options);
      const confidence = analysis.confidence;
      res.json({ analysis, provenance: `AI estimate • ${confidence} confidence — review and edit if needed.` });
    } catch (error) {
      const failure = error instanceof AIError ? error : new AIError("invalid_ai_response");
      res.status(failure.status).json({ error: "Meal analysis is temporarily unavailable.", code: failure.code });
    }
  });

  app.post("/api/entry-correction", async (req, res) => {
    const apiKey = process.env.OPENAI_API_KEY;
    const backendToken = process.env.MEALTRACKER_BACKEND_TOKEN;
    if (!apiKey || !backendToken) {
      res.status(503).json({ error: "AI corrections are not configured on this server." });
      return;
    }
    if (req.get("Authorization") !== `Bearer ${backendToken}`) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    const body = req.body as EntryCorrectionRequest;
    const instruction = typeof body.instruction === "string" ? body.instruction.trim() : "";
    if (!instruction || !body.entry || typeof body.entry !== "object") {
      res.status(400).json({ error: "Provide an existing meal and a correction." });
      return;
    }

    const instructions = `You correct one existing meal log from the user's short note. The supplied existing entry is the authoritative baseline; its nutrition object contains the existing values. Apply only a change that is clearly stated or unambiguously implied by the note. Preserve every nutrient that the note does not change. A missing or null nutrient is unknown: return null for it unless the note explicitly supplies its value. Never substitute zero or an estimate for an unknown value. If the user states an exact calorie count, return that exact calories value. If the correction cannot be applied safely, return applied=false and return the baseline nutrition unchanged. Do not add foods, remove foods, rename the meal, or estimate new nutrition. summary must be a short, factual explanation of the correction or why no change was made.`;

    try {
      const correction = await requestAI(apiKey, res.locals.requestId, {
          model: "gpt-4o-mini",
          input: [
            { role: "developer", content: [{ type: "input_text", text: instructions }] },
            {
              role: "user",
              content: [{
                type: "input_text",
                text: `Existing meal entry:\n${JSON.stringify(body.entry)}\n\nCorrection note:\n${instruction}`,
              }],
            },
          ],
          text: {
            format: {
              type: "json_schema",
              name: "meal_entry_correction",
              strict: true,
              schema: entryCorrectionSchema,
            },
          },
          max_output_tokens: 800,
          temperature: 0,
          store: false,
        }, (value) => entryCorrectionValidator.parse(value), options);
      res.json({ correction });
    } catch (error) {
      const failure = error instanceof AIError ? error : new AIError("invalid_ai_response");
      res.status(failure.status).json({ error: "AI correction is temporarily unavailable.", code: failure.code });
    }
  });

  app.post("/api/restaurant-menu", async (req, res) => {
    const apiKey = process.env.OPENAI_API_KEY;
    const backendToken = process.env.MEALTRACKER_BACKEND_TOKEN;
    if (!apiKey || !backendToken) {
      res.status(503).json({ error: "Restaurant menu search is not configured on this server." });
      return;
    }
    if (req.get("Authorization") !== `Bearer ${backendToken}`) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    const body = req.body as RestaurantMenuRequest;
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const subtitle = typeof body.subtitle === "string" ? body.subtitle.trim() : "";
    const latitude = typeof body.latitude === "number" && Number.isFinite(body.latitude) ? body.latitude : undefined;
    const longitude = typeof body.longitude === "number" && Number.isFinite(body.longitude) ? body.longitude : undefined;
    if (!name) {
      res.status(400).json({ error: "Provide a restaurant name." });
      return;
    }

    const locationHint = [subtitle, latitude !== undefined && longitude !== undefined ? `${latitude}, ${longitude}` : ""]
      .filter(Boolean)
      .join("; ");
    const instructions = `Search the live web for the official menu of the restaurant the user supplies. Prefer the restaurant's own website; do not use search result snippets, review sites, social media, delivery marketplaces, or menu aggregators as the source. Open the official menu page and extract only items actually listed there. Return found=false with empty source fields and items when no trustworthy official menu page is available. Return at most 40 representative food and drink items, preserving their menu names and concise descriptions. If the official page publishes nutrition, copy it and set nutritionSource=official. Otherwise estimate one menu serving's calories, protein, fat, and carbohydrates from the listed description and set nutritionSource=estimated. Never present estimated nutrition as official. sourceURL must be the exact official page opened, not a search URL or homepage when a more specific menu page exists.`;

    try {
      const menu = await requestAI(apiKey, res.locals.requestId, {
          model: process.env.OPENAI_MENU_MODEL || "gpt-5-mini",
          tools: [{ type: "web_search" }],
          input: [
            { role: "developer", content: [{ type: "input_text", text: instructions }] },
            {
              role: "user",
              content: [{
                type: "input_text",
                text: `Restaurant: ${name}\nLocation hint: ${locationHint || "not supplied"}`,
              }],
            },
          ],
          text: {
            format: {
              type: "json_schema",
              name: "restaurant_menu",
              strict: true,
              schema: restaurantMenuSchema,
            },
          },
          max_output_tokens: 6_000,
          store: false,
        }, (value) => restaurantMenuValidator.parse(value), options);
      res.json({
        ...menu,
        retrievedAt: new Date().toISOString(),
      });
    } catch (error) {
      const failure = error instanceof AIError ? error : new AIError("invalid_ai_response");
      res.status(failure.status).json({ error: "Restaurant menu search is temporarily unavailable.", code: failure.code });
    }
  });

  // Serve static files from dist/public in production
  const staticPath =
    process.env.NODE_ENV === "production"
      ? path.resolve(__dirname, "public")
      : path.resolve(__dirname, "..", "dist", "public");

  app.use(express.static(staticPath));

  // Handle client-side routing - serve index.html for all routes
  app.get("*", (_req, res) => {
    res.sendFile(path.join(staticPath, "index.html"));
  });

  return app;
}

function startServer() {
  const server = createServer(createApp());
  const port = process.env.PORT || 3000;
  server.listen(port, () => {
    console.log(`Server running on http://localhost:${port}/`);
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) startServer();
