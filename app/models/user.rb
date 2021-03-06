class User < ActiveRecord::Base
  belongs_to :district
  has_many :candidates
  has_many :endorsements

  has_one :organization
  has_many :watchings
  has_one :twitteruser

  def name
    self.twitteruser.name
  end

  def populate_district
    if self.district == nil
      return ""
    else
      self.district.name
    end
  end

  def nickname
    self.twitteruser.nickname
  end

  def location
    self.twitteruser.location
  end

  def email
    self.twitteruser.email
  end

  def image
    self.twitteruser.image
  end

  def description
    self.twitteruser.description
  end

  def website
    self.twitteruser.website
  end

  def watch(current_user)
    args = {}
    args[:user] = current_user
    args[:organization] = self.organization
    Watching.find_or_create(args)
  end

  def unwatch(current_user)
    watching_to_destroy = Watching.find_by(organization: self.organization)
    watching_to_destroy && watching_to_destroy.destroy
  end

  def endorse(current_user)
    args = {}
    args[:user] = current_user
    args[:candidate] = Candidate.find_by(user: self)
    Endorsement.create(args)
  end

  def unendorse(candidate)
    endorsement_to_destroy = Endorsement.find_by(candidate: candidate, user: self)
    p endorsement_to_destroy
    p "*" * 100
    p candidate
    p "*" * 100
    p self
    p "*" * 100
    p endorsement_to_destroy
    endorsement_to_destroy && endorsement_to_destroy.destroy
  end

  def self.create_or_update(twitter_user)
    user = User.find_by(uid: twitter_user.uid) || User.new(uid: twitter_user.uid, district_id: 1)
    user.save
    user
  end

#Home page after logged in:
#--------------------------


  #top orgs based on how many are watching them and how many they are endorsing
  def org_score
    if  self.watchings == []
      watchings_count = 0
    else
      watchings = Watching.all
      watchings_array_user_id = watchings.map { |watching| watching.user_id }
      watchings_filtered = watchings_array_user_id.select {|user_id| user_id ==  self.id}
      watchings_count = watchings_filtered.compact.count
    end

    endorsements = self.endorsements.map { |endorsement| endorsement }

    sum_score = endorsements.compact.count + watchings_count
  end

  #top candidates based on how many are watching them and how many have endorsed them
  def cand_score

    if  self.watchings == []
      watchings_count = 0
    else
      watchings = Watching.all
      watchings_array_user_id = watchings.map { |watching| watching.user_id }
      watchings_filtered = watchings_array_user_id.select {|user_id| user_id ==  self.id}
      watchings_count = watchings_filtered.compact.count
    end

    if  self.endorsements == []
      endorsements_count = 0
    else
      endorsements = Endorsements.all
      endorsements_array_user_id = endorsements.map { |endorsements| endorsements.user_id }
      endorsements_filtered = endorsements_array_user_id.select {|user_id| user_id ==  self.id}
      endorsements_count = endorsements_filtered.compact.count
    end

    sum_score = endorsements_count + watchings_count
  end


  #checks that the listed users to watch are only those users that are not already watched by the viewer
  def already_watched_users
    watched_organizations = self.watchings.map { |watching| watching.organization }
    watched_users = watched_organizations.map { |organization|
      if organization == nil || organization == [nil] #here we need a check for eventualities
        nil
      else
        organization.user_id
      end }
    watched_users.compact
  end

  #checks that the listed users to watch are only those users that are not already watched by the viewer
  def already_endorsed_candidates
    if self.endorsements == nil || self.endorsements == []
      [1000] #FL: this could be a timebomb, once we have more then a 1000 candidates.
    else
      endorsed_candidates = self.endorsements.map { |endorsement| endorsement.candidate }
      watched_users = endorsed_candidates.map { |candidate|
        if candidate == nil || candidate == [nil]
          1000
        else
          candidate.user_id
        end }
       watched_users
     end
  end

  #which orgs are endorsing a specific candidate
  def organizations_endorsing_a_candidate
    endorsements = Endorsement.all
      endorsements_array_user_id = endorsements.map { |endorsement| endorsement.user }
      endorsements_filtered = endorsements_array_user_id.select {|user| user.id ==  self.id}
  end

  #check that all information is district specific
  def user_specific_districts
    if self.district
      districts = self.district.add_parents
      districts_array = districts.map {|district| district.id}
    else
      districts = District.all
      districts_array = districts.map {|district| district.id}
    end
  end

  #returns all users
  def users
    users_collection = User.all
  end

  #top watch user suggestions for a specific user
  def home_users_to_watch
    #takes all users
    users_array = users.map {|user| user}
    #filters out any user that does not endorse anybody
    users_endorsing = users_array.select {|user| user.endorsements.count >= 1}
    #sort users with endorsements according to their endorsement count
    users_array_sort = users_endorsing.sort_by {|user| user.org_score}
    #if user has a district it will only show relevant candidates else it will show all
    filtered_district_user_array = users_array_sort.reverse.select {|user| user_specific_districts.include?(user.district_id)}
    #filters out self
    f_filtered_district_user_array = filtered_district_user_array.select{|user|
      unless user == self
        user
      end }
    #filters out all users that the specific user is already watching
    filtered_district_and_watched_user_array = f_filtered_district_user_array.select{|user|
      unless already_watched_users.include?(user.id)
        user
      end }
    #returns the twitteruser data for the users
    twitterusers = filtered_district_and_watched_user_array.map { |user| user.twitteruser }
    # cut_off_users_array = twitterusers[0..10]
  end

  #returns all candidates as users
  def candidates_users
    candidates_collection = Candidate.all
    candidates_users_collection = candidates_collection.map {|candidate| candidate.user}
  end

  #top candidate suggestions for a specific user
  def home_candidates_to_endorse
    #takes all candidates
    candidates_array = candidates_users.map {|user| user}
    #sorts candidates by their candidate score
    candidates_array_sort = candidates_array.sort_by {|user| user.cand_score}
    #selects only the candidates of relevant districts
    filtered_district_candidate_array = candidates_array_sort.select {|user| user_specific_districts.include?(user.district_id)}
    #this filters out all candidates that you are endorsing already
    filtered_district_and_watched_candidate_array = filtered_district_candidate_array.reverse.select {|user|
      unless already_endorsed_candidates.include?(user.id)
        user
      end }
    #returns the twitteruser data for the users
    twitterusers = filtered_district_and_watched_candidate_array.map {|user| user.twitteruser}
    # cut_off_candidate_array = twitterusers[0..10]
  end

