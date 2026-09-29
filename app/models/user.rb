class User < ApplicationRecord
  has_secure_password

  enum :role, { admin: 0, staff: 1 }, default: :staff

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  before_save { self.email = email.downcase.strip }
end
