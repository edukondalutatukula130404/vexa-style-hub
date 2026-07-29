import { createFileRoute, Link } from "@tanstack/react-router";
import {
  Shirt,
  Wind,
  Sparkles,
  ShieldCheck,
  Truck,
  BadgeIndianRupee,
  MessageCircle,
  ArrowRight,
} from "lucide-react";
import heroImg from "@/assets/hero.jpg";
import { products, SIZES } from "@/lib/products";
import { ProductCard } from "@/components/ProductCard";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "VEXA | Premium Oversized T-Shirt Collection" },
      {
        name: "description",
        content:
          "Shop the VEXA premium t-shirt collection — oversized modern fit, soft breathable cotton, wrinkle resistant. Up to 30% off.",
      },
      { property: "og:title", content: "VEXA | Premium T-Shirt Collection" },
      {
        property: "og:description",
        content:
          "Premium cotton oversized t-shirts crafted for everyday confidence. Up to 30% off.",
      },
    ],
  }),
  component: Home,
});

const features = [
  { icon: Shirt, title: "Premium Cotton Fabric", text: "240 GSM combed long-staple cotton." },
  { icon: Sparkles, title: "Oversized Modern Fit", text: "Drop shoulder, sculpted drape." },
  { icon: Wind, title: "Soft & Breathable", text: "Bio-washed for all-day comfort." },
  { icon: ShieldCheck, title: "Wrinkle Resistant", text: "Holds its shape wash after wash." },
];

const services = [
  { icon: MessageCircle, title: "WhatsApp Order", text: "Order in one message" },
  { icon: Truck, title: "Fast Delivery", text: "2–4 day dispatch" },
  { icon: BadgeIndianRupee, title: "Cash on Delivery", text: "Pay when it arrives" },
  { icon: ShieldCheck, title: "Quality Guarantee", text: "30-day easy returns" },
];

