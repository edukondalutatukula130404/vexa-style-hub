import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Mail, Phone, MapPin, Send, CheckCircle2 } from "lucide-react";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/contact")({
  head: () => ({
    meta: [
      { title: "Contact VEXA | Support & Wholesale" },
      {
        name: "description",
        content:
          "Reach the VEXA team for order support, sizing help, wholesale and collaborations. We reply within 24 hours.",
      },
      { property: "og:title", content: "Contact VEXA" },
      {
        property: "og:description",
        content: "Order support, sizing help and wholesale enquiries — answered in 24 hours.",
      },
    ],
  }),
  component: Contact,
});

const info = [
  { icon: Mail, label: "Email", value: "care@vexa.store" },
  { icon: Phone, label: "WhatsApp", value: "+91 98765 43210" },
  { icon: MapPin, label: "Studio", value: "Indiranagar, Bengaluru 560038" },
];

function Contact() {
  const [sent, setSent] = useState(false);

  return (
    <section className="mx-auto max-w-7xl px-5 py-16">
      <Reveal className="text-center">
        <p className="text-[10px] uppercase tracking-[0.3em] text-gold">We're listening</p>
        <h1 className="mt-4 font-display text-4xl sm:text-5xl">Contact Us</h1>
        <div className="hairline mx-auto mt-6 w-40" />
      </Reveal>

      <div className="mt-14 grid gap-10 lg:grid-cols-[1fr_1.3fr]">
        <div className="space-y-4">
          {info.map((c, i) => (
            <Reveal key={c.label} delay={i * 110}>
              <div className="flex items-center gap-5 rounded-sm border border-border bg-card p-6 transition-all duration-500 hover:-translate-y-1 hover:border-gold hover:shadow-goldy">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-full border border-gold/50 text-gold">
                  <c.icon className="size-5" />
                </div>
                <div>
                  <p className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                    {c.label}
                  </p>
                  <p className="mt-1 text-foreground">{c.value}</p>
                </div>
              </div>
            </Reveal>
          ))}
          <Reveal delay={340}>
            <div className="rounded-sm border border-gold/40 bg-surface/50 p-6">
              <p className="text-xs uppercase tracking-[0.22em] text-gold">Support hours</p>
              <p className="mt-3 text-sm text-muted-foreground">
                Mon – Sat, 10:00 – 19:00 IST. Average first reply: 3 hours.
              </p>
            </div>
          </Reveal>
        </div>

        <Reveal delay={150}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              setSent(true);
            }}
            className="rounded-sm border border-border bg-card p-8"
          >
            <h2 className="font-display text-2xl">Send a message</h2>
            <div className="mt-8 grid gap-5 sm:grid-cols-2">
              <Field label="Full name" type="text" placeholder="Aarav Sharma" />
              <Field label="Email" type="email" placeholder="you@email.com" />
              <div className="sm:col-span-2">
                <Field label="Subject" type="text" placeholder="Order #VX-1043" />
              </div>
              <div className="sm:col-span-2">
                <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
                  Message
                </label>
                <textarea
                  required
                  rows={5}
                  placeholder="Tell us how we can help…"
                  className="mt-2 w-full rounded-sm border border-border bg-background px-4 py-3 text-sm outline-none transition-colors duration-300 placeholder:text-muted-foreground/60 focus:border-gold"
                />
              </div>
            </div>

            <button className="btn-gold hover:btn-gold-hover mt-8 inline-flex items-center gap-2 rounded-sm px-8 py-4 text-xs">
              <Send className="size-4" /> Send message
            </button>

            {sent && (
              <p className="animate-fade-up mt-5 flex items-center gap-2 text-sm text-gold">
                <CheckCircle2 className="size-4" /> Thanks — we'll reply within 24 hours.
              </p>
            )}
          </form>
        </Reveal>
      </div>
    </section>
  );
}

function Field({
  label,
  type,
  placeholder,
}: {
  label: string;
  type: string;
  placeholder: string;
}) {
  return (
    <div>
      <label className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">
        {label}
      </label>
      <input
        required
        type={type}
        placeholder={placeholder}
        className="mt-2 w-full rounded-sm border border-border bg-background px-4 py-3 text-sm outline-none transition-colors duration-300 placeholder:text-muted-foreground/60 focus:border-gold"
      />
    </div>
  );
}
