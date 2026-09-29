import { useEffect, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { apiRequest, ApiError } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { Product, Warehouse } from "../types";

export function NewOrderPage() {
  const { token } = useAuth();
  const navigate = useNavigate();

  const [products, setProducts] = useState<Product[]>([]);
  const [warehouses, setWarehouses] = useState<Warehouse[]>([]);
  const [customerName, setCustomerName] = useState("");
  const [customerEmail, setCustomerEmail] = useState("");
  const [productId, setProductId] = useState("");
  const [warehouseId, setWarehouseId] = useState("");
  const [quantity, setQuantity] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    apiRequest<Product[]>("/api/v1/products", { token }).then(setProducts).catch(() => undefined);
    apiRequest<Warehouse[]>("/api/v1/warehouses", { token }).then(setWarehouses).catch(() => undefined);
  }, [token]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);

    try {
      await apiRequest("/api/v1/orders", {
        method: "POST",
        token,
        body: {
          customer_name: customerName,
          customer_email: customerEmail,
          external_reference: `web-${Date.now()}`,
          items: [ { product_id: Number(productId), warehouse_id: Number(warehouseId), quantity } ],
        },
      });
      navigate("/orders");
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) {
        setError("Not enough stock at that warehouse for the requested quantity.");
      } else {
        setError(err instanceof ApiError ? err.message : "Failed to place order");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="page page-narrow">
      <h1>Place an order</h1>
      <form onSubmit={handleSubmit} className="card">
        <label>
          Customer name
          <input value={customerName} onChange={(e) => setCustomerName(e.target.value)} required />
        </label>
        <label>
          Customer email
          <input type="email" value={customerEmail} onChange={(e) => setCustomerEmail(e.target.value)} required />
        </label>
        <label>
          Product
          <select value={productId} onChange={(e) => setProductId(e.target.value)} required>
            <option value="" disabled>
              Select a product
            </option>
            {products.map((p) => (
              <option key={p.id} value={p.id}>
                {p.sku} · {p.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Warehouse
          <select value={warehouseId} onChange={(e) => setWarehouseId(e.target.value)} required>
            <option value="" disabled>
              Select a warehouse
            </option>
            {warehouses.map((w) => (
              <option key={w.id} value={w.id}>
                {w.code} · {w.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Quantity
          <input type="number" min={1} value={quantity} onChange={(e) => setQuantity(Number(e.target.value))} />
        </label>
        {error && <p className="error">{error}</p>}
        <button type="submit" disabled={submitting}>
          {submitting ? "Placing..." : "Place order"}
        </button>
      </form>
    </div>
  );
}
