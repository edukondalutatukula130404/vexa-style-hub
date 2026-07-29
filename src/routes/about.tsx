import { createFileRoute } from "@tanstack/react-router";
import heroImg from "@/assets/hero.jpg";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/about")({
  head: () => ({
    meta: [
      { title: "About VEXA | Our Craft & Story" },
      {
        name: "description",
        content:
          "VEXA was built on one idea: a t-shirt should feel like an heirloom. Meet the craft, the mill and the makers.",
      },
      { property: "og:title", content: "About VEXA | Our Craft & Story" },
      {
        property: "og:description",
        content: "The mill, the makers and the standard behind every VEXA tee.",
      },
    ],
  }),
  component: About,
});

const stats = [
  { k: "240", l: "GSM cotton" },
  { k: "68k+", l: "Tees shipped" },
  { k: "4.9", l: "Average rating" },
  { k: "30d", l: "Easy returns" },
];

const steps = [
  { n: "01", t: "Sourcing", d: "Long-staple cotton from certified Indian mills, spun to a consistent 240 GSM." },
  { n: "02", t: "Cutting", d: "Drop-shoulder patterns graded across six sizes for a true oversized drape." },
  { n: "03", t: "Finishing", d: "Bio-wash, reinforced collar tape and twin-needle hems, inspected by hand." },
];

function About() {
  return (
    <>
      <section className="relative overflow-hidden border-b border-border">
        <img
          src={heroImg}
          alt="VEXA studio display of premium t-shirts"
          loading="lazy"
          width={1600}
          height={1104}
          className="absolute inset-0 h-full w-full object-cover opacity-25"
        />
        <div className="relative mx-auto max-w-4xl px-5 py-24 text-center">
          <Reveal>
            <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Est. 2024</p>
            <h1 className="mt-5 font-display text-4xl sm:text-6xl">
              We build the <span className="text-gold-gradient">perfect tee</span>
            </h1>
            <p className="mx-auto mt-6 max-w-2xl leading-relaxed text-muted-foreground">
              VEXA started with a frustration — every "premium" t-shirt lost its shape
              after five washes. So we spent two years with a single mill perfecting
              weight, drape and collar tension until the shirt outlived the trend.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-5 py-20">
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((s, i) => (
            <Reveal key={s.l} delay={i * 100}>
              <div className="rounded-sm border border-border bg-card p-8 text-center transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
                <p className="font-display text-4xl text-gold-gradient">{s.k}</p>
                <p className="mt-3 text-xs uppercase tracking-[0.22em] text-muted-foreground">
                  {s.l}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-5xl px-5 pb-24">
        <Reveal className="text-center">
          <h2 className="font-display text-3xl sm:text-4xl">How it's made</h2>
          <div className="hairline mx-auto mt-6 w-40" />
        </Reveal>

        <div className="mt-14 space-y-6">
          {steps.map((s, i) => (
            <Reveal key={s.n} delay={i * 120}>
              <div className="group flex flex-col gap-5 rounded-sm border border-border bg-card p-8 transition-all duration-500 hover:border-gold sm:flex-row sm:items-center">
                <span className="font-display text-4xl text-gold/50 transition-colors duration-500 group-hover:text-gold">
                  {s.n}
                </span>
                <div>
                  <h3 className="font-display text-xl">{s.t}</h3>
                  <p className="mt-2 leading-relaxed text-muted-foreground">{s.d}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>
    </>
  );
}
