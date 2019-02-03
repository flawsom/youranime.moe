class UsersController < AuthenticatedController
    # Home page
    def home
        if params[:username] != current_user.username
            redirect_to "/users/#{current_user.username}"
        end
        set_title(before: t("user.welcome", user: current_user.get_name))
        @shows = Show.latest(current_user)
        @episodes = current_user.currently_watching(limit: 4)
        @recommended = Show.get_presence :recommended
        @featured = Show.get_presence :featured
        @this_season = Show.get_presence :season, 3, options: {current: true}
        @last_season = Show.get_presence :season, 3, options: {previous: true}
        @coming_soon = Show.coming_soon limit: 4
    end

    # Going to settings
    def settings
        set_title(before: 'Your settings')
    end

    # Update the user
    def update
        id = params[:id]
        user = User.find(id)
        if params[:user_settings]
            if user.update_settings(settings_params)
                flash[:success] = "Update successful!"
            else
                flash[:danger] = "Sorry, we can't seem to be able to update \"#{user.get_name}\"."
            end
        else
            if user.admin != user_params[:admin] and current_user.id == id
                flash[:danger] = "Sorry, you can't update your previledges. Another administrator must do it for you."
                return
            end
            if user.update_attributes(user_params)
                flash[:success] = "Update successful!"
                p user.settings
            else
                flash[:danger] = "Sorry, we can't seem to be able to update \"#{user.get_name}\"."
            end
        end
        redirect_to '/users/settings'
    end

    def short_settings
        redirect_to '/users/settings'
    end

    private
        def user_params
            params.require(:user).permit(
                :username,
                :name,
                :admin,
                :password,
                :password_confirmation
            )
        end

        def settings_params
            params.require(:user_settings).permit(
                :watch_anime,
                :last_episode,
                :episode_tracking,
                :recommendations,
                :images
            )
        end


end
