class CreateStockItems < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_items do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.integer :quantity_on_hand, null: false, default: 0
      t.integer :quantity_reserved, null: false, default: 0

      t.timestamps
    end

    add_index :stock_items, [ :product_id, :warehouse_id ], unique: true

    # Belt-and-braces against overselling: reserve_stock! locks this row and
    # checks headroom in Ruby before incrementing, but a CHECK constraint is
    # the backstop that makes it impossible to ever *persist* a row where
    # more stock is reserved than is on hand, no matter what path got there.
    execute <<-SQL
      ALTER TABLE stock_items
      ADD CONSTRAINT quantity_reserved_within_on_hand
      CHECK (quantity_reserved >= 0 AND quantity_reserved <= quantity_on_hand)
    SQL
  end
end
