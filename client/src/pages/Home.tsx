/*
 * Phase 1 design reminder — Monochrome Editorial Instrument.
 * Keep hierarchy, predicted actions, neutral progress, and low-friction capture visible.
 * This page is intentionally grayscale and low fidelity until the wireframe is approved.
 */
import { useState } from "react";
import {
  ArrowLeft,
  BookOpen,
  Camera,
  Check,
  ChevronRight,
  CircleHelp,
  Clock3,
  Compass,
  Image as ImageIcon,
  MapPin,
  Mic,
  MoreHorizontal,
  Plus,
  RotateCcw,
  Search,
  Sparkles,
  Utensils,
  X,
} from "lucide-react";
import { toast } from "sonner";

const meals = [
  { name: "Salmon grain bowl", meta: "Your usual • 12:30 PM", kcal: "620 kcal", image: "/manus-storage/mealtrack-food-bowl_ab7a0551.png" },
  { name: "Avocado toast", meta: "Logged 4 times this month", kcal: "410 kcal", image: "/manus-storage/mealtrack-food-toast_871d3672.png" },
];

function Ring() {
  return (
    <div className="ring" aria-label="Two of four meal categories logged">
      <div className="ring-center"><strong>2 / 4</strong><span>logged</span></div>
    </div>
  );
}

function Sheet({ children, onClose, eyebrow }: { children: React.ReactNode; onClose: () => void; eyebrow: string }) {
  return <div className="sheet-backdrop" role="presentation" onClick={onClose}><section className="sheet" role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}><div className="sheet-handle" /><div className="sheet-head"><span className="eyebrow">{eyebrow}</span><button className="icon-button" onClick={onClose} aria-label="Close"><X size={18} /></button></div>{children}</section></div>;
}

function AppNav({ page, setPage }: { page: string; setPage: (p: string) => void }) {
  return <nav className="bottom-nav" aria-label="Primary navigation">
    {[{ id: "dashboard", icon: Utensils, label: "Today" }, { id: "history", icon: Clock3, label: "History" }, { id: "adventure", icon: Compass, label: "Adventure" }].map(({ id, icon: Icon, label }) => <button key={id} className={page === id ? "nav-item active" : "nav-item"} onClick={() => setPage(id)}><Icon size={18} /><span>{label}</span></button>)}
  </nav>;
}

