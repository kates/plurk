# Plurk Client #

A Plurk client in Ruby using the brand, spanking, new API found in [http://www.plurk.com/API](http://www.plurk.com/API). You will need an API key.

## Install ##
    gem install plurk --source http://gemcutter.org

## Usage ##
    require "rubygems"
    require "plurk"
    
    plurk = Plurk::Client.new api_key
    plurk.login :username => "username", :password => "password"
    plurk.get_plurks
    plurk.plurk_add :content => "plurking yay (lmao)", :qualifier => "says"
    

## File upload ##
    plurk.upload_picture "/path/to/image.jpg"
    
See [http://www.plurk.com/API](http://www.plurk.com/API) for the return values.

Released under MIT License.