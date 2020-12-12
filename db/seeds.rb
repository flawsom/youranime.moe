# encoding: utf-8
require 'mini_magick'

def seed
  seed_users
  seed_show_tags
  seed_shows_later
end

def seed_users
  Staff.create!(
    username: 'system',
    name: 'System User',
    limited: false,
    password: SecureRandom.hex,
    email: 'system@youranime.moe',
  )
  if Rails.env.development?
    Staff.create(
      username: 'admin',
      name: 'Admin User',
      limited: false,
      password: 'password',
      email: 'admin@youranime.moe',
    ).to_user!

    User.create(
      username: 'futsuu',
      name: 'Yamada Normy',
      limited: false,
      password: 'normal',
      email: 'normal@youranime.moe',
    )

    User.create(
      username: 'limited',
      name: 'Limited User',
      limited: true,
      password: 'limited',
      email: 'limited@youranime.moe',
    )
  else
    User.create(
      username: 'demo',
      password: 'demo',
      limited: true,
      name: 'Demo User'
    )
    Staff.create(
      username: 'admin',
      name: 'Admin User',
      password: 'this is my boss password',
      limited: false,
    )
  end
  #(1..249).each do |i|
  #  User.create!(
  #    username: "user#{i}",
  #    password: 'password',
  #    name: "User #{i}",
  #    limited: true,
  #    email: "user#{i}@email.com"
  #  )
  #end
end

def seed_show_tags
  Utils.valid_tags.each do |tag|
    Tag.create(value: tag)
  end
end

def seed_shows_later
  Sync::ShowsFromKitsuJob.perform_later(staff: Users::Admin.system)
end

def seed_shows
  banners.each_with_index do |banner_filename, i|
    show_name = banner_filename.split('.')[0]
    show = seed_show(show_name, at: i)
    next unless show.persisted?

    seed_episodes(show, show_name)
  end

  `bundle exec rails seed:all:media`

  # Seed an additional 500 shows
  #start = Show.count + 1
  #fin = 500 + start
  #(start..fin).each do |i|
  #  title = Title.new(en: "Show #{i}")
  #  description = Description.new(en: "This show was autogenetared. Number: #{i}")
  #  Show.create!(show_type: 'anime', published: true, released_on: Time.now, title: title, description: description)
  #end

  # seed_ratings

  Rails.logger.info "Note: Don't forget to run `rails seed:shows:banners` to populate the show's banners"
end

def seed_episodes(show, key)
  show.seasons.each do |season|
    episodes(key).each_with_index do |_, i|
      episode_number = i + 1
      season.episodes.create(
        number: episode_number,
        title: "Episode #{episode_number} - Season #{season.number} - #{show.title}"
      )
    end
  end
end

def seed_show(show_name, at: nil)
  title = Title.new(
    en: "Title for #{show_name}",
    fr: "Titre pour #{show_name}",
    jp: "「#{show_name}」のタイトル",
    roman: show_name
  )
  description = Description.new(
    en: 'My description in English',
    fr: 'Ma description en Français',
    jp: '日本語での概要'
  )

  show = Show.create!(
    show_type: 'anime',
    released_on: Time.now.utc,
    published: true,
    title: title,
    description: description
  )

  %w[comedy fantasy magic].each do |tag|
    show.tags << Tag.find_by(value: tag)
  end

  show.seasons.create(number: 1)

  show
end

def seed_ratings
  ids = Show.ids.sample 100
  shows = Show.where(id: ids)

  shows.each do |show|
    user_ids = User.ids.sample(rand(50..User.count))
    users = User.where(id: user_ids)

    users.each do |user|
      user.ratings.create!(show: show, value: rand(1..5))
    end
  end
end

def banner_files
  @banner_files ||= banners.map { |banner_filename| File.open("./seeds/banners/#{banner_filename}") }
end

def banners
  files_at('seeds', 'banners').select { |file| file =~ /\.(png|jpg)\z/.freeze }
end

def episodes(key)
  files_at('seeds', 'thumbnails').select do |file|
    file =~ /\.(png|jpg)\z/.freeze
    return false unless file

    file.start_with?(key)
  end
end

def files_at(*args)
  Dir.entries(Rails.root.join(*args))
end

seed
