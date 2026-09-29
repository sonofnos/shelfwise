class CreateProcessedWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_webhook_events do |t|
      t.string :event_id
      t.string :event_type

      t.timestamps
    end
    add_index :processed_webhook_events, :event_id, unique: true
  end
end
