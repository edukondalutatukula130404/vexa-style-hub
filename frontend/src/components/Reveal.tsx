import { useEffect, useRef, type ReactNode } from "react";

export function Reveal({
  children,
  delay = 0,
  className = "",
}: {
  children: ReactNode;
  delay?: number;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Fallback: Ensure element becomes visible even if IntersectionObserver fails on mobile
    const timer = setTimeout(() => {
      if (el && !el.classList.contains("is-visible")) {
        el.classList.add("is-visible");
      }
    }, 400);

    if (typeof IntersectionObserver === "undefined") {
      el.classList.add("is-visible");
      clearTimeout(timer);
      return;
    }

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            el.classList.add("is-visible");
            clearTimeout(timer);
            io.unobserve(el);
          }
        });
      },
      { threshold: 0.01, rootMargin: "0px 0px 100px 0px" },
    );
    io.observe(el);
    return () => {
      clearTimeout(timer);
      io.disconnect();
    };
  }, []);

  return (
    <div
      ref={ref}
      className={`reveal ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </div>
  );
}
