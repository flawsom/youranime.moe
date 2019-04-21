class Admin::EpisodesController < AdminController

	def create
		episode = Episode.find_by(
      episode_number: episode_params[:episode_number],
      show_id: episode_params[:show_id]
    )
		if episode
			success = episode.update(title: episode_params[:title])
		else
			episode = Episode.new(episode_params)
			success = episode.save
		end
		if success
			episode.thumbnail.attach(params[:episode][:thumbnail]) if params[:episode][:thumbnail].class == ActionDispatch::Http::UploadedFile
			episode.video.attach(params[:episode][:video]) if params[:episode][:video].class == ActionDispatch::Http::UploadedFile
		end
		render json: { success: true, number: episode_params[:episode_number] }
	end

	def index
    @show = Show.find(params[:show_id])
    @episodes = @show.all_episodes.order('id desc')
    set_title before: t('sidebar.admin.manage.episodes')
	end

	def edit
		@episode = Show.find(params[:show_id]).all_episodes.find(params[:id])
	end

  def create_subs
    @episode = Show.find(params[:show_id]).all_episodes.find(params[:episode_id])
    src_file = params[:subtitle][:src]
    if src_file.nil?
      render json: {success: false, message: 'You\'re missing a subtitle file!'}
      return
    end

    begin
      Webvtt::File.new(src_file.tempfile.path)
    rescue => e
      render json: {success: false, message: 'Invalid WebVTT subtitle file!'}
      return
    end

    subtitle = @episode.subtitles.create(subtitle_params)
    if subtitle.persisted?
      render json: {success: true}
    else
      render json: {success: false, message: subtitle.errors_string}
    end
  end

	def update
		episode = Episode.find_by(id: params[:id])
		success = false
		unless episode.nil?
			episode.update_attributes(episode_params)
			if params[:video].class == ActionDispatch::Http::UploadedFile
				episode.video.attach(params[:video])
				success = true
			end
			if params[:thumbnail].class == ActionDispatch::Http::UploadedFile
				episode.thumbnail.attach(params[:thumbnail])
				success = true
			end
		end
		render json: { success: success }
	end

	private

	def episode_params
		params.require(:episode).permit(
			:title,
			:published,
			:episode_number,
			:show_id
		)
	end

  def subtitle_params
    params.require(:subtitle).permit(
      :name,
      :lang
    )
  end

end
