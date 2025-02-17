# frozen_string_literal: true
class Issue < ApplicationRecord
  include AASM

  OPEN = :open
  PENDING = :pending
  IN_PROGRESS = :in_progress
  RESOLVED = :resolved
  CLOSED = :closed
  ARCHIVED = :archived

  STATUSES = [OPEN, PENDING, IN_PROGRESS, RESOLVED, CLOSED, ARCHIVED].freeze
  PAGE_URL_FORMAT = %r{\A/[/\w-]+\z}

  validates :title, presence: true
  validates :description, presence: true
  validates_inclusion_of :status, in: STATUSES.map(&:to_s), message: '%{value} is not a valid status'

  belongs_to :graphql_user, inverse_of: :issues, foreign_key: :user_id
  validates_format_of :page_url, with: PAGE_URL_FORMAT, if: :page_url?

  aasm column: :status do
    state OPEN, initial: true
    (STATUSES - [OPEN]).each { |status| state(status) }

    event :close do
      transitions from: [OPEN, IN_PROGRESS, PENDING], to: CLOSED
    end

    event :as_pending do
      transitions from: OPEN, to: PENDING
    end

    event :as_in_progress do
      transitions from: PENDING, to: IN_PROGRESS
    end

    event :archive do
      transitions from: [PENDING, CLOSED, RESOLVED], to: ARCHIVED
    end

    event :resolve do
      transitions from: IN_PROGRESS, to: RESOLVED
    end
  end
end
