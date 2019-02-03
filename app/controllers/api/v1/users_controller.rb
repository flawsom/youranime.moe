module Api
  module V1
    class UsersController < Api::ApplicationController

      def token
        credentials = get_username_password
        username = credentials[:username]
        password = credentials[:password]

        user = ensure_user_exists! username
        ensure_maintenance! user

        # If the client requests and admin account.
        ensure_admin_if_requested! user
        ensure_is_activated! user

        # Keep generating tokens until no user with that token exists.
        success = true
        if params[:preserve_token] != "true"
            success = user.regenerate_auth_token
        end

        if success
    			render json: {token: user.auth_token, message: t("welcome.user", user: user.get_name), user: user, success: true}
    		else
    			render json: {message: "Sorry, our server authenticated you but could not log you in.", success: false}
    		end
    	end

      private

      def get_username_password
        username = token_params[:username]
    		password = token_params[:password]

    		if username.to_s.strip.empty? or password.to_s.strip.empty?
    			raise Api::MissingCredentialsError.new
    		end

        begin
          username = Base64.urlsafe_decode64 username
          password = Base64.urlsafe_decode64 password
        rescue ArgumentError
          raise Api::InvalidCredentialsError.new
        end
        {username: username, password: password}
      end

      def ensure_user_exists!(username)
        user = User.find_by(username: username)
    		if user.nil? or !user.authenticate password
          raise Api::UserNotFoundError.new
    		end
        user
      end

      def ensure_maintenance!(user)
        if !user.is_admin? && maintenance_activated?(user: user)
          raise Api::UndergoingMaintenanceError.new
        end
      end

      def ensure_admin_if_requested!(user)
        if params[:admin] == "true" && !user.is_admin?
          raise Api::NotAdminError.new
        end
      end

      def ensure_is_activated!(user)
        raise Api::UserNotActivatedError.new if !user.is_activated?
      end

    end
  end
end
