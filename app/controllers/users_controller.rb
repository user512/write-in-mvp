class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def report_card
    @user = User.find(params[:user_id])

    #  #this would show all the offices and all the candidates
    #  @user_districts = @user.district.add_parents.map {|district| district}
    #  @user_districts_offices = @user_districts.compact.map {|district| district.offices}.flatten
    #  @user_districts_offices_candidates = @user_districts_offices.compact.map {|office| office.candidates}.flatten
    #  @user_districts_offices_candidates_users = @user_districts_offices_candidates.compact.map {|candidate| candidate.user.twitteruser}.flatten

    # # @reports = current_user.report_card
    # # @watched_users = current_user.specific_watched_users
    @twitter_profile_name = @user.twitteruser.name
    @twitter_handle = @user.twitteruser.nickname
    @twitter_profile_image = @user.twitteruser.larger_image
    @report_card = ReportCard.new(@user)

  end



  def endorse
    @user = User.find(params[:id])
    @user.endorse(current_user)
    if request.xhr?
      render json: true
    else
      redirect_to show_path(@user)
    end
  end

  def unendorse
    @candidate_to_unendorse = Candidate.find_by(user: User.find(params[:id]))
    current_user.unendorse(@candidate_to_unendorse)
    if request.xhr?
      render json: true
    else
      redirect_to show_path(current_user)
    end
  end

  # GET /users
  # GET /users.json

  # GET /users/1
  # GET /users/1.json
  def show
    @report_card = ReportCard.new(@user)
    @logged_in = logged_in?
    @current_user = current_user
    @user = User.find(params[:id])

    @organizations = Organization.list_of_watched_orgs(@user)
    @watched_user_endorsements = @organizations.map { |twitteruser| Candidate.list_of_cand_endorsed_by_org(twitteruser.user) }

    @twitter_profile_name = @user.twitteruser.name
    @twitter_handle = @user.twitteruser.nickname
    @twitter_profile_image = @user.twitteruser.larger_image

    @endorsed_candidates = Candidate.list_of_cand_endorsed_by_org(@user)
    @orgs_endorsing_a_candidate = @endorsed_candidates.map { |twitteruser| Organization.list_of_candidate_endorsing_organizations(twitteruser.user) }

    # @endorsed_candidate_endorsers = @endorsed_candidates.map { |twitteruser| Organization.list_of_orgs_endorsing_candidates(twitteruser.user) }

    @current_watching = Watching.find_by(user: current_user, organization: params[:id])
    @candidates_endorsed_by_a_org = @organizations.map { |twitteruser| Candidate.list_of_cand_endorsed_by_org(twitteruser.user)
    }

    @current_user_watches_org = @organizations.map do |org|
      if @current_user
        watchings = @current_user.watchings
        twitter_users = watchings.map { |w| w.organization.user.twitteruser }
        twitter_users.include?(org)
      else
        nil
      end
    end


    @org_ids = @organizations.map do |tu|
      tu.user.organization.id
    end



  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
   p env["omniauth.auth"]
    User.create_from_omniauth(auth)
    redirect_to root_url

  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:twitter_id, :token, :expires, :district)
    end
end
