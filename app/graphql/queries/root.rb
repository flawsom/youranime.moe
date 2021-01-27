# frozen_string_literal: true
module Queries
  class Root < ::Types::BaseObject
    field :browse_all, Queries::Types::Show.connection_type, null: false
    field :next_airing_episode, Queries::Types::Shows::AiringSchedule, null: true do
      argument :slug, String, required: true
    end
    field :search, Queries::Types::Show.connection_type, null: false do
      argument :query, String, required: true
      argument :limit, Integer, required: false
    end
    field :show, Queries::Types::Show, null: true do
      argument :slug, String, required: true
    end
    field :trending, Queries::Types::Show.connection_type, null: false
    field :top_platforms, Queries::Types::Shows::Platform.connection_type, null: false

    def browse_all
      Show.optimized
    end

    def search(query:, limit: 100)
      ::Search.perform(search: query, limit: limit, format: :shows)
    end

    def show(slug:)
      Shows::Kitsu::GetBySlug.perform(slug: slug)
    end

    def next_airing_episode(slug:)
      Shows::Anilist::NextAiringEpisode.perform(slug: slug)
    end

    def top_platforms
      ShowUrl.popular_platforms
    end

    def trending
      Show.trending.includes(:title_record).limit(100)
    end
  end
end
