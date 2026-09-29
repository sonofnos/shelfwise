export type Role = "admin" | "staff";

export interface AuthUser {
  id: number;
  name: string;
  email: string;
  role: Role;
}

export interface Product {
  id: number;
  sku: string;
  name: string;
  price_cents: number;
}

export interface Warehouse {
  id: number;
  name: string;
  code: string;
}

export interface StockItem {
  id: number;
  product: { id: number; sku: string; name: string };
  warehouse: { id: number; code: string };
  quantity_on_hand: number;
  quantity_reserved: number;
  available: number;
}

export type OrderStatus = "pending" | "paid" | "fulfilled" | "cancelled";

export interface Order {
  id: number;
  status: OrderStatus;
  external_reference: string;
  customer_name: string;
  items: { product: string; warehouse: string; quantity: number }[];
}
