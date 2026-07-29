import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Plus } from "lucide-react";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/faq")({
  head: () => ({
    meta: [
      { title: "FAQ | Sizing, Shipping & Returns — VEXA" },
      {
        name: "description",
        content:
          "Answers on VEXA sizing, fabric care, delivery times, cash on delivery and our 30-day return policy.",
      },
      { property: "og:title", content: "VEXA FAQ" },
      {
        property: "og:description",
        content: "Sizing, shipping, payment and returns — everything about ordering from VEXA.",
      },
    ],
  }),
  component: Faq,
});

const faqs = [
  {
    q: "How does the oversized fit run?",
    a: "Our oversized cut runs one size relaxed. If you're between sizes or prefer a classic fit, size down. Every product page lists chest and length in inches.",
  },
  {
    q: "What fabric do you use?",
    a: "240 GSM combed long-staple cotton, bio-washed for softness and pre-shrunk so it holds its shape after repeated washes.",
  },
  {
    q: "How long does delivery take?",
    a: "Orders dispatch within 24 hours. Metro cities receive in 2–3 days, rest of India in 4–6 days. Free shipping over ₹1999.",
  },
  {
    q: "Do you offer cash on delivery?",
    a: "Yes. COD is available across 22,000+ pin codes in India, with a small ₹49 handling fee.",
  },
  {
    q: "What is your return policy?",
    a: "30 days from delivery on unworn items with tags intact. Pickup is free and refunds are processed within 5 working days.",
  },
  {
    q: "How should I care for my tee?",
    a: "Machine wash cold, inside out, with similar colours. Tumble dry low or line dry. Do not bleach; iron on medium if needed.",
  },
  {
    q: "Do you restock limited drops?",
    a: "Limited colourways are produced once. Join the newsletter or create an account to get first access to the next drop.",
  },
];

function Faq() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section className="mx-auto max-w-3xl px-5 py-16">
      <Reveal className="text-center">
        <p className="text-[10px] uppercase tracking-[0.3em] text-gold">Good to know</p>
        <h1 className="mt-4 font-display text-4xl sm:text-5xl">FAQ</h1>
        <div className="hairline mx-auto mt-6 w-40" />
      </Reveal>

      <div className="mt-14 space-y-4">
        {faqs.map((f, i) => {
          const isOpen = open === i;
          return (
            <Reveal key={f.q} delay={i * 70}>
              <div
                className={`overflow-hidden rounded-sm border bg-card transition-colors duration-500 ${
                  isOpen ? "border-gold" : "border-border"
                }`}
              >
                <button
                  onClick={() => setOpen(isOpen ? null : i)}
                  className="flex w-full items-center justify-between gap-6 px-6 py-5 text-left"
                >
                  <span className="font-display text-base sm:text-lg">{f.q}</span>
                  <Plus
                    className={`size-5 shrink-0 text-gold transition-transform duration-500 ${
                      isOpen ? "rotate-45" : ""
                    }`}
                  />
                </button>
                <div
                  className={`grid transition-all duration-500 ${
                    isOpen ? "grid-rows-[1fr]" : "grid-rows-[0fr]"
                  }`}
                >
                  <div className="overflow-hidden">
                    <p className="px-6 pb-6 text-sm leading-relaxed text-muted-foreground">
                      {f.a}
                    </p>
                  </div>
                </div>
              </div>
            </Reveal>
          );
        })}
      </div>
    </section>
  );
}
