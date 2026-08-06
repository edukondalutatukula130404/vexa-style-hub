import { useState, useEffect } from "react";
import type { Product } from "./products";

let wishlistState: Product[] = [];

if (typeof window !== "undefined") {
  try {
    const saved = localStorage.getItem("vexa_wishlist");
    if (saved) {
      wishlistState = JSON.parse(saved);
    }
  } catch (e) {
    console.warn("Failed to parse local wishlist:", e);
  }
}

const listeners = new Set<() => void>();

function notify() {
  if (typeof window !== "undefined") {
    try {
      localStorage.setItem("vexa_wishlist", JSON.stringify(wishlistState));
      window.dispatchEvent(new Event("vexa_wishlist_updated"));
    } catch (e) {
      console.warn("Failed to save wishlist to localStorage:", e);
    }
  }
  listeners.forEach((l) => l());
}

export function isInWishlist(productId: string | number): boolean {
  return wishlistState.some((p) => String(p.id) === String(productId));
}

export function toggleWishlist(product: Product) {
  const exists = isInWishlist(product.id);
  if (exists) {
    wishlistState = wishlistState.filter((p) => String(p.id) !== String(product.id));
  } else {
    wishlistState.push(product);
  }
  notify();
  return !exists;
}

export function addToWishlist(product: Product) {
  if (!isInWishlist(product.id)) {
    wishlistState.push(product);
    notify();
  }
}

export function removeFromWishlist(productId: string | number) {
  wishlistState = wishlistState.filter((p) => String(p.id) !== String(productId));
  notify();
}

export function clearWishlist() {
  wishlistState = [];
  notify();
}

export function useWishlist() {
  const [items, setItems] = useState<Product[]>(wishlistState);

  useEffect(() => {
    const listener = () => setItems([...wishlistState]);
    listeners.add(listener);

    const handleCustomEvent = () => setItems([...wishlistState]);
    if (typeof window !== "undefined") {
      window.addEventListener("vexa_wishlist_updated", handleCustomEvent);
    }

    return () => {
      listeners.delete(listener);
      if (typeof window !== "undefined") {
        window.removeEventListener("vexa_wishlist_updated", handleCustomEvent);
      }
    };
  }, []);

  return {
    wishlistItems: items,
    isInWishlist,
    toggleWishlist,
    addToWishlist,
    removeFromWishlist,
    clearWishlist,
  };
}
