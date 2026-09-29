class ProcessedWebhookEvent < ApplicationRecord
  # No uniqueness validation on purpose: a validation is a check-then-insert
  # race just like the thing it's meant to prevent. Idempotency here relies
  # solely on the unique index on event_id -- the insert either succeeds or
  # raises RecordNotUnique, atomically, which the caller rescues to detect
  # "already processed".
  validates :event_id, presence: true
end
