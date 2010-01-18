require 'rubygems'
require 'cgi'
require 'net/http'
require 'net/https'
require 'json'


module Plurk
  DOMAIN = "www.plurk.com"
  ENDPOINTS = {
    :register => {:path => "/API/Users/register", :login_required => false, :required_params => [:nick_name, :full_name, :password, :gender, :date_of_birth, :email]},
    :login => {:path => "/API/Users/login", :login_required => false},
    :logout => {:path => "/API/Users/logout", :login_required => false},
    :update_profile => {:path => "/API/Users/update", :login_required => true, :required_params => [:current_password]},
    :update_picture => {:path => "/API/Users/updatePicture", :login_required => true, :required_params => [:profile_image]}, 
    :get_own_profile => {:path => "/API/Profile/getOwnProfile", :login_required => true},
    :get_public_profile => {:path => "/API/Profile/getPublicProfile", :login_required => false, :required_params => [:user_id]},
    :get_polled_plurks => {:path => "/API/Polling/getPlurks", :login_required => true},
    :get_polled_unread_count => {:path => "/API/Polling/getUnreadCount", :login_required => true},
    :get_plurk => {:path => "/API/Timeline/getPlurk", :login_required => true, :required_params => [:plurk_id]},
    :get_plurks => {:path => "/API/Timeline/getPlurks", :login_required => true},
    :get_unread_plurks => {:path => "/API/Timeline/getUnreadPlurks", :login_required => true},
    :plurk_add => {:path => "/API/Timeline/plurkAdd", :login_required => true, :required_params => [:content, :qualifier]},
    :plurk_delete => {:path => "/API/Timeline/plurkDelete", :login_required => true, :required_params => [:plurk_id]},
    :plurk_edit => {:path => "/API/Timeline/plurkEdit", :login_required => true, :required_params => [:plurk_id, :content]},
    :mute_plurks => {:path => "/API/Timeline/mutePlurks", :login_required => true, :required_params => [:ids]},
    :unmute_plurks => {:path => "/API/Timeline/unmutePlurks", :login_required => true, :required_params => [:ids]},
    :mark_as_read => {:path => "/API/Timeline/markAsRead", :login_required => true, :required_params => [:ids]},
    :upload_picture => {:path => "/API/Timeline/uploadPicture", :login_required => true, :required_params => [:image]},
    :get_responses => {:path => "/API/Responses/get", :login_required => false, :required_params => [:plurk_id, :from_response]},
    :add_response => {:path => "/API/Responses/responseAdd", :login_required => true, :required_params => [:plurk_id, :content, :qualifier]},
    :delete_response => {:path => "/API/Responses/responseDelete", :login_required => true, :required_params => [:plurk_id, :response_id]},
    :get_friends_by_offset => {:path => "/API/FriendsFans/getFriendsByOffset", :login_required => false, :required_params => [:user_id]},
    :get_fans_by_offset => {:path => "/API/FriendsFans/getFansByOffset", :login_required => false, :required_params => [:user_id]},
    :get_following_by_offset => {:path => "/API/FriendsFans/getFollowingByOffset", :login_required => true},
    :become_friend => {:path => "/API/FriendsFans/becomeFriend", :login_required => true, :required_params => [:friend_id]},
    :remove_as_friend => {:path => "/API/FriendsFans/removeAsFriend", :login_required => true, :required_params => [:friend_id]},
    :become_fan => {:path => "/API/FriendsFans/becomeFan", :login_required => true, :required_params => [:fan_id]},
    :set_following => {:path => "/API/FriendsFans/setFollowing", :login_required => true, :required_params => [:user_id, :follow]},
    :get_completion => {:path => "/API/FriendsFans/getCompletion", :login_required => true},
    :active_alerts => {:path => "/API/Alerts/getActive", :login_required => true},
    :alert_history => {:path => "/API/Alerts/getHistory", :login_required => true},
    :add_as_fan => {:path => "/API/Alerts/addAsFan", :login_required => true, :required_params => [:user_id]},
    :add_all_as_fan => {:path => "/API/Alerts/addAllAsFan", :login_required => true},
    :add_all_as_friends => {:path => "/API/Alerts/addAllAsFriend", :login_required => true},
    :add_as_friend => {:path => "/API/Alerts/addAsFriend", :login_required => true, :required_params => [:user_id]},
    :deny_friendship => {:path => "/API/Alerts/denyFriendship", :login_required => true, :required_params => [:user_id]},
    :remove_notification => {:path => "/API/Alerts/removeNotification", :login_required => true, :required_params => [:user_id]},
    :search_plurks => {:path => "/API/PlurkSearch/search", :login_required => false, :required_params => [:query]},
    :search_users => {:path => "/API/UserSearch/search", :login_required => false, :required_params => [:query]},
    :get_emoticons => {:path => "/API/Emoticons/get", :login_required => false},
    :get_blocked_users => {:path => "/API/Blocks/get", :login_required => true},
    :block_user => {:path => "/API/Blocks/block", :login_required => true, :required_params => [:user_id]},
    :unblock_user => {:path => "/API/Blocks/unblock", :login_required => true, :required_params => [:user_id]},
    :get_cliques => {:path => "/API/Cliques/getCliques", :login_required => true},
    :get_clique => {:path => "/API/Cliques/getClique", :login_required => true, :required_params => [:clique_name]},
    :create_clique => {:path => "/API/Cliques/createClique", :login_required => true, :required_params => [:clique_name]},
    :rename_clique => {:path => "/API/Cliques/renameClique", :login_required => true, :required_params => [:clique_name, :new_name]},
    :clique_add => {:path => "/API/Cliques/add", :login_required => true, :required_params => [:clique_name, :user_id]},
    :clique_remove => {:path => "/API/Cliques/remove", :login_required => true, :required_params => [:clique_name]}
  }
    
  class Client  
    attr_accessor :cookie, :logged_in, :api_key
    
    # params: username, password
    def login(params={})
      send_secure(:login, params)
    end
    
    def logout
      send_request(:logout)
      @cookie = ""
      @logged_in = false
    end
    
    # params: nick_name, fulle_name, password, gender, date_of_birth, email
    def register(params={})
      raise "Must be logged out to register" if logged_in?
      send_secure(:register, params)
    end
        
    # params: current_password
    def update_profile(params={})
      send_secure(:update_profile, params)
    end
    
    # params: attachment[name]=profile_image, attachment[file]
    def update_picture(params={})
      file_upload(:update_picture, params)
    end
    
    # params: none
    def get_own_profile
      send_request(:get_own_profile)
    end
    
    # params: user_id
    def get_public_profile(params={})
      send_request(:get_public_profile, params)
    end
    
    # get plurks newer than :offset
    # offset format: 2010-01-18T20:30:25
    def get_polled_plurks(params={})
      send_request(:get_polled_plurks, params)
    end
    
    def get_polled_unread_count
      send_request(:get_polled_unread_count)
    end
    
    # params: plurk_id
    def get_plurk(params={})
      send_request(:get_plurk, params)
    end
    
    
    def get_plurks(params={})
      send_request(:get_plurks, params)
    end
    
    def get_unread_plurks(params={})
      send_request(:get_unread_plurks, params)
    end
    
    # params: content, qualifier 
    def plurk_add(params={})
      send_request(:plurk_add, params)
    end
    
    # params: plurk_id
    def plurk_delete(params={})
      send_request(:plurk_delete, params)
    end
    
    # params: plurk_id, content
    def plurk_edit(params={})
      send_request(:plurk_edit, params)
    end
    
    # params: ids
    def mute_plurks(params={})
      send_request(:mute_plurks, {:ids => params[:ids].to_json})
    end
    
    # params: ids
    def unmute_plurks(params={})
      send_request(:unmute_plurks, {:ids => params[:ids].to_json})
    end
    
    # params: ids
    def mark_as_read(params={})
      send_request(:mark_as_read, {:ids => params[:ids].to_json})
    end
    
    # params: attachment[name]=image, attachment[file]
    def upload_picture(params={})
      file_upload(:upload_picture, params)
    end
    
    # params: plurk_id, from_response
    def get_responses(params={})
      send_request(:get_responses, params)
    end
    
    # params: plurk_id, content, qualifier
    def add_response(params={})
      send_request(:add_response, params)
    end
    
    # params: plurk_id, response_id
    def delete_response(params={})
      send_request(:delete_response, params)
    end
    
    # params: user_id
    def get_friends_by_offset(params={})
      send_request(:get_friends_by_offset, params)
    end
    
    # params: user_id
    def get_fans_by_offset(params={})
      send_request(:get_fans_by_offset, params)
    end
    
    # params:
    def get_following_by_offset(params={})
      send_request(:get_following_by_offset, params)
    end
    
    # params: friend_id
    def become_friend(params={})
      send_request(:become_friend, params)
    end
    
    # params: friend_id
    def remove_as_friend(params)
      send_request(:remove_as_friend, params)
    end
    
    # params: fan_id
    def become_fan(params={})
      send_request(:become_fan, params)
    end
    
    # params: user_id, follow
    def set_following(params={})
      send_request(:set_following, params)
    end
    
    # params:
    def get_completion
      send_request(:get_completion)
    end
    
    def active_alerts
      send_request(:active_alerts)
    end
    
    def alert_history
      send_request(:alert_history)
    end
    
    # params: user_id
    def add_as_fan(params={})
      send_request(:add_as_fan, params)
    end
    
    def add_all_as_fan
      send_request(:add_all_as_fan)
    end
    
    def add_all_as_friends
      send_request(:add_all_as_friends)
    end
    
    # params: user_id
    def add_as_friend(params={})
      send_request(:add_as_friend, params)
    end
    
    # params: user_id
    def deny_friendship(params={})
      send_request(:deny_friendship, params)
    end
    
    # params: user_id
    def remove_notification(params={})
      send_request(:remove_notification, params)
    end
    
    # params: query
    def search_plurks(params={})
      send_request(:search_plurks, params)
    end
    
    # params: query
    def search_users(params={})
      send_request(:search_users, params)
    end
    
    # params
    def get_emoticons
      send_request(:get_emoticons)
    end
    
    def get_blocked_users
      send_request(:get_blocked_users)
    end
    
    # params: user_id
    def block_user(params={})
      send_request(:block_user, params)
    end
    
    # params: user_id
    def unblock_usre(params={})
      send_request(:unblock_user, params)
    end
    
    def get_cliques
      send_request(:get_cliques)
    end
    
    # params: clique_name
    def get_clique(params={})
      send_request(:get_clique, params)
    end
        
    # params: clique_name
    def create_clique(params={})
      send_request(:create_clique, params)
    end
    
    # params: clique_name, new_name
    def rename_clique(params={})
      send_request(:rename_clique, params)
    end
    
    # params: clique_name, user_id
    def clique_add(params={})
      send_request(:clique_add, params)
    end
    
    # params: clique_name, user_id
    def clique_remove(params={})
      send_request(:clique_remove, params)
    end
    
    def initialize(api_key)
      @cookie = ""
      @api_key = api_key
    end
    
    def logged_in?
      defined?(@logged_in) && @logged_in
    end
    
    private
    def send_request(endpoint, params={}, headers={})
      raise LoginRequired, "Requires Login" if ENDPOINTS[endpoint][:login_required] && !logged_in?
            
      http = Net::HTTP.new(DOMAIN, 80)
      headers.merge!({"Cookie" => @cookie}) if logged_in?
      params.merge!({"api_key" => @api_key})
      params = Hash[*params.collect{|k,v| [k.to_s, v]}.flatten]
      request = Net::HTTP::Post.new(ENDPOINTS[endpoint][:path], headers)
      request.set_form_data(params)
      response = http.request(request)      
      @cookie = response["set-cookie"] || @cookie
      JSON.parse(response.body)  
    end
    
    def send_secure(endpoint, params={}, headers={})
      raise LoginRequired, "Requires Login" if ENDPOINTS[endpoint][:login_required] && !logged_in?
      
      http = Net::HTTP.new(DOMAIN, 443)
      http.use_ssl = true
      headers.merge!({"Cookie" => @cookie}) if logged_in?
      params.merge!({"api_key" => @api_key})
      params = Hash[*params.collect{|k,v| [k.to_s, v]}.flatten]
      request = Net::HTTP::Post.new(ENDPOINTS[endpoint][:path], headers)
      request.set_form_data(params)
      response = http.request(request)
      @cookie = response["set-cookie"] || @cookie
      @logged_in = true if endpoint == :login && response.code.to_i == 200
      JSON.parse(response.body)
    end
    
    def file_upload(endpoint, params={}, headers={})
      raise LoginRequired, "Requires Login" if ENDPOINTS[endpoint][:login_required] && !logged_in?
      http = Net::HTTP.new(DOMAIN, 80)
      headers.merge!({"Cookie" => @cookie}) if logged_in?
      request = Net::HTTP::Post.new(ENDPOINTS[endpoint][:path], headers)
      request = construct_body(request, params)
      response = http.request(request)
      @cookie = response["set-cookie"] || @cookie
      JSON.parse(response.body)
    end
    
    # stolen from http://boonedocks.net/mike/archives/162-Determining-Image-File-Types-in-Ruby.html
    def image_type(file)
      case IO.read(file, 10)
        when /^GIF8/: 'image/gif'
        when /^\x89PNG/: 'image/png'
        when /^\xff\xd8\xff\xe0\x00\x10JFIF/: 'image/jpeg'
        when /^\xff\xd8\xff\xe1(.*){2}Exif/: 'image/jpeg'
      else 'application/octet-stream'
      end
    end
    
    def construct_body(request, params)
      boundary = "plurkAABBZ012A"
      body = []
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: file; name=\"#{params[:attachment][:name]}\"; filename=\"#{File.basename(params[:attachment][:file])}\"\r\n"
      body << "Content-Type: #{image_type(params[:attachment][:file])}\r\n"
      body << "\r\n"
      body << File.read(params[:attachment][:file])
      body << "\r\n--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"api_key\"\r\n"
      body << "\r\n"
      body << "#{@api_key}\r\n"
      body << "--#{boundary}--\r\n"
      request.body = body.join
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request
    end
  end
  class LoginRequired < Exception; end
end