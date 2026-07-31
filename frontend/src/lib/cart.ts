import { useState, useEffect } from "react";
import type { Product } from "./products";

export type CartItem = {
  product: Product;
  size: string;
  quantity: number;
};

let cartState: CartItem[] = [];

if (typeof window !== "undefined") {
  try {
    const saved = localStorage.getItem("vexa_cart");
    if (saved) {
      cartState = JSON.parse(saved);
    }
  } catch (e) {
    console.warn("Failed to parse local cart:", e);
  }
}

const listeners = new Set<() => void>();

function notify() {
  if (typeof window !== "undefined") {
    try {
      localStorage.setItem("vexa_cart", JSON.stringify(cartState));
    } catch (e) {
      console.warn("Failed to save cart to localStorage:", e);
    }
  }
  listeners.forEach((l) => l());
}

export function addToCart(product: Product, size: string = "M", quantity: number = 1) {
  const existingIndex = cartState.findIndex(
    (item) => String(item.product.id) === String(product.id) && item.size === size
  );
  if (existingIndex > -1) {
    cartState[existingIndex].quantity += quantity;
  } else {
    cartState.push({ product, size, quantity });
  }
  notify();
}

export function removeFromCart(productId: string | number, size: string) {
  cartState = cartState.filter(
    (item) => !(String(item.product.id) === String(productId) && item.size === size)
  );
  notify();
}

export function updateCartQuantity(productId: string | number, size: string, delta: number) {
  const existing = cartState.find(
    (item) => String(item.product.id) === String(productId) && item.size === size
  );
  if (existing) {
    existing.quantity += delta;
    if (existing.quantity <= 0) {
      removeFromCart(productId, size);
    } else {
      notify();
    }
  }
}

export function clearCart() {
  cartState = [];
  notify();
}

export function useCart() {
  const [items, setItems] = useState<CartItem[]>(cartState);

  useEffect(() => {
    const listener = () => setItems([...cartState]);
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  }, []);

  const totalAmount = items.reduce(
    (sum, item) => sum + item.product.price * item.quantity,
    0
  );

  return {
    cartItems: items,
    addToCart,
    removeFromCart,
    updateCartQuantity,
    clearCart,
    totalAmount,
  };
}
