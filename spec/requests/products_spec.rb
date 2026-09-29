require "rails_helper"

RSpec.describe "Products", type: :request do
  it "forbids a staff (non-admin) user from creating a product" do
    staff = create(:user)

    post "/api/v1/products", params: { sku: "NEW1", name: "New", price_cents: 100 }, headers: auth_headers(staff)

    expect(response).to have_http_status(:forbidden)
  end

  it "allows an admin to create a product" do
    admin = create(:user, :admin)

    post "/api/v1/products", params: { sku: "NEW2", name: "New", price_cents: 100 }, headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
  end
end
