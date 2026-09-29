# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_29_013238) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.bigint "warehouse_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["warehouse_id"], name: "index_order_items_on_warehouse_id"
    t.check_constraint "quantity > 0", name: "quantity_must_be_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.integer "status", default: 0, null: false
    t.string "external_reference", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_reference"], name: "index_orders_on_external_reference", unique: true
  end

  create_table "processed_webhook_events", force: :cascade do |t|
    t.string "event_id"
    t.string "event_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_processed_webhook_events_on_event_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "stock_items", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "warehouse_id", null: false
    t.integer "quantity_on_hand", default: 0, null: false
    t.integer "quantity_reserved", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "warehouse_id"], name: "index_stock_items_on_product_id_and_warehouse_id", unique: true
    t.index ["product_id"], name: "index_stock_items_on_product_id"
    t.index ["warehouse_id"], name: "index_stock_items_on_warehouse_id"
    t.check_constraint "quantity_reserved >= 0 AND quantity_reserved <= quantity_on_hand", name: "quantity_reserved_within_on_hand"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_warehouses_on_code", unique: true
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "warehouses"
  add_foreign_key "stock_items", "products"
  add_foreign_key "stock_items", "warehouses"
end
