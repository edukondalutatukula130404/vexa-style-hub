import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Mail, Phone, MapPin, Send, CheckCircle2, MessageCircle, Clock } from "lucide-react";
import { Reveal } from "@/components/Reveal";

export const Route = createFileRoute("/contact")({
  head: () => ({
    meta: [
      { title: "Contact Us | VEXA" },
      {
        name: "description",
        content: "Get in touch with VEXA customer support. We are here to help you with your orders and sizing queries.",
      },
    ],
  }),
  component: Contact,
});

export function Contact() {
  const [sent, setSent] = useState(false);

  return (
    <section className="mx-auto max-w-5xl px-5 py-16">
      <Reveal className="text-center">
        <p className="text-[10px] uppercase tracking-[0.3em] text-gold font-bold">Need Help?</p>
        <h1 className="mt-3 font-display text-4xl sm:text-5xl font-bold">Contact Us</h1>
        <div className="hairline mx-auto mt-4 w-32" />
        <p className="mx-auto mt-4 max-w-md text-xs sm:text-sm text-muted-foreground leading-relaxed">
          Have a question about your order, sizing, or custom tees? Send us a message or reach out directly.
        </p>
      </Reveal>

      {/* Quick Contact Cards */}
      <div className="mt-10 grid gap-4 sm:grid-cols-3">
        <Reveal delay={50}>
          <div className="flex items-center gap-4 rounded-xl border border-gold/40 bg-card p-5 shadow-goldy transition-all hover:border-gold">
            <div className="flex size-12 shrink-0 items-center justify-center rounded-xl border border-gold/50 bg-gold/15 text-gold">
              <Mail className="size-6" />
            </div>
            <div>
              <p className="text-[10px] uppercase tracking-widest text-gold font-bold">Email Us</p>
              <p className="mt-1 font-display text-xs sm:text-sm font-bold text-foreground">support@vexa.store</p>
            </div>
          </div>
        </Reveal>

        <Reveal delay={100}>
          <div className="flex items-center gap-4 rounded-xl border border-gold/40 bg-card p-5 shadow-goldy transition-all hover:border-gold">
            <div className="flex size-12 shrink-0 items-center justify-center rounded-xl border border-gold/50 bg-gold/15 text-gold">
              <Phone className="size-6" />
            </div>
            <div>
              <p className="text-[10px] uppercase tracking-widest text-gold font-bold">Call / WhatsApp</p>
              <p className="mt-1 font-display text-xs sm:text-sm font-bold text-foreground">+91 98765 43210</p>
            </div>
          </div>
        </Reveal>

        <Reveal delay={150}>
          <div className="flex items-center gap-4 rounded-xl border border-gold/40 bg-card p-5 shadow-goldy transition-all hover:border-gold">
            <div className="flex size-12 shrink-0 items-center justify-center rounded-xl border border-gold/50 bg-gold/15 text-gold">
              <Clock className="size-6" />
            </div>
            <div>
              <p className="text-[10px] uppercase tracking-widest text-gold font-bold">Working Hours</p>
              <p className="mt-1 font-display text-xs sm:text-sm font-bold text-foreground">Mon – Sat: 10am – 7pm</p>
            </div>
          </div>
        </Reveal>
      </div>

      {/* Simple Contact Form */}
      <Reveal delay={200} className="mt-10">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setSent(true);
          }}
          className="mx-auto max-w-2xl rounded-2xl border border-gold/40 bg-card p-8 shadow-goldy"
        >
          <h2 className="font-display text-xl sm:text-2xl font-bold text-foreground">Send a Message</h2>
          <p className="mt-1 text-xs text-muted-foreground">Fill out the form below and we will get back to you shortly.</p>

          <div className="mt-6 space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-bold">Your Name</label>
                <input
                  required
                  type="text"
                  placeholder="Enter your name"
                  className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs text-foreground outline-none focus:border-gold transition-colors"
                />
              </div>

              <div>
                <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-bold">Email Address</label>
                <input
                  required
                  type="email"
                  placeholder="name@example.com"
                  className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs text-foreground outline-none focus:border-gold transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-bold">Subject</label>
              <input
                required
                type="text"
                placeholder="How can we help you?"
                className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs text-foreground outline-none focus:border-gold transition-colors"
              />
            </div>

            <div>
              <label className="text-[10px] uppercase tracking-widest text-muted-foreground font-bold">Message</label>
              <textarea
                required
                rows={4}
                placeholder="Write your message here..."
                className="mt-1.5 w-full rounded-sm border border-border bg-background px-4 py-3 text-xs text-foreground outline-none focus:border-gold transition-colors"
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn-gold hover:btn-gold-hover mt-6 inline-flex w-full sm:w-auto items-center justify-center gap-2 rounded-sm px-8 py-3.5 text-xs font-bold uppercase tracking-wider shadow-sm"
          >
            <Send className="size-4" /> Send Message
          </button>

          {sent && (
            <div className="animate-fade-up mt-5 flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/10 p-4 text-xs text-gold font-semibold">
              <CheckCircle2 className="size-5 shrink-0" />
              <span>Thank you! Your message has been sent successfully. We will reply soon.</span>
            </div>
          )}
        </form>
      </Reveal>
    </section>
  );
}