export default function Home() {
  const [page, setPage] = useState("dashboard");
  const [sheet, setSheet] = useState<"meal" | "capture" | "end" | "restaurant" | null>(null);
  const [restaurant, setRestaurant] = useState(false);
  const [ingredients, setIngredients] = useState(["salmon", "rice", "greens", "berries"]);
  const [logged, setLogged] = useState(false);
  const [recovery, setRecovery] = useState(false);

  const logMeal = () => { setLogged(true); setSheet(null); toast.success("Logged — +1 consistency resource banked", { description: "You can edit this meal anytime." }); };
  const toggleIngredient = (name: string) => setIngredients((items) => items.includes(name) ? items.filter((i) => i !== name) : [...items, name]);

  return <div className="review-shell">
    <aside className="review-notes">
      <div className="note-brand"><img src="/manus-storage/mealtrack-mark_41ae0274.png" alt="" /><span>MEALTRACK<br /><small>PHASE 01 / WIREFRAME</small></span></div>
      <div className="note-rule" />
      <p className="eyebrow">Review canvas</p>
      <h1>Make the next log<br /><em>obvious.</em></h1>
      <p className="note-copy">A grayscale interaction study for a predictive meal-tracking app. The product rewards consistency, never dietary perfection.</p>
      <div className="annotation"><span>01</span><p>Primary action is predicted, prefilled, and one tap away.</p></div>
      <div className="annotation"><span>02</span><p>Progress describes the day; it does not grade it.</p></div>
      <div className="annotation"><span>03</span><p>Adventure resources persist independently from streaks.</p></div>
      <div className="review-status"><span className="status-dot" />Clickable prototype<br /><small>Try a predicted meal, then open the AI field.</small></div>
    </aside>

    <main className="phone-stage">
      <div className="phone-frame">
        <div className="status-bar"><span>9:41</span><span>▰ ◌ ▰</span></div>
        <header className="app-header"><div><span className="eyebrow">Wednesday, October 18</span><h2>{page === "history" ? "Your history" : page === "adventure" ? "Adventure" : restaurant ? "Dinner nearby" : "Good morning, Alex"}</h2></div><button className="avatar">AR</button></header>

        {page === "dashboard" && <>
          <section className="daily-brief">
            <div className="ring-wrap"><Ring /><div><span className="eyebrow">Daily log</span><h3>{logged ? "3 of 4 moments" : "2 of 4 moments"}</h3><p>{logged ? "Nice. One more later if it happens." : "No pressure — just keep the thread."}</p></div></div>
            <div className="meal-segments"><span className="done">Breakfast</span><span className="done">Lunch</span><span>Dinner</span><span>Snacks</span></div>
          </section>
          <section className="metrics-card"><div className="section-label"><span>Neutral snapshot</span><button onClick={() => toast("Macro targets are adjustable in settings.")}><CircleHelp size={14} /></button></div><div className="metric-row"><div><strong>1,240</strong><span>calories</span></div><div><strong>72g</strong><span>protein</span></div><div><strong>48g</strong><span>fat</span></div><div><strong>116g</strong><span>carbs</span></div></div><div className="metric-lines"><i style={{ width: "62%" }} /><i style={{ width: "48%" }} /><i style={{ width: "36%" }} /><i style={{ width: "55%" }} /></div></section>
          <section className="status-rail"><div><span className="eyebrow">Consistency</span><strong>7 day streak</strong><span className="muted">Keep showing up</span></div><div className="rail-divider" /><div><span className="eyebrow">Banked</span><strong>120 energy</strong><span className="muted">Play later <ChevronRight size={12} /></span></div></section>
          <section className="suggestions"><div className="section-label"><span>{restaurant ? "Likely at this place" : "You usually eat around now"}</span><button onClick={() => setRestaurant(!restaurant)}>{restaurant ? "Exit restaurant" : "Try restaurant mode"}</button></div>{restaurant && <div className="restaurant-strip"><MapPin size={14} /><span><strong>Juniper Kitchen</strong> · recognized nearby</span><button onClick={() => setSheet("restaurant")}>View context</button></div>}{(restaurant ? meals.slice().reverse() : meals).map((meal) => <button className="meal-card" key={meal.name} onClick={() => setSheet("meal")}><img src={meal.image} alt="" /><span className="meal-card-copy"><strong>{meal.name}</strong><small>{meal.meta}</small><small>{meal.kcal}</small></span><ChevronRight size={18} /></button>)}<button className="none-button" onClick={() => toast("Marked Dinner as Skipped / None")}>＋ Skipped / None</button></section>
          <button className="capture-bar" onClick={() => setSheet("capture")}><span className="capture-spark"><Sparkles size={15} /></span><span>What did you eat?</span><span className="capture-actions"><Mic size={16} /><Camera size={16} /></span></button>
        </>}

        {page === "history" && <section className="page-content"><div className="history-summary"><span className="eyebrow">October 2023</span><h3>Small actions, visible over time.</h3><p>Incomplete days can be recovered. Adventure energy stays banked.</p></div><div className="calendar"><div className="weekdays">{["M","T","W","T","F","S","S"].map((x, i) => <span key={i}>{x}</span>)}</div><div className="days">{Array.from({ length: 31 }, (_, i) => <button key={i} className={i < 7 ? "day done-day" : i === 17 ? "day today-day" : "day"} onClick={() => i === 17 && setRecovery(true)}>{i + 1}</button>)}</div></div><div className="history-item"><div className="history-icon"><Check size={16} /></div><div><strong>Oct 17 · Tuesday</strong><span>4 moments logged · 40 energy</span></div><ChevronRight size={16} /></div><div className="history-item"><div className="history-icon"><RotateCcw size={16} /></div><div><strong>Oct 16 · Monday</strong><span>3 moments · Recovery available</span></div><button onClick={() => setRecovery(true)}>Edit</button></div></section>}

        {page === "adventure" && <section className="page-content adventure-page"><div className="adventure-mark"><Compass size={34} /></div><span className="eyebrow">Optional layer</span><h3>Your resources are waiting.</h3><p>Logging earns energy for an AI-guided adventure you play when you want. Missing a day never takes it away.</p><div className="energy-box"><span>Banked adventure energy</span><strong>120</strong><small>+40 from yesterday</small></div><button className="primary-button" onClick={() => toast("Adventure preview coming in Phase 2")}>Enter adventure <ChevronRight size={16} /></button><button className="text-button" onClick={() => setPage("dashboard")}><ArrowLeft size={14} /> Back to today</button></section>}
        <AppNav page={page} setPage={setPage} />
      </div>
      <div className="stage-caption"><span>INTERACTION 01</span><span>IPHONE / 390 × 844</span></div>
    </main>

    {sheet === "meal" && <Sheet eyebrow="Predicted meal" onClose={() => setSheet(null)}><h3 className="sheet-title">Salmon grain bowl</h3><p className="sheet-subtitle">Preselected from your usual order.</p><div className="portion-row"><div><span className="eyebrow">Portion</span><strong>Full bowl</strong></div><span className="exact">2 cups</span><button className="mini-button">Change</button></div><div className="ingredient-list"><div className="section-label"><span>Likely ingredients</span><span className="muted">Tap to swap</span></div>{["salmon", "rice", "greens", "berries"].map((item) => <button key={item} className={ingredients.includes(item) ? "ingredient selected" : "ingredient"} onClick={() => toggleIngredient(item)}><span>{ingredients.includes(item) ? <Check size={14} /> : <Plus size={14} />}</span>{item}</button>)}<button className="swap-link" onClick={() => toggleIngredient("banana")}>+ swap berries for banana</button></div><div className="estimate"><span>Estimated nutrition</span><strong>620 kcal</strong><small>34g protein · 22g fat · 68g carbs</small></div><button className="primary-button" onClick={logMeal}>Log this meal <Check size={16} /></button><button className="text-button" onClick={() => setSheet(null)}>Cancel</button></Sheet>}
    {sheet === "capture" && <Sheet eyebrow="Quick capture" onClose={() => setSheet(null)}><h3 className="sheet-title">Use the easiest input.</h3><p className="sheet-subtitle">You can edit any estimate after it is logged.</p><div className="capture-grid"><button onClick={() => { setSheet(null); toast("Photo estimate logged — Edit or Undo from the confirmation."); }}><Camera size={22} /><strong>Take a photo</strong><small>Best estimate, no confirmation</small></button><button onClick={() => toast("Listening… say what you ate") }><Mic size={22} /><strong>Use your voice</strong><small>“Turkey sandwich…”</small></button><button onClick={() => toast("Photo library opened") }><ImageIcon size={22} /><strong>Choose a photo</strong><small>From your library</small></button><button onClick={() => toast("Text entry ready") }><Search size={22} /><strong>Type it in</strong><small>Search foods or meals</small></button></div></Sheet>}
    {sheet === "restaurant" && <Sheet eyebrow="Restaurant context" onClose={() => setSheet(null)}><div className="location-heading"><MapPin size={20} /><div><h3>Juniper Kitchen</h3><p>Recognized nearby · 6 previous visits</p></div></div><div className="menu-note"><Sparkles size={15} /><span>Reliable menu data found</span></div><button className="meal-card compact" onClick={() => { setSheet("meal"); setRestaurant(true); }}><div className="menu-placeholder"><Utensils size={18} /></div><span className="meal-card-copy"><strong>Harvest bowl</strong><small>Previously ordered · 540 kcal</small></span><ChevronRight size={18} /></button><button className="meal-card compact"><div className="menu-placeholder"><Utensils size={18} /></div><span className="meal-card-copy"><strong>View full menu</strong><small>Browse reliable menu items</small></span><ChevronRight size={18} /></button><div className="fallback"><span>No reliable data?</span><button onClick={() => setSheet("capture")}>Use photo, voice, or text</button></div></Sheet>}
    {recovery && <Sheet eyebrow="Streak recovery" onClose={() => setRecovery(false)}><div className="recovery-icon"><RotateCcw size={22} /></div><h3 className="sheet-title">Want to complete Monday?</h3><p className="sheet-subtitle">Your streak paused because the day was incomplete. Editing the prior day can restore it. Your 120 adventure energy is safe either way.</p><button className="primary-button" onClick={() => { setRecovery(false); toast.success("Monday completed — 7 day streak restored"); }}>Review Monday <ChevronRight size={16} /></button><button className="text-button" onClick={() => setRecovery(false)}>Not now</button></Sheet>}
  </div>;
}
