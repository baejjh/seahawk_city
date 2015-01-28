class SiteController < ApplicationController

  def index
    #made up html5 api gps static location
    @user_pin = [47.62326,-122.33025] # this will be replaced with gps from phone of user
    @last_user_checkin = Checkin.order("created_at").last
    @locations = Location.all
    @events = Event.all
    @hash = Gmaps4rails.build_markers(@locations) do |location, marker|
        marker.lat location.latitude
        marker.lng location.longitude
        #marker.infowindow gmaps4rails_infowindow
        marker.infowindow render_to_string(:partial => "/partials/marker", :locals => { :object => location })
        marker.picture({
            "url" => "https://s3.amazonaws.com/uploads.hipchat.com/39979/1426756/Gyhorx6vyPkjyto/12flags_blue.png",
            "width" => 32,
            "height" => 32
            })

    end
  end

  def about
  end

end