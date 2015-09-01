class WelcomeController < ApplicationController
  def index
    @current_user = current_user
    @logged_in = logged_in?
    @home = true # this hides the white status bar from the home page

    user = current_user || User.new

    @candidates = user.home_candidates_to_endorse
    # p "***********************"
    # p @orgs_endorsing_candidates = @candidates.map { |twitteruser| twitteruser.user.specific_watched_users }
    #FL: I have a feeling the schema could be an issue in the deactivated code above

    @organizations = user.home_users_to_watch
    @candidates_endorsed_by_orgs = @organizations.map { |twitteruser| twitteruser.user.specific_endorsed_candidates
    }

    if @logged_in
      @twitter_profile_name = current_user.twitteruser.name
      @twitter_handle = current_user.twitteruser.nickname
      @twitter_profile_image = current_user.twitteruser.image
      @current_user_path = "/users/#{@current_user.id}"

    else
      @current_user_path = "#"
    end

    @users = User.all
  end
end
