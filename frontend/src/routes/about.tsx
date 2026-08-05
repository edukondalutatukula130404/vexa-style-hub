import heroImg from "@/assets/hero.jpg";
import { Reveal } from "@/components/Reveal";
import { ShieldCheck, Award, Leaf, Feather, Star } from "lucide-react";

const stats = [
  { k: "240 GSM", l: "Heavyweight combed cotton" },
  { k: "68,000+", l: "Tees crafted & delivered" },
  { k: "4.95 / 5", l: "Customer satisfaction rating" },
  { k: "30 Days", l: "No-questions return guarantee" },
];

const pillars = [
  {
    icon: Feather,
    t: "Long-Staple Combed Cotton",
    d: "Sourced directly from certified Indian textile mills. The long cotton fibers provide exceptional softness, zero pilling, and enduring fabric integrity.",
  },
  {
    icon: Award,
    t: "Drop-Shoulder Silhouette",
    d: "Patterns sculpted specifically for an effortless modern drape. Boxy, structural, and perfectly proportioned across six calibrated sizes.",
  },
  {
    icon: Leaf,
    t: "Zero-Shrinkage Bio-Wash",
    d: "Pre-treated with organic enzyme washes to neutralize shrinkage and ensure color richness wash after wash, year after year.",
  },
  {
    icon: ShieldCheck,
    t: "Twin-Needle Collar Lock",
    d: "Ribbed collar reinforced with internal herringbone neck tape so your neckband never sags or bacon-ribs.",
  },
];

const reviews = [
  {
    author: "Kabir Mehta",
    role: "Verified Purchaser",
    quote: "The weight and drape on the Gold-Embroidered Tee are unreal. Easily competes with luxury designer brands at 4x the price.",
  },
  {
    author: "Rohan Kapoor",
    role: "Fashion Editor, TrendReport",
    quote: "VEXA has mastered the balance between structured heavyweight cotton and breathable comfort. The collar tension is perfect.",
  },
  {
    author: "Ananya Desai",
    role: "Verified Purchaser",
    quote: "I’ve washed my Obsidian Black tee 15 times and it still looks and feels brand new. No fading, no misshaping.",
  },
];

export function About() {
  return (
    <>
      {/* HERO SECTION */}
      <section className="relative overflow-hidden border-b border-border bg-background">
        <div className="relative mx-auto max-w-4xl px-5 py-24 text-center">
          <Reveal>
            <p className="text-[10px] uppercase tracking-[0.35em] text-gold font-semibold">Est. 2024 • Bengaluru, India</p>
            <h1 className="mt-5 font-display text-4xl sm:text-6xl">
              We build the <span className="text-gold-gradient">definitive tee</span>
            </h1>
            <p className="mx-auto mt-6 max-w-2xl text-base leading-relaxed text-muted-foreground">
              VEXA was born out of frustration with flimsy t-shirts that lose shape after three washes.
              We spent two years collaborating with master weavers to engineer a heavyweight cotton fabric
              that delivers timeless structure, plush comfort, and unwavering durability.
            </p>
          </Reveal>
        </div>
      </section>

      {/* STATS HIGHLIGHT */}
      <section className="mx-auto max-w-7xl px-5 py-20">
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4 items-stretch">
          {stats.map((s, i) => (
            <Reveal key={s.l} delay={i * 100} className="h-full w-full flex flex-col">
              <div className="flex h-full min-h-[140px] w-full flex-col items-center justify-center rounded-xl border border-border bg-card p-6 sm:p-8 text-center transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
                <p className="font-display text-3xl font-bold text-gold-gradient">{s.k}</p>
                <p className="mt-3 text-[11px] uppercase tracking-[0.22em] text-muted-foreground font-medium">
                  {s.l}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* CRAFT PILLARS */}
      <section className="mx-auto max-w-7xl px-5 pb-24">
        <Reveal className="text-center">
          <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Obsessive Craftsmanship</p>
          <h2 className="mt-3 font-display text-3xl sm:text-4xl">Built to Outlast Trends</h2>
          <div className="hairline mx-auto mt-6 w-44" />
        </Reveal>

        <div className="mt-14 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {pillars.map((p, i) => (
            <Reveal key={p.t} delay={i * 100}>
              <div className="group h-full rounded-xl border border-border bg-card p-8 transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
                <div className="flex size-12 items-center justify-center rounded-full border border-gold/40 text-gold transition-transform duration-500 group-hover:scale-110">
                  <p.icon className="size-6" />
                </div>
                <h3 className="mt-6 font-display text-lg font-semibold text-foreground">{p.t}</h3>
                <p className="mt-3 text-xs leading-relaxed text-muted-foreground">{p.d}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* TESTIMONIALS */}
      <section className="border-t border-border bg-surface/40 py-24">
        <div className="mx-auto max-w-7xl px-5">
          <Reveal className="text-center">
            <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Community Voices</p>
            <h2 className="mt-3 font-display text-3xl sm:text-4xl">Trusted by Collectors</h2>
            <div className="hairline mx-auto mt-6 w-40" />
          </Reveal>

          <div className="mt-14 grid gap-8 md:grid-cols-3">
            {reviews.map((r, i) => (
              <Reveal key={r.author} delay={i * 120}>
                <div className="h-full rounded-xl border border-border bg-card p-8 shadow-sm transition-all duration-500 hover:border-gold">
                  <div className="flex gap-1 text-gold">
                    {Array.from({ length: 5 }).map((_, idx) => (
                      <Star key={idx} className="size-4 fill-current" />
                    ))}
                  </div>
                  <p className="mt-6 text-sm leading-relaxed text-muted-foreground italic">"{r.quote}"</p>
                  <div className="mt-8 border-t border-border/60 pt-4">
                    <p className="font-display text-sm font-semibold text-foreground">{r.author}</p>
                    <p className="text-[10px] uppercase tracking-wider text-gold">{r.role}</p>
                  </div>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
