import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { apiRequest, ApiError } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { Order } from "../types";

export function OrdersPage() {
  const { token } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    try {
      const data = await apiRequest<Order[]>("/api/v1/orders", { token });
      setOrders(data);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load orders");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function transition(id: number, action: "pay" | "ship" | "cancel") {
    try {
      await apiRequest(`/api/v1/orders/${id}/${action}`, { method: "POST", token });
      load();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Action failed");
    }
  }

  return (
    <div className="page">
      <header className="topbar">
        <h1>Orders</h1>
        <Link to="/" className="link-button">
          Back to inventory
        </Link>
      </header>

      {error && <p className="error">{error}</p>}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Reference</th>
              <th>Customer</th>
              <th>Items</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id}>
                <td>{order.external_reference}</td>
                <td>{order.customer_name}</td>
                <td>
                  {order.items.map((line) => `${line.quantity}x ${line.product}@${line.warehouse}`).join(", ")}
                </td>
                <td>
                  <span className={`badge badge-${order.status}`}>{order.status}</span>
                </td>
                <td>
                  {order.status === "pending" && (
                    <>
                      <button onClick={() => transition(order.id, "pay")} className="link-button">
                        Mark paid
                      </button>{" "}
                      <button onClick={() => transition(order.id, "cancel")} className="link-button">
                        Cancel
                      </button>
                    </>
                  )}
                  {order.status === "paid" && (
                    <button onClick={() => transition(order.id, "ship")} className="link-button">
                      Ship
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {orders.length === 0 && (
              <tr>
                <td colSpan={5} className="muted">
                  No orders yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
