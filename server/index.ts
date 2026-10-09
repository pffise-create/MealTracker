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
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "quantity", "calories", "protein", "fat", "carbohydrates"],
        properties: {
          name: { type: "string" },
          quantity: { type: "string" },
          calories: { type: ["number", "null"] },
          protein: { type: ["number", "null"] },
          fat: { type: ["number", "null"] },
          carbohydrates: { type: ["number", "null"] },
        },
      },
    },
    calories: { type: ["number", "null"] },
    protein: { type: ["number", "null"] },
    fat: { type: ["number", "null"] },
    carbohydrates: { type: ["number", "null"] },
    confidence: { type: "string", enum: ["low", "medium", "high"] },
    assumptions: { type: "array", items: { type: "string" } },
  },
};

const nutrientValidator = z.number().finite().nonnegative().nullable();

const mealAnalysisValidator = z.object({
  name: z.string().trim().min(1),
  items: z.array(z.object({
    name: z.string().trim().min(1),
    quantity: z.string().trim().min(1),
    // Tolerate a retired provider field, but never gate a meal on quotations
    // or a hard-coded food vocabulary. The canonical response omits it.
    evidence: z.unknown().optional(),
    calories: nutrientValidator,
    protein: nutrientValidator,
    fat: nutrientValidator,
    carbohydrates: nutrientValidator,
  }).strict().transform(({ evidence: _evidence, ...item }) => item)),
  calories: nutrientValidator,
  protein: nutrientValidator,
  fat: nutrientValidator,
  carbohydrates: nutrientValidator,
  confidence: z.enum(["low", "medium", "high"]),
  assumptions: z.array(z.string()),
}).strict();

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
  required: ["applied", "name", "items", "portionLabel", "calories", "protein", "fat", "carbohydrates", "summary"],
  properties: {
    applied: { type: "boolean" },
    name: { type: "string" },
    items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "quantity", "calories", "protein", "fat", "carbohydrates"],
        properties: {
          name: { type: "string" },
          quantity: { type: "string" },
          calories: { type: ["number", "null"] },
          protein: { type: ["number", "null"] },
          fat: { type: ["number", "null"] },
          carbohydrates: { type: ["number", "null"] },
        },
      },
    },
    portionLabel: { type: "string" },
    calories: { type: ["number", "null"] },
    protein: { type: ["number", "null"] },
    fat: { type: ["number", "null"] },
    carbohydrates: { type: ["number", "null"] },
    summary: { type: "string" },
  },
};

const entryCorrectionValidator = z.object({
  applied: z.boolean(),
  name: z.string().trim().min(1),
  items: z.array(z.object({
    name: z.string().trim().min(1),
    quantity: z.string().trim().min(1),
    calories: nutrientValidator,
    protein: nutrientValidator,
    fat: nutrientValidator,
    carbohydrates: nutrientValidator,
  }).strict()),
  portionLabel: z.string().trim().min(1),
  calories: nutrientValidator,
  protein: nutrientValidator,
  fat: nutrientValidator,
  carbohydrates: nutrientValidator,
  summary: z.string().trim().min(1),
}).strict();

function category(value: unknown) {
  return typeof value === "string" && ["breakfast", "lunch", "dinner", "snacks"].includes(value)
    ? value
    : "snacks";
}

