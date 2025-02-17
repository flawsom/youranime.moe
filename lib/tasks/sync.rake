# frozen_string_literal: true

namespace :sync do
  namespace :shows do
    namespace :update do
      task later: :environment do
        Show.find_in_batches.each do |batch|
          show_ids = batch.map(&:id)

          ::Sync::Shows::UpdateShowsJob.perform_later(
            show_ids,
          )
        end
      end

      task now: :environment do
        Show.find_in_batches.each do |batch|
          show_ids = batch.map(&:id)

          ::Sync::Shows::UpdateShowsJob.perform_now(
            show_ids,
          )
        end
      end
    end

    namespace :kitsu do
      desc 'Fetch and update the currently airing and upcoming shows from kitsu.io'
      task later: :environment do
        %i(current next).each do |season|
          Sync::ShowsFromKitsuJob.perform_later(season)
        end
      end
      task now: :environment do
        %i(current next).each do |season|
          Sync::ShowsFromKitsuJob.perform_now(season)
        end
      end

      namespace :update do
        desc 'Update the existing shows from kitsu.io'
        task now: :environment do
          Sync::UpdateExistingShowsJob.perform_now(
            force_update: false,
          )
        end

        task later: :environment do
          Sync::UpdateExistingShowsJob.perform_later(
            force_update: false,
          )
        end

        namespace :force do
          task now: :environment do
            Sync::UpdateExistingShowsJob.perform_now(
              force_update: true,
            )
          end

          task later: :environment do
            Sync::UpdateExistingShowsJob.perform_later(
              force_update: true,
            )
          end
        end
      end
    end

    namespace :anilist do
      desc 'Fetch additional show information from anilist.co'
      task airing_schedule: :environment do
        Show.streamable.airing.find_in_batches(batch_size: 10).each do |shows_batch|
          ::Sync::Shows::UpdateAiringScheduleJob.perform_later(
            shows_batch.map(&:id),
          )
        end
      end
    end

    namespace :crawl do
      desc 'Crawls all shows (and updates) all available shows from kitsu.io'
      task :later, [:start, :end] => [:environment] do |_, args|
        Sync::Shows::CrawlFromKitsuJob.perform_later(
          args[:start].to_i,
          args[:end].to_i,
        )
      end
      task :now, [:start, :end] => [:environment] do |_, args|
        Sync::Shows::CrawlFromKitsuJob.perform_now(
          args[:start].to_i,
          args[:end].to_i,
        )
      end
    end
  end
end
