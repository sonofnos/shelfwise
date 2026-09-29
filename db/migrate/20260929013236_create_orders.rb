class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.integer :status, null: false, default: 0
      t.string :external_reference, null: false

      t.timestamps
    end
    add_index :orders, :external_reference, unique: true
  end
end
