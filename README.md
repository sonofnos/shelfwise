# Shelfwise

A multi-warehouse inventory and order-fulfillment API (Rails 8, API-only)
with a React/TypeScript front end. Staff place orders against per-warehouse
stock; stock can't be oversold, and payment webhooks can't double-process.

## What it does

- JWT auth (`POST /login`), roles: `admin`, `staff`.
- Products, warehouses, per-warehouse stock levels.
- Placing an order (`POST /api/v1/orders`) reserves stock across one or more
  warehouses; if any line is out of stock, nothing is reserved and the whole
  order fails with `409 Conflict`.
- Order lifecycle: `pending -> paid -> fulfilled`, or `cancelled` (which
  releases any reserved stock back to the pool).
- A payment processor's webhook (`POST /webhooks/payments`) marks an order
  paid, HMAC-signed and idempotent against replay.
- Shipping an order (`fulfill!`) deducts on-hand stock and queues a low-stock
  alert email once a product drops to the reorder threshold.

## Overselling, for real

An `available = on_hand - reserved` check in Ruby isn't enough by itself:
two concurrent orders on two different DB connections can both read
"5 available" before either writes. This is closed two ways:

1. **Application level**: `StockItem.reserve!` locks the stock row
   (`SELECT ... FOR UPDATE`) and checks headroom inside the same transaction
   as the increment.
2. **Database level**: a Postgres `CHECK` constraint on `stock_items`
   (`quantity_reserved <= quantity_on_hand`, `db/migrate/..._create_stock_items.rb`)
   makes it impossible to ever persist a row that oversells, regardless of
   the path that got there.

`spec/models/stock_item_spec.rb` proves it: ten threads on ten separate DB
connections all try to reserve the last unit of a 5-unit stock item at once.
Exactly five win, five get `InsufficientStockError`, and the persisted
`quantity_reserved` never exceeds `quantity_on_hand`.

## Idempotency, for real

Order placement is idempotent on `external_reference` (a retried client
request returns the original order, doesn't double-reserve). The payment
webhook is idempotent on `event_id` via a unique index, not a uniqueness
*validation* -- a validation is just another check-then-insert race; the
unique index makes the insert itself atomic, and the caller treats
`RecordNotUnique` as "already processed." `spec/requests/payment_webhooks_spec.rb`
replays the same event twice and confirms it's only applied once.

## Stack

- Rails 8.1 (API-only), PostgreSQL, Solid Queue for background jobs.
- React 19 + TypeScript + Vite, React Router, plain `fetch`.
- RSpec + FactoryBot for tests.

## Running it

```
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server -p 3000

cd web
npm install
cp .env.example .env.local   # VITE_API_URL=http://localhost:3000
npm run dev
```

Seeded login: `admin@shelfwise.test` / `password123` (two warehouses, two
products, stock pre-loaded).

## Tests

```
bundle exec rspec
```

23 examples, including the ten-thread oversell concurrency test above.