function Home() {
  return (
    <>
      {/* HERO */}
      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute inset-0">
          <img
            src={heroImg}
            alt="VEXA premium oversized t-shirts on black marble pedestals"
            width={1600}
            height={1104}
            className="h-full w-full object-cover opacity-45"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-background/85 via-background/60 to-background" />
        </div>

        <div className="relative mx-auto grid max-w-7xl gap-10 px-5 py-24 lg:grid-cols-2 lg:py-32">
          <div className="animate-fade-up">
            <span className="inline-block rounded-full border border-gold/50 px-4 py-1.5 text-[10px] uppercase tracking-[0.3em] text-gold">
              Elevate your everyday style
            </span>
            <h1 className="mt-7 font-display text-5xl leading-[1.05] sm:text-6xl lg:text-7xl">
              Premium
              <br />
              <span className="text-gold-gradient">T-Shirt</span>
              <br />
              Collection
            </h1>
            <p className="mt-6 max-w-md text-base leading-relaxed text-muted-foreground">
              Engineered in heavyweight cotton, finished by hand, and cut for the
              modern oversized silhouette. This is VEXA — wear confidence, wear
              style.
            </p>

            <div className="mt-9 flex flex-wrap gap-4">
              <Link
                to="/products"
                className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-8 py-4 text-xs"
              >
                Shop the drop <ArrowRight className="size-4" />
              </Link>
              <Link
                to="/about"
                className="btn-outline-gold inline-flex items-center rounded-sm px-8 py-4 text-xs hover:bg-gold hover:text-primary-foreground"
              >
                Our story
              </Link>
            </div>

            <div className="mt-12">
              <p className="text-[10px] uppercase tracking-[0.3em] text-muted-foreground">
                Available sizes
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                {SIZES.map((s) => (
                  <span
                    key={s}
                    className="flex size-11 items-center justify-center rounded-sm border border-gold/40 text-xs tracking-widest text-gold transition-all duration-300 hover:-translate-y-1 hover:bg-gold hover:text-primary-foreground"
                  >
                    {s}
                  </span>
                ))}
              </div>
            </div>
          </div>

          <div className="relative flex items-center justify-center">
            <div className="animate-float relative flex size-56 items-center justify-center rounded-full border-2 border-gold/70 shadow-goldy lg:size-72">
              <div className="absolute inset-3 rounded-full border border-gold/30" />
              <div className="text-center">
                <p className="font-display text-6xl text-gold-gradient lg:text-7xl">30%</p>
                <p className="text-sm uppercase tracking-[0.4em] text-gold">Off</p>
              </div>
            </div>
          </div>
        </div>

        {/* marquee */}
        <div className="relative overflow-hidden border-y border-border py-4">
          <div className="animate-marquee flex w-max gap-12 whitespace-nowrap">
            {Array.from({ length: 2 }).map((_, r) => (
              <div key={r} className="flex gap-12">
                {[
                  "FREE SHIPPING OVER ₹1999",
                  "PREMIUM COTTON",
                  "OVERSIZED FIT",
                  "CASH ON DELIVERY",
                  "30-DAY RETURNS",
                  "LIMITED DROPS",
                ].map((t) => (
                  <span
                    key={t + r}
                    className="text-xs uppercase tracking-[0.3em] text-muted-foreground"
                  >
                    ✦ {t}
                  </span>
                ))}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FEATURES */}
      <section className="mx-auto max-w-7xl px-5 py-24">
        <Reveal className="text-center">
          <h2 className="font-display text-3xl sm:text-4xl">
            Crafted to the <span className="text-gold-gradient">last stitch</span>
          </h2>
          <div className="hairline mx-auto mt-6 w-48" />
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((f, i) => (
            <Reveal key={f.title} delay={i * 110}>
              <div className="group h-full rounded-sm border border-border bg-card p-8 transition-all duration-500 hover:-translate-y-2 hover:border-gold hover:shadow-goldy">
                <f.icon className="size-8 text-gold transition-transform duration-500 group-hover:scale-110" />
                <h3 className="mt-6 font-display text-lg">{f.title}</h3>
                <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                  {f.text}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* BESTSELLERS */}
      <section className="mx-auto max-w-7xl px-5 pb-24">
        <Reveal className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-[10px] uppercase tracking-[0.3em] text-gold">The collection</p>
            <h2 className="mt-3 font-display text-3xl sm:text-4xl">Bestsellers</h2>
          </div>
          <Link
            to="/products"
            className="inline-flex items-center gap-2 text-xs uppercase tracking-[0.2em] text-gold transition-transform hover:translate-x-1"
          >
            View all <ArrowRight className="size-4" />
          </Link>
        </Reveal>

        <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {products.slice(0, 3).map((p, i) => (
            <Reveal key={p.id} delay={i * 120}>
              <ProductCard product={p} />
            </Reveal>
          ))}
        </div>
      </section>

      {/* SERVICE BAR */}
      <section className="border-y border-border bg-surface/40">
        <div className="mx-auto grid max-w-7xl gap-8 px-5 py-14 sm:grid-cols-2 lg:grid-cols-4">
          {services.map((s, i) => (
            <Reveal key={s.title} delay={i * 90}>
              <div className="flex items-center gap-4">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-full border border-gold/50 text-gold">
                  <s.icon className="size-5" />
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.2em] text-foreground">
                    {s.title}
                  </p>
                  <p className="mt-1 text-sm text-muted-foreground">{s.text}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="mx-auto max-w-4xl px-5 py-24 text-center">
        <Reveal>
          <h2 className="font-display text-3xl sm:text-5xl">
            Join the <span className="text-gold-gradient">VEXA</span> circle
          </h2>
          <p className="mx-auto mt-5 max-w-xl text-muted-foreground">
            Create an account for early access to limited drops, member pricing and
            free express shipping.
          </p>
          <div className="mt-9 flex flex-wrap justify-center gap-4">
            <Link
              to="/register"
              className="btn-gold hover:btn-gold-hover rounded-sm px-8 py-4 text-xs"
            >
              Create account
            </Link>
            <Link
              to="/contact"
              className="btn-outline-gold rounded-sm px-8 py-4 text-xs hover:bg-gold hover:text-primary-foreground"
            >
              Talk to us
            </Link>
          </div>
        </Reveal>
      </section>
    </>
  );
}
