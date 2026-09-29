require "rails_helper"

RSpec.describe InventoryMailer, type: :mailer do
  describe "low_stock" do
    let(:stock_item) { create(:stock_item, quantity_on_hand: 3) }
    let(:mail) { InventoryMailer.low_stock(stock_item) }

    it "renders the headers" do
      expect(mail.subject).to include(stock_item.product.sku)
      expect(mail.to).to eq([ "warehouse-managers@shelfwise.test" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(stock_item.product.name)
    end
  end
end
