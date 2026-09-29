admin = User.find_or_create_by!(email: "admin@shelfwise.test") do |u|
  u.name = "Ada Admin"
  u.password = "password123"
  u.role = :admin
end

lagos = Warehouse.find_or_create_by!(code: "LOS") { |w| w.name = "Lagos Distribution Center" }
abuja = Warehouse.find_or_create_by!(code: "ABJ") { |w| w.name = "Abuja Fulfillment Hub" }

widget = Product.find_or_create_by!(sku: "WIDGET-01") { |p| p.name = "Widget"; p.price_cents = 2500 }
gadget = Product.find_or_create_by!(sku: "GADGET-01") { |p| p.name = "Gadget"; p.price_cents = 4900 }

StockItem.find_or_create_by!(product: widget, warehouse: lagos) { |s| s.quantity_on_hand = 50 }
StockItem.find_or_create_by!(product: widget, warehouse: abuja) { |s| s.quantity_on_hand = 20 }
StockItem.find_or_create_by!(product: gadget, warehouse: lagos) { |s| s.quantity_on_hand = 8 }

puts "Seeded #{User.count} users, #{Warehouse.count} warehouses, #{Product.count} products, #{StockItem.count} stock items."
