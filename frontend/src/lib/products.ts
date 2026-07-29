import black from "@/assets/tee-black.jpg";
import white from "@/assets/tee-white.jpg";
import navy from "@/assets/tee-navy.jpg";
import beige from "@/assets/tee-beige.jpg";
import charcoal from "@/assets/tee-charcoal.jpg";
import olive from "@/assets/tee-olive.jpg";

export type Product = {
  id: string;
  name: string;
  price: number;
  oldPrice: number;
  image: string;
  category: "Oversized" | "Classic" | "Limited";
  color: string;
  rating: number;
  stock: number;
};

export const SIZES = ["XS", "S", "M", "L", "XL", "XXL"] as const;

export const products: Product[] = [
  {
    id: "vx-01",
    name: "Obsidian Oversized Tee",
    price: 1499,
    oldPrice: 2199,
    image: black,
    category: "Oversized",
    color: "Jet Black",
    rating: 4.9,
    stock: 42,
  },
  {
    id: "vx-02",
    name: "Ivory Signature Tee",
    price: 1399,
    oldPrice: 1999,
    image: white,
    category: "Classic",
    color: "Ivory",
    rating: 4.8,
    stock: 27,
  },
  {
    id: "vx-03",
    name: "Midnight Navy Tee",
    price: 1599,
    oldPrice: 2299,
    image: navy,
    category: "Oversized",
    color: "Navy",
    rating: 4.7,
    stock: 18,
  },
  {
    id: "vx-04",
    name: "Desert Sand Tee",
    price: 1549,
    oldPrice: 2149,
    image: beige,
    category: "Limited",
    color: "Sand",
    rating: 5.0,
    stock: 9,
  },
  {
    id: "vx-05",
    name: "Charcoal Luxe Tee",
    price: 1449,
    oldPrice: 2099,
    image: charcoal,
    category: "Classic",
    color: "Charcoal",
    rating: 4.6,
    stock: 33,
  },
  {
    id: "vx-06",
    name: "Olive Heritage Tee",
    price: 1649,
    oldPrice: 2399,
    image: olive,
    category: "Limited",
    color: "Olive",
    rating: 4.9,
    stock: 6,
  },
];
