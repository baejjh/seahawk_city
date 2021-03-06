class LocationsController < ApplicationController

  def index
    #ALL CODE MOVED TO SITE CONTROLLER
    @locations = Location.all
  end

  # def gmaps4rails_infowindow - METHOD TO POPULATE THE INFO WINDOW, NOT BEING USED ANYMORE
  #   "<img src=\'http://i.imgur.com/QL2gRQv.jpg\'>"

  # end

  def new
      @location = Location.new
      @user = current_user
  end

  def create
      #If Search Field is filled in...
      if params[:location][:address] != ""
          geo_and_reverse
              if @existing_location
                  @existing_location.update!("user_id" => current_user.id)
                  # render json: @existing_location
                  flash[:success] = "Thanks for claiming your business; you may now create events for your business below!"
                  redirect_to profile_path
              elsif
                  #IF it's not an existing location
                  @location = Location.create(search_address_hash)
                  flash[:success] = "!!!Your business has been added to the system; you may now create events below!"
                  # render json: nearby_locations
                  redirect_to profile_path
              else
                  flash[:danger] = "Apologies, we were unable to find that location: please try searching for another"
                  redirect_to new_location_path
              end
      else
          #If Longitude and Latitude are both available
          if (params[:location][:latitude] != "") and (params[:location][:longitude] != "")
              geo_by_lat_long
              if @existing_location
                  redirect_to new_location_path
              else
                  #REVERSE-GEOCODE to Get Address Details
                  @location = Location.create(reverse_geocoded_address_hash)
                  render json: nearby_locations
              end
          else
              #If longitude and/or latitude are not available, use address form
              geo_and_reverse
              if existing_location
                  @existing_location.update!("user_id" => current_user.id)
                  # render json: @existing_location
                  flash[:success] = "Thanks for claiming your business; you may now create events for your business below!"
                  redirect_to profile_path
              else
                      @location = Location.new(address_hash)
                    if @location.save
                      flash[:success] = "Your business has been added to the system; you may now create events below!"
                    else
                      flash[:danger] = "Shit stopped working"

                    end
                      # render json: nearby_locations
                      redirect_to new_location_path
                    # else
                      # redirect_to root_path
                    # end
              end
          end
      end
  end

  def show
  end

  def nearby
      @location = params[:latitude] + ", " + params[:longitude]
      render json: nearby_locations

  end

  def edit
  end

  def update
  end

  def destroy
  end

  def geo_and_reverse
  #GEOCODE BY ADDRESS to Get Longitude & Latitude
  #AND REVERSE-GEOCODE on Result to keep data normalized
      @lat_long_array = Geocoder.coordinates(address_string) || [nil, nil]
      @latitude = @lat_long_array[0].to_s
      @longitude = @lat_long_array[1].to_s
      @lat_long_string = @latitude + ", " + @longitude
      existing_location
  end

  def geo_by_lat_long
      @latitude = params[:location][:latitude]
      @longitude = params[:location][:longitude]
      @lat_long_string = @latitude + ", " + @longitude
      existing_location
  end

  def existing_location
          @existing_location = Location.find_by_latitude_and_longitude(@latitude, @longitude)
  end

  def nearby_locations
      #Returns all locations in the database within 1 mile
      @nearby_locations = Location.near((@location), 1)
  end

  def location_params
      params.require(:location).permit(:name,:desc,:longitude,:latitude,:address_street,:address_city,:address_state,:address_zip,:address_country, :address)
  end

  def address_string
      street = params[:location][:address_street]
      city = params[:location][:address_city]
      state = params[:location][:address_state]
      zip = params[:location][:address_zip]
      country = params[:location][:address_country]
      address_search = params[:location][:address]
      # .compact removes the nil values so string can concatenate properly
      return [street, city, state, zip, country, address_search].compact.join(', ')
  end

  def address_hash
      form_entry_hash = {
          "name" => params[:location][:name],
          "desc" => params[:location][:desc],
          "address_street" => params[:location][:address_street],
          "address_city" => params[:location][:address_city],
          "address_state" => params[:location][:address_state],
          "address_zip" => params[:location][:address_zip],
          "address_country" => params[:location][:address_country],
          "latitude" => @lat_long_array[0],
          "longitude" => @lat_long_array[1],
          "address" => params[:location][:address],
          "user_id" => current_user.id
      }
  end

  def search_address_hash
      address_array = Geocoder.search(@lat_long_string)
      first_match = address_array.first
      # We can use if statements to determine which value to add to database if fields are filled in that contradict with reverse-geocode results
      if params[:location][:name] != ""
          name_value = params[:location][:name]
      else
          name_value = params[:location][:address]
      end
      search_hash = {
          "name" => name_value,
          "desc" => params[:location][:desc],
          "latitude" => @lat_long_array[0],
          "longitude" => @lat_long_array[1],
          "address_street" => first_match.street_number+" "+first_match.route,
          "address_city" => first_match.city,
          "address_state" => first_match.state_code,
          "address_zip" => first_match.postal_code,
          "address_country" => first_match.country_code,
          "address" => params[:location][:address],
          "user_id" => current_user.id
      }
  end

  def reverse_geocoded_address_hash
      address_array = Geocoder.search(@lat_long_string)
      first_match = address_array.first
      parsed_address_hash = {
          "name" => params[:location][:name],
          "desc" => params[:location][:desc],
          "address_street" => first_match.street_number+" "+first_match.route,
          "address_city" => first_match.city,
          "address_state" => first_match.state_code,
          "address_zip" => first_match.postal_code,
          "address_country" => first_match.country_code,
          "latitude" => first_match.latitude,
          "longitude" => first_match.longitude,
          "address" => params[:location][:address],
          "user_id" => current_user.id
      }
  end

end