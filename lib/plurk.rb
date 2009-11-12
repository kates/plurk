require 'mechanize'
require 'json'
require 'uri'

class Plurk
  PLURK_PATHS = {
    :login => 'Users/login',
    :get_completion => 'Users/getCompletion',
    :plurk_add => 'TimeLine/addPlurk',
    :plurk_respond => 'Responses/add',
    :plurk_get => 'TimeLine/getPlurks',
    :plurk_get_responses => 'Responses/get2',
    :plurk_get_unread => 'TimeLine/getUnreadPlurks',
    :plurk_get_global => 'TimeLine/getGlobalPlurks',
    :plurk_mute => 'TimeLine/setPlurkMute',
    :plurk_delete => 'TimeLine/deletePlurk',
    :notification => 'Notifications',
    :notification_accept => 'Notifications/allow',
    :notification_makefan => 'Notifications/allowDontFollow',
    :notification_deny => 'Notifications/deny',
    :friends_get => 'Users/getFriends',
    :friends_block => 'Friends/blockUser',
    :friends_remove_block => 'Friends/removeBlock',
    :friends_get_blocked => 'Friends/getBlockedByOffset',
    :user_get_info => 'Users/fetchUserInfo',
    :get_countrieds => 'Geo/getCountries',
    :get_regions => 'Geo/getRegions',
    :get_cities => 'Geo/getCities'
  }
  
  HTTP_BASE = "http://www.plurk.com"
  
  attr_accessor :agent
  attr_accessor :user_id

  def initialize

  end

  def agent
    @agent ||= WWW::Mechanize.new
  end

  def login(nick_name, password)
    @nick_name = nick_name
    @password = password
    page = agent.get(HTTP_BASE)
    login_form = page.forms.first
    login_form.nick_name = @nick_name
    login_form.password = @password
    page = agent.submit(login_form, login_form.buttons.first)
    /var SETTINGS = \{.*"user_id": ([\d]+),.*\}/imu =~ page.body
    @user_id = $1
    @logged_in = page.code == "200"
  end

  def authenticate?(nick_name, password)
    agent = WWW::Mechanize.new
    page = agent.get(HTTP_BASE)
    login_form = page.forms.first
    login_form.nick_name = nick_name
    login_form.password = password
    page = agent.submit(login_form, login_form.buttons.first)
    login_error = page.uri.query && page.uri.query.split("&").collect
    return page.code == "200"
  end

  def get_params(uri)
    uri = URI.parse(uri) unless uri.is_a? URI
    Hash[*uri.split("&").collect{|c| c.split("=") }.flatten]
  end

  def logged_in?
    @logged_in
  end

  def plurks(params={})
    default_params = {:user_id => @user_id, :user_ids => []}
    default_params.merge!(params)
    puts default_params.inspect
    page = agent.post("#{HTTP_BASE}/#{PLURK_PATHS[:plurk_get]}", default_params)
    body = page.body
    body.gsub(/new Date\(([^\)]*)\)/, "")
    body.gsub!(/new Date\(([^\)]*)\)/, $1)
    JSON.parse(body)
  end

  def friends_completion
    page = agent.post("#{HTTP_BASE}/Friends/getMyFriendsCompletion")
    body = page.body
    JSON.parse(body)
  end

  def friends
    (0..(user_data(@user_id)['num_of_friends'].to_i/10)).inject([]) do |a,c|
      a += get_friends_by_offset(@user_id, c * 10)
    end
  end
  
  def get_friends_by_offset(uid, offset)
    page = agent.post("#{HTTP_BASE}/Friends/getFriendsByOffset", {:user_id => uid, :offset => offset})
    body = page.body
    body.gsub(/new Date\(([^\)]*)\)/, "")
    body.gsub!(/new Date\(([^\)]*)\)/, $1)
    JSON.parse(body)
  end
  
  def fans
    (0..(user_data(@user_id)['num_of_fans'].to_i/10)).inject([]) do |a,c|
      a += get_fans_by_offset(@user_id, c * 10)
    end
  end
  
  def get_fans_by_offset(uid, offset)
    page = agent.post("#{HTTP_BASE}/Friends/getFansByOffset", {:user_id => uid, :offset => offset})
    body = page.body
    body.gsub(/new Date\(([^\)]*)\)/, "")
    body.gsub!(/new Date\(([^\)]*)\)/, $1)
    JSON.parse(body)
  end

  def add(params)
    defaults = {
      :posted => Time.now.getgm.strftime("%Y-%m-%dT%H:%M:%S"),
      :content => "",
      :qualifier => ":",
      :limited__to => [],
      :no_comments => false,
      :lang => "en",
      :uid => @user_id
    }
    params = defaults.merge(params)
    params[:content] = "#{params[:content].slice(0,137)}..." if params[:content].length >= 140
    params[:limited_to] &&= "[#{params[:limited_to].join(",")}]"
    params[:no_comments] = params[:no_comments] ? 1 : 0
    page = agent.post("#{HTTP_BASE}/#{PLURK_PATHS[:plurk_add]}", params)
    page.code
  end

  def user_data(uid)
    @user_data ||= get_user_data(uid)
  end
  
  def get_user_data(uid)
    page = agent.post("#{HTTP_BASE}/Users/getUserData", {:page_uid => uid})
    body = page.body
    user_data = JSON.parse(body)
  end
    
  def unread_plurks
    page = agent.post("#{HTTP_BASE}/Users/getUnreadPlurks", {:known_friends => "[#{friends_following.join(",")}]" })
    body = page.body
    body.gsub(/new Date\(([^\)]*)\)/, "")
    body.gsub!(/new Date\(([^\)]*)\)/, $1)
    JSON.parse(body)
  end
  
  def friends_following
    friends.collect{|f| f['uid'].to_s }
  end
end
