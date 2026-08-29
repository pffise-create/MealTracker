/*
 * Phase 2 design reminder — five visual directions, one unchanged MealTrack UX.
 * Compare hierarchy, predicted action clarity, nutrition neutrality, and native iPhone character.
 */
import { CSSProperties } from "react";
import { ArrowUpRight, Camera, Check, ChevronRight, CircleHelp, Image as ImageIcon, Mic, Moon, Plus, Send, Sparkles, Sun, Utensils } from "lucide-react";
import { toast } from "sonner";

const meals = [
  { name: "Salmon grain bowl", meta: "Your usual • 12:30 PM", kcal: "620 kcal", image: "/manus-storage/mealtrack-food-bowl_ab7a0551.png" },
  { name: "Avocado toast", meta: "Logged 4 times this month", kcal: "410 kcal", image: "/manus-storage/mealtrack-food-toast_871d3672.png" },
  { name: "Overnight oats", meta: "Often on busy mornings", kcal: "360 kcal" },
];

const directions = [
  { id: "01", name: "Warm Editorial", short: "Premium print utility", className: "warm-editorial", accent: "#B8664D", accentSoft: "#E9CFC3", bg: "#F4F0E8", ink: "#25231F", muted: "#766F66", line: "#D8D0C4", font: "Fraunces + DM Sans", icon: "Lucide", image: "User photos", character: "Tactile, composed, quietly encouraging.", tradeoff: "Warmth raises approachability, but the clay accent needs restraint to keep progress neutral." },
  { id: "02", name: "Mineral Calm", short: "Precision without pressure", className: "mineral-calm", accent: "#547A82", accentSoft: "#C9DCDE", bg: "#F7F8F6", ink: "#202525", muted: "#6E7A78", line: "#DDE3DF", font: "Plus Jakarta Sans", icon: "Phosphor", image: "Open Food Facts", character: "Credible, clear, reassuring.", tradeoff: "Strongest scanability, but risks feeling like generic clinical wellness software." },
  { id: "03", name: "Citrus Ledger", short: "A signal for the next action", className: "citrus-ledger", accent: "#E4A52D", accentSoft: "#F3E2AE", bg: "#FBFAF5", ink: "#20211E", muted: "#77736A", line: "#D9D6CB", font: "Space Grotesk + IBM Plex Sans", icon: "Tabler", image: "Generated overheads", character: "Focused, energetic, disciplined.", tradeoff: "The clearest action signal, but citrus must not become a reward-chasing color." },
  { id: "04", name: "Night Kitchen", short: "A late-evening companion", className: "night-kitchen", accent: "#D6A35D", accentSoft: "#5D4A32", bg: "#171917", ink: "#F2EEE4", muted: "#A4ABA1", line: "#394039", font: "Manrope + Instrument Serif", icon: "Lucide", image: "User / licensed photos", character: "Intimate, cinematic, low-light calm.", tradeoff: "Most distinctive at night, but dense macro data needs careful contrast." },
  { id: "05", name: "Coastal Utility", short: "A field guide for daily meals", className: "coastal-utility", accent: "#287A85", accentSoft: "#C5DEDA", bg: "#F1F5F2", ink: "#19323A", muted: "#718688", line: "#D2E0DE", font: "Public Sans + Newsreader", icon: "Radix", image: "Emoji / open illustrations", character: "Airy, optimistic, spacious.", tradeoff: "Most approachable, but softness can weaken the predicted action hierarchy." },
];

function MealThumb({ meal }: { meal: typeof meals[number] }) {
  return meal.image ? <img src={meal.image} alt="" /> : <span className="mini-thumb-placeholder"><Utensils size={13} /></span>;
}

function MiniRing() {
  return <div className="mini-ring"><div><strong>2/4</strong><small>logged</small></div></div>;
}

