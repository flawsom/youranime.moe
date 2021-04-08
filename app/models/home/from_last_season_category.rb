# frozen_string_literal: true
module Home
  class FromLastSeasonCategory < Home::BaseCategory
    def title_template
      "categories.from_last_season.title"
    end

    def scopes
      [:trending, :from_last_season]
    end

    def enabled?
      true
    end
  end
end
