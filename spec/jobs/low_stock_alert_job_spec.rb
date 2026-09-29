require "rails_helper"

RSpec.describe LowStockAlertJob, type: :job do
  it "queues a low stock email for the stock item" do
    item = create(:stock_item)

    perform_enqueued_jobs do
      described_class.perform_now(item.id)
    end

    expect(ActionMailer::Base.deliveries.last.subject).to include(item.product.sku)
  end

  it "does nothing if the stock item no longer exists" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