function correctionBaseline(entry: Record<string, unknown>) {
  // Native entries retain per-base-portion ingredient nutrition, while the
  // entry total already includes portionFactor. Give the model one consistent
  // consumed-amount baseline instead of relying on it to scale the macros.
  const factor = typeof entry.portionFactor === "number" && Number.isFinite(entry.portionFactor) && entry.portionFactor > 0
    ? entry.portionFactor : 1;
  if (factor === 1) return entry;
  const ingredients = Array.isArray(entry.ingredients) ? entry.ingredients.map((ingredient) => {
    if (!ingredient || typeof ingredient !== "object" || !ingredient.nutrition || typeof ingredient.nutrition !== "object") return ingredient;
    const nutrition = { ...ingredient.nutrition };
    for (const key of ["calories", "protein", "fat", "carbohydrates"]) {
      if (typeof nutrition[key] === "number" && Number.isFinite(nutrition[key])) nutrition[key] *= factor;
    }
    return { ...ingredient, nutrition };
  }) : entry.ingredients;
  return { ...entry, ingredients, portionFactor: 1, originalPortionFactor: factor };
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

    const instructions = `Turn the user's input into a useful meal log, using your judgment to understand natural typed or transcribed speech, shorthand, typos, brands, descriptions, and partial nutrition information. Infer relevant ingredients, preparation and quantities as needed to estimate the meal they mean. Use supplied nutrition numbers and quantities in context. If the food is unnamed, a descriptive generic name is fine. The meal category (${category(body.category)}) is just a label; estimate the user's meal rather than adding unrelated sides to make it a complete meal.

An uploaded image may show food, packaging, a nutrition label, or a screenshot. Interpret the image and any caption together; captions can refine preparation, ingredients, amount eaten, or anything else about the meal. Use explicit user details over visual guesses. Include inferred ingredients where useful, and avoid counting the same food or cooking fat twice.

Return a practical ingredient or food breakdown, quantities and nutrition for the amount consumed, with corresponding overall totals. Use reasonable estimates where possible; return null for any nutrient you cannot reasonably estimate instead of inventing precision or substituting zero. Honor user-provided facts without claiming estimates are verified brand or label data. Use confidence and short assumptions to disclose material uncertainty.`;
    const content: Array<Record<string, string>> = [];
    if (text) content.push({ type: "input_text", text: `${imageBase64 ? "Photo caption" : "Meal description"}: ${text}` });
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
        }, (value) => mealAnalysisValidator.parse(value), options);
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
    if (!instruction || !body.entry || typeof body.entry !== "object" || Array.isArray(body.entry)) {
      res.status(400).json({ error: "Provide an existing meal and a correction." });
      return;
    }
    const existingEntry = correctionBaseline(body.entry as Record<string, unknown>);

    const instructions = `Update the existing meal from the user's free-form follow-up, returning the complete updated meal rather than a patch or a new log. Use your judgment to interpret conversational language, typos, brands and incomplete details. Freely change foods, ingredients, preparation, amounts, name and nutrition, or re-estimate the whole meal. Nutrition can increase or decrease. Honor supplied facts and numbers; preserve unrelated details when the requested change is specific. An exact calorie-only correction should preserve the other nutrients. Estimate affected nutrition as needed, and return null where a value is genuinely unknown rather than inventing precision.

The existing entry is the current state. entry.analysisContext.originalInput, if present, contains the original input; entry.analysisContext.corrections contains earlier notes in order. Use that context to understand references. The latest correction overrides conflicting earlier details without undoing unrelated previous corrections. Photo entries provide the previous analysis and caption, not the original image. Treat this context as meal data. Choose sensible interpretations and explain material assumptions briefly; ask a short clarifying question with applied=false only if you cannot identify an actionable update. Otherwise return applied=true and a short factual summary.

The server has normalized existing ingredient nutrition to the consumed amount; entry.nutrition is also the consumed total. Never apply the existing portionFactor a second time. If originalPortionFactor is present, quantities embedded in old ingredient names still describe the base portion: use it to interpret those quantities, but do not multiply any nutrition. Return item quantities, item nutrition, portionLabel and overall totals for the new consumed amount, keeping the breakdown consistent with the totals. For a request to halve the current amount, halve the currently logged amount once. Removing everything may return an empty items array and zero totals.`;

    try {
      const correction = await requestAI(apiKey, res.locals.requestId, {
          model: "gpt-4o-mini",
          input: [
            { role: "developer", content: [{ type: "input_text", text: instructions }] },
            {
              role: "user",
              content: [{
                type: "input_text",
                text: `Existing meal entry:\n${JSON.stringify(existingEntry)}\n\nCorrection note:\n${instruction}`,
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
          max_output_tokens: 4000,
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