#Profile page:
#--------------------------
  # def self.twitteruser_profile_name
  #   Twitteruser.find_by(user_id: session[:current_user_id]).name
  # end

  #watched users for a specific profile
  def specific_watched_users
    watched_organizations = self.watchings.map { |watching| watching.organization }
    watched_users = watched_organizations.compact.map { |organization| organization.user }
    #sorts users according to organization score
    watched_users_sorted = watched_users.sort_by {|user| user.org_score}
    watched_users_twitter = watched_users_sorted.reverse.compact.map { |user| user.twitteruser }
    watched_users_twitter.compact
    # cut_off_twitteruser_array = watched_users_twitter[0..10]
  end

  #watched endorsed users (candidates) for a specific profile
  def specific_endorsed_candidates
    endorsed_users = self.endorsements.map { |endorsement| endorsement }
    endorsed_candidates = endorsed_users.map { |endorsement| endorsement.candidate }
    endorsed_candidate_users = endorsed_candidates.compact.map { |candidate| candidate.user }
    #sorts candidates according to organization score (should be candidate score)
    endorsed_candidate_users_sorted = endorsed_candidate_users.sort_by {|user| user.cand_score}
    endorsed_users_twitter = endorsed_candidate_users_sorted.reverse.map { |user| user.twitteruser }
    # cut_off_twitteruser_array = endorsed_users_twitter[0..10]
  end

  #endorsing orgs for a specific candidate
  def specific_endorsing_orgs
    candidate = Candidate.find_by(user: self)
    endorsements = Endorsement.where(candidate: candidate)
    twitterusers = endorsements.reverse.map { |endorsement| endorsement.user.twitteruser
    }
  end


#Report card page:
#--------------------------

  #report card information
  def report_card
    self.district.add_parents.map do |district|
      { district: district,
        offices: district.rc_offices(self)
      }
    end
  end

  #checks that the listed candidates are only those candidates that are also endorsed by people i am watching
  def check_candidate(passed_candidate)

    watched_organizations = self.watchings.map { |watching| watching.organization }
    watched_users = watched_organizations.compact.map { |organization| organization.user }

    p "pass first call"
    return false if watched_users.count == 0

    watched_user_endorsements = watched_users.map { |user| user.endorsements }.flatten
    acceptable_candidates = watched_user_endorsements.map { |endorsement| endorsement.candidate }
    acceptable_users = acceptable_candidates.compact.map { |candidate| candidate.user }

    p "pass second call"
    return false if acceptable_users.count == 0

    p "passed_candidate: #{passed_candidate}"
    p "passed_candidate.user: #{passed_candidate.user}"
    if acceptable_users.include?(passed_candidate.user)
      return passed_candidate.user
    else
      return false
    end
  end

end

