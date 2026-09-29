import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { apiRequest, ApiError } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { StockItem } from "../types";

export function InventoryPage() {
  const { token, user, logout } = useAuth();
  const [items, setItems] = useState<StockItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiRequest<StockItem[]>("/api/v1/stock_items", { token })
      .then(setItems)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load inventory"))
      .finally(() => setLoading(false));
  }, [token]);

  return (
    <div className="page">
      <header className="topbar">
        <h1>Shelfwise</h1>
        <div>
          <span className="muted">
            {user?.name} · {user?.role}
          </span>
          <button onClick={logout} className="link-button">
            Sign out
          </button>
        </div>
      </header>

      <div className="actions">
        <Link to="/orders/new" className="button">
          Place order
        </Link>
        <Link to="/orders" className="button button-secondary">
          Orders
        </Link>
      </div>

      {error && <p className="error">{error}</p>}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>SKU</th>
              <th>Product</th>
              <th>Warehouse</th>
              <th>On hand</th>
              <th>Reserved</th>
              <th>Available</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id}>
                <td>{item.product.sku}</td>
                <td>{item.product.name}</td>
                <td>{item.warehouse.code}</td>
                <td>{item.quantity_on_hand}</td>
                <td>{item.quantity_reserved}</td>
                <td className={item.available <= 5 ? "low-stock" : undefined}>{item.available}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
