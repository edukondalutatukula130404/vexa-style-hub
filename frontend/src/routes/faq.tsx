import { createFileRoute } from "@tanstack/react-router";
import { useState, useMemo } from "react";
import { Plus, Search, HelpCircle, MessageCircle, Truck, RefreshCw, ShieldCheck } from "lucide-react";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/faq")({
  head: () => ({
    meta: [
      { title: "FAQ | Sizing, Shipping & Returns — VEXA" },
      {
        name: "description",
        content:
          "Search VEXA FAQs for details on 240 GSM cotton care, oversized fit sizing, 24-hour dispatch, Cash on Delivery, and our 30-day hassle-free return policy.",
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

type FAQItem = {
  category: "Sizing & Fit" | "Orders & Shipping" | "Payments & COD" | "Returns & Exchanges" | "Care & Quality";
  q: string;
  a: string;
};

const allFaqs: FAQItem[] = [
  {
    category: "Sizing & Fit",
    q: "How does the oversized fit run compared to standard t-shirts?",
    a: "Our oversized silhouette is engineered with a drop-shoulder cut and 2 extra inches in chest width for an intended relaxed drape. If you prefer a tailored or standard fit, we recommend ordering one size down from your usual size. Check our interactive Size Guide on any product page for exact measurements.",
  },
  {
    category: "Sizing & Fit",
    q: "Will the t-shirt shrink after washing?",
    a: "No. Every VEXA garment undergoes an intensive organic bio-wash and pre-shrinking process during fabric finishing. As long as you follow cold wash care instructions, shrinkage is under 1%.",
  },
  {
    category: "Orders & Shipping",
    q: "How fast will my order dispatch and arrive?",
    a: "Orders placed before 2:00 PM IST dispatch the same business day. Metro cities (Bengaluru, Mumbai, Delhi, Hyderabad, Chennai) receive delivery within 2–3 days. Tier 2/3 locations arrive in 4–6 business days. Express shipping is free on all orders over ₹1,999.",
  },
  {
    category: "Orders & Shipping",
    q: "Can I modify or cancel my order after placing it?",
    a: "Yes! You can modify size options or address details within 2 hours of order placement by contacting our WhatsApp concierge (+91 98765 43210) or emailing support@vexa.store.",
  },
  {
    category: "Payments & COD",
    q: "Do you offer Cash on Delivery (COD)?",
    a: "Yes. Cash on Delivery is supported across 22,000+ pin codes in India. A nominal ₹49 handling fee is applied at checkout to cover courier cash processing.",
  },
  {
    category: "Payments & COD",
    q: "What online payment methods are accepted?",
    a: "We accept all major UPI apps (GPay, PhonePe, Paytm, CRED), Credit/Debit Cards (Visa, MasterCard, Amex, RuPay), Net Banking across 50+ Indian banks, and Bajaj Finserv EMI.",
  },
  {
    category: "Returns & Exchanges",
    q: "What is your 30-Day Return & Exchange Policy?",
    a: "We offer 30-day hassle-free returns and exchanges from the date of delivery. Items must be unworn, unwashed, and in original packaging with tags attached. Pickup from your doorstep is completely free.",
  },
  {
    category: "Returns & Exchanges",
    q: "How quickly are refunds processed?",
    a: "Once our doorstep courier verifies the returned shipment, refunds are initiated within 24 hours back to your original payment method or as instant VEXA Store Credit.",
  },
  {
    category: "Care & Quality",
    q: "What is 240 GSM combed cotton?",
    a: "GSM stands for Grams per Square Meter. Standard t-shirts range between 140–180 GSM. Our 240 GSM heavy cotton provides plush weight, structured architectural drape, zero transparency, and exceptional longevity.",
  },
  {
    category: "Care & Quality",
    q: "How should I wash and care for my VEXA tee?",
    a: "Machine wash cold inside-out with similar colors using mild detergent. Line dry in shade or tumble dry low. Do not bleach or dry clean. Iron inside-out on medium heat if needed.",
  },
];

const categories = ["All", "Sizing & Fit", "Orders & Shipping", "Payments & COD", "Returns & Exchanges", "Care & Quality"] as const;

export function Faq() {
  const [open, setOpen] = useState<number | null>(0);
  const [searchQuery, setSearchQuery] = useState("");
  const [activeCategory, setActiveCategory] = useState<string>("All");

  const filteredFaqs = useMemo(() => {
    let result = allFaqs;
    if (activeCategory !== "All") {
      result = result.filter((f) => f.category === activeCategory);
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter((f) => f.q.toLowerCase().includes(q) || f.a.toLowerCase().includes(q));
    }
    return result;
  }, [activeCategory, searchQuery]);

  return (
    <section className="mx-auto max-w-4xl px-5 py-16">
      <Reveal className="text-center">
        <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-semibold">Help & Information Center</p>
        <h1 className="mt-4 font-display text-4xl sm:text-5xl">Frequently Asked Questions</h1>
        <div className="hairline mx-auto mt-6 w-40" />
        <p className="mx-auto mt-6 max-w-xl text-xs sm:text-sm text-muted-foreground leading-relaxed">
          Everything you need to know about our heavyweight fabric, sizing recommendations,
          dispatch timelines, and 30-day exchange guarantee.
        </p>
      </Reveal>

      {/* Live Search & Filter Bar */}
      <div className="mt-12 space-y-6">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search FAQs (e.g. sizing, wash care, return policy, delivery)..."
            className="w-full rounded-xl border border-border bg-card py-3.5 pl-11 pr-4 text-xs shadow-sm outline-none transition-colors focus:border-gold placeholder:text-muted-foreground/60"
          />
        </div>

        {/* Category Pills */}
        <div className="flex flex-wrap gap-2 justify-center">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => {
                setActiveCategory(cat);
                setOpen(null);
              }}
              className={`rounded-full px-5 py-2 text-[10px] uppercase tracking-[0.2em] font-medium transition-all duration-300 ${
                activeCategory === cat
                  ? "bg-gold text-primary-foreground shadow-goldy"
                  : "border border-border bg-card text-muted-foreground hover:border-gold hover:text-gold"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Accordion FAQ List */}
      <div className="mt-10 space-y-4">
        {filteredFaqs.length > 0 ? (
          filteredFaqs.map((f, i) => {
            const isOpen = open === i;
            return (
              <Reveal key={f.q} delay={i * 50}>
                <div
                  className={`overflow-hidden rounded-xl border bg-card transition-all duration-500 shadow-sm ${
                    isOpen ? "border-gold" : "border-border hover:border-gold/50"
                  }`}
                >
                  <button
                    onClick={() => setOpen(isOpen ? null : i)}
                    className="flex w-full items-center justify-between gap-6 px-6 py-5 text-left"
                  >
                    <div>
                      <span className="text-[9px] uppercase tracking-widest text-gold font-semibold block mb-1">
                        {f.category}
                      </span>
                      <span className="font-display text-base font-medium text-foreground sm:text-lg">{f.q}</span>
                    </div>
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
                    <div className="overflow-hidden border-t border-border/40">
                      <p className="px-6 py-5 text-xs sm:text-sm leading-relaxed text-muted-foreground">
                        {f.a}
                      </p>
                    </div>
                  </div>
                </div>
              </Reveal>
            );
          })
        ) : (
          <div className="py-12 text-center text-muted-foreground border border-dashed border-border rounded-xl">
            <HelpCircle className="mx-auto size-8 text-gold/60" />
            <p className="mt-3 font-display text-base">No matching questions found</p>
            <p className="mt-1 text-xs">Try searching for a different keyword or select another category.</p>
          </div>
        )}
      </div>

      {/* Direct Assistance CTA Banner */}
      <div className="mt-16 rounded-xl border border-gold/40 bg-surface/60 p-8 text-center shadow-sm">
        <h3 className="font-display text-xl font-semibold text-foreground">Still have questions?</h3>
        <p className="mt-2 text-xs text-muted-foreground">Our client concierge team is ready to assist you via instant WhatsApp or email.</p>
        <div className="mt-6 flex flex-wrap justify-center gap-4">
          <a
            href="https://wa.me/919876543210"
            target="_blank"
            rel="noreferrer"
            className="btn-gold hover:btn-gold-hover inline-flex items-center gap-2 rounded-sm px-6 py-3 text-xs font-bold"
          >
            <MessageCircle className="size-4" /> Chat on WhatsApp
          </a>
          <a
            href="mailto:support@vexa.store"
            className="btn-outline-gold inline-flex items-center gap-2 rounded-sm px-6 py-3 text-xs font-bold hover:bg-gold hover:text-primary-foreground"
          >
            Email Support
          </a>
        </div>
      </div>
    </section>
  );
}
