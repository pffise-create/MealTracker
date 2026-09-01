import express from "express";
import { createServer } from "http";
import path from "path";
import { fileURLToPath } from "url";
import { z } from "zod";

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

function normalizedEvidence(value: string) {
  return value.toLocaleLowerCase("en-US").replace(/\s+/g, " ").trim();
}

function hasGroundedTextItems(analysis: ValidatedMealAnalysis, description: string) {
  const source = normalizedEvidence(description);
  const evidence = analysis.items.map((item) => normalizedEvidence(item.evidence));
  return evidence.every((phrase) => source.includes(phrase))
    && new Set(evidence).size === evidence.length;
}

function category(value: unknown) {
  return typeof value === "string" && ["breakfast", "lunch", "dinner", "snacks"].includes(value)
    ? value
    : "snacks";
}

function extractOutputText(payload: unknown): string | undefined {
  if (!payload || typeof payload !== "object") return undefined;
  const response = payload as {
    output_text?: unknown;
    output?: Array<{ content?: Array<{ type?: unknown; text?: unknown }> }>;
  };
  if (typeof response.output_text === "string") return response.output_text;
  for (const item of response.output ?? []) {
    for (const content of item.content ?? []) {
      if (content.type === "output_text" && typeof content.text === "string") return content.text;
    }
  }
  return undefined;
}

async function startServer() {
  const app = express();
  const server = createServer(app);

  app.use(express.json({ limit: "12mb" }));

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

    const instructions = `Estimate nutrition only for foods and drinks explicitly supplied by the user. The meal category (${category(body.category)}) is labeling metadata, never evidence of additional food. Do not complete a meal, add typical sides, recommend pairings, or invent foods that were not named or visible. You may infer a reasonable quantity or preparation only for an item that is actually present in the input. For every text-described item, set evidence to the shortest exact contiguous phrase from the meal description that supports that item; one evidence phrase may support only one item. For image-only items, set evidence to "visible in image". If the description is "a beer", return exactly one beer item. Name the result from the supplied items rather than using a generic category name. Calculate item macros and ensure the top-level totals equal their sum. Use non-negative finite numbers and keep assumptions short and material.`;
    const content: Array<Record<string, string>> = [];
    if (text) content.push({ type: "input_text", text: `Meal description: ${text}` });
    if (imageBase64) content.push({ type: "input_image", image_url: `data:${mimeType};base64,${imageBase64}` });

    try {
      const response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
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
          max_output_tokens: 600,
          temperature: 0.2,
          store: false,
        }),
      });
      if (!response.ok) {
        console.error("OpenAI meal analysis failed", response.status, await response.text());
        res.status(502).json({ error: "Meal analysis is temporarily unavailable." });
        return;
      }

      const outputText = extractOutputText(await response.json());
      if (!outputText) throw new Error("OpenAI returned no structured output");
      const analysis = mealAnalysisValidator.parse(JSON.parse(outputText));
      if (text && !hasGroundedTextItems(analysis, text)) {
        throw new Error("OpenAI returned meal items that were not grounded in the description");
      }
      const confidence = analysis.confidence;
      res.json({ analysis, provenance: `AI estimate • ${confidence} confidence — review and edit if needed.` });
    } catch (error) {
      console.error("Meal analysis request failed", error);
      res.status(502).json({ error: "Meal analysis is temporarily unavailable." });
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
      const response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
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
        }),
      });
      if (!response.ok) {
        console.error("OpenAI restaurant menu search failed", response.status, await response.text());
        res.status(502).json({ error: "Restaurant menu search is temporarily unavailable." });
        return;
      }

      const outputText = extractOutputText(await response.json());
      if (!outputText) throw new Error("OpenAI returned no restaurant menu output");
      const menu = restaurantMenuValidator.parse(JSON.parse(outputText));
      res.json({
        ...menu,
        retrievedAt: new Date().toISOString(),
      });
    } catch (error) {
      console.error("Restaurant menu search failed", error);
      res.status(502).json({ error: "Restaurant menu search is temporarily unavailable." });
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

  const port = process.env.PORT || 3000;

  server.listen(port, () => {
    console.log(`Server running on http://localhost:${port}/`);
  });
}

startServer().catch(console.error);