function MiniPhone({ direction }: { direction: typeof directions[number] }) {
  return <div className="mini-phone">
    <div className="mini-status"><span>9:41</span><span>▰ ◌ ▰</span></div>
    <div className="mini-header"><div><small>WEDNESDAY, OCTOBER 18</small><h3>Good morning, Alex</h3></div><span className="mini-avatar">AR</span></div>
    <div className="mini-log"><MiniRing /><div className="mini-log-copy"><small>DAILY LOG</small><strong>2 of 4 moments</strong><div className="mini-segments"><i /><i /><i /><i /></div><div className="mini-segment-labels"><span>Breakfast</span><span>Lunch</span><span>Dinner</span><span>Snacks</span></div></div></div>
    <div className="mini-metrics"><div className="mini-label">NEUTRAL SNAPSHOT <CircleHelp size={10} /></div><div className="mini-metric-row"><b>1,240<small>calories</small></b><b>72g<small>protein</small></b><b>48g<small>fat</small></b><b>116g<small>carbs</small></b></div></div>
    <div className="mini-suggestions"><div className="mini-label"><span>NEXT MEAL</span><u>Try restaurant mode</u></div>{meals.map((meal) => <button key={meal.name} onClick={() => toast(`${direction.name}: predicted meal selected`)}><MealThumb meal={meal} /><span><strong>{meal.name}</strong><small>{meal.meta}</small><small>{meal.kcal}</small></span><ChevronRight size={13} /></button>)}</div>
    <div className="mini-capture"><Sparkles size={13} /><span>What did you eat?</span><Mic size={12} /><Camera size={12} /></div>
    <div className="mini-nav"><b><Utensils size={13} />Today</b><span><Sun size={13} />History</span><span><Moon size={13} />Adventure</span></div>
  </div>;
}

function MiniDetailSheet({ direction }: { direction: typeof directions[number] }) {
  return <div className="detail-swatch">
    <div className="swatch-top"><span>MEAL DETAIL</span><button onClick={() => toast(`${direction.name}: detail sheet selected`)} aria-label="Open detail option"><ArrowUpRight size={14} /></button></div>
    <h3>Salmon grain bowl</h3>
    <p>Preselected from your usual order.</p>
    <div className="swatch-portion"><span><small>PORTION</small><strong>Full bowl</strong></span><b>2 cups</b><button>Change</button></div>
    <div className="swatch-ingredients"><small>LIKELY INGREDIENTS</small><div><button className="selected"><Check size={10} />salmon</button><button className="selected"><Check size={10} />rice</button><button className="selected"><Check size={10} />greens</button><button><Plus size={10} />berries</button></div></div>
    <div className="swatch-estimate"><span>Estimated nutrition</span><strong>620 kcal</strong></div>
    <button className="swatch-log" onClick={() => toast(`${direction.name}: Log action selected`)}>Log this meal <Check size={13} /></button>
  </div>;
}

function DirectionCard({ direction }: { direction: typeof directions[number] }) {
  const style = { "--accent": direction.accent, "--accent-soft": direction.accentSoft, "--direction-bg": direction.bg, "--direction-ink": direction.ink, "--direction-muted": direction.muted, "--direction-line": direction.line } as CSSProperties;
  return <article className={`direction-card ${direction.className}`} style={style}>
    <header className="direction-heading"><div><span className="direction-index">{direction.id}</span><h2>{direction.name}</h2><p>{direction.short}</p></div><button aria-label={`Select ${direction.name}`} onClick={() => toast(`${direction.name} selected for review`)}><ArrowUpRight size={17} /></button></header>
    <MiniPhone direction={direction} />
    <MiniDetailSheet direction={direction} />
    <div className="direction-meta"><div><span>FONT SYSTEM</span><strong>{direction.font}</strong></div><div><span>ICON SYSTEM</span><strong>{direction.icon}</strong></div><div><span>FOOD IMAGERY</span><strong>{direction.image}</strong></div></div>
    <p className="direction-character">{direction.character}</p>
    <p className="direction-tradeoff"><b>Tradeoff</b> {direction.tradeoff}</p>
  </article>;
}

export default function Home() {
  return <main className="phase2-board">
    <header className="phase2-header"><div className="phase2-brand"><img src="/manus-storage/mealtrack-mark_41ae0274.png" alt="" /><span>MEALTRACK<small>PHASE 02 / VISUAL EXPLORATION</small></span></div><div className="phase2-title"><span className="eyebrow">Five directions · same approved UX</span><h1>Make the next log<br /><em>feel like you.</em></h1><p>Dashboard and meal-detail comparisons for an adult, motivating, iPhone-native meal tracker. Every option keeps the prediction, neutral macro snapshot, direct capture, and one clear Log action unchanged.</p></div><div className="phase2-license"><span>ASSET SOURCES</span><strong>Fonts: Google Fonts / OFL</strong><strong>Icons: open-source sets</strong><strong>Food: user, open, or generated</strong></div></header>
    <section className="direction-rail" aria-label="Five visual design directions">{directions.map((direction) => <DirectionCard key={direction.id} direction={direction} />)}</section>
    <footer className="phase2-footer"><span>COMPARE ON THE SAME QUESTIONS</span><p>Which direction makes the predicted meal most obvious? Which keeps nutrition neutral? Which feels most adult and native to iPhone? Which gives imagery a useful recognition role without decorative noise?</p></footer>
  </main>;
}
