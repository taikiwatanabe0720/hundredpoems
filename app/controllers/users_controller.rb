class UsersController < ApplicationController
  
  before_action :correct_user, only: [:edit, :update]
  include SessionsHelper
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "登録が完了しました。"
      redirect_to root_path
    else
      render "new"
    end
  end
  
  def update
    if @user.update(user_params)
      flash[:success] = "登録内容を変更しました"
      redirect_to root_path
    else
      render 'edit'
    end
  end
  
  def show
    @user = User.find(params[:id])
  end

  def travel
    user_station
    destination_station
    search_hotel
    if @stations_home['result'].nil? || @stations_des['result'].nil?
    else
      ekispert
      search_des_sta_lanlng
      @api_key = Rails.application.secrets.googleapi_js_key
    end
  end


  private
  
  def user_params
    params.require(:user).permit(:name, :email, :address, :password, :password_confirmation)
  end
  
  def correct_user
    @user = User.find(params[:id])
    redirect_to root_path if @user != current_user
  end

  def user_station
    @address = current_user.address

    # geocoding APIを呼び出すURLを作成する。
    @url = 'http://www.geocoding.jp/api/?v=1.1&q='
    @keyword = @address
    @escaped_url = URI.escape(@url + @keyword)
    
    #APIを呼び出す。
    @response = Faraday.get(@escaped_url)
    
    #XML形式で返ってきた結果を取得する。
    @geo = Hash.from_xml(@response.body)
    
    #SimpleAPIと連携
    #緯度経度を取得
    @lat = @geo['result']['coordinate']['lat']
    @lng = @geo['result']['coordinate']['lng']
    
    # APIを呼び出すURLを作成
    @url_simpleapi = 'http://map.simpleapi.net/stationapi?x=' + @lng + '&y=' + @lat + '&output=xml'
    @escaped_url_simpleapi = URI.escape(@url_simpleapi)
    
    # API を呼び出す
    @response_simpleapi = Faraday.get(@escaped_url_simpleapi)

    # XML 形式で返ってきた結果を取得する
    @stations_home = Hash.from_xml(@response_simpleapi.body)
  end
  
  def destination_station
    @des = Destination.find_by(pid: params[:poem_id])
    @des_lng = @des.longitude
    @des_lat = @des.latitude
    
    # APIを呼び出すURLを作成
    @url_simpleapi = 'http://map.simpleapi.net/stationapi?x=' + @des_lng.to_s + '&y=' + @des_lat.to_s + '&output=xml'
    @escaped_url_simpleapi = URI.escape(@url_simpleapi)
    
    # API を呼び出す
    @response_simpleapi = Faraday.get(@escaped_url_simpleapi)

    # XML 形式で返ってきた結果を取得する
    @stations_des = Hash.from_xml(@response_simpleapi.body)
  end

  def google_directions
    key1 = Rails.application.secrets.google_direction_key
    @latlng_ori = @lat + ',' + @lng
    @latlng_des = @des.latitude.to_s + ',' + @des.longitude.to_s
    url = 'https://maps.googleapis.com/maps/api/directions/json?mode=transit&origin=' + @latlng_ori + '&destination=' + @latlng_des + '&key=' + key1
    escaped_url = URI.escape(url)
    response = Faraday.get(escaped_url)
    @directions = JSON.parse(response.body)
    @route = @directions['routes'].first
  end
  
  
  def ekispert
    # 自宅の県名を抽出  #.class
    if @stations_home['result']['station'].class == Hash then
      @str_pref_h = @stations_home['result']['station']['prefecture']
    elsif @stations_home['result']['station'].class == Array then
      @str_pref_h = @stations_home['result']['station'][0]['prefecture']
    end
    # 自宅最寄り駅リストを取得
    @sta_h_arr = @stations_home['result']['station']
    # 自宅最寄り駅の名前を取得
    if @sta_h_arr.class == Hash then
      @station_h = @sta_h_arr['name']
    elsif @sta_h_arr.class == Array then
      @station_h = @sta_h_arr[0]['name']
    end
    @station_h.slice!(@station_h.index('駅'))
    url_str_h = 'http://api.ekispert.jp/v1/json/station/light?key=' + Rails.application.secrets.ekispert_key + '&name=' + @station_h
    @res_h = Faraday.get(url_str_h)
    @res_h_arr = JSON.parse(@res_h.body)["ResultSet"]["Point"]
    if @res_h_arr.class == Hash then
      from_code = @res_h_arr["Station"]["code"]
    elsif @res_h_arr.class == Array then
      @res_h_arr.each_with_index do |s, index|
        if s['Station']['Name'] == @station_h && s['Prefecture']['Name'] == @str_pref_h
          from_code = s["Station"]["code"]
        end
      end
      if from_code.nil?
        @res_h_arr.each do |s|
          if s['Station']['Name'].include?(@station_h + '(') && s['Prefecture']['Name'] == @str_pref_h
            from_code = s["Station"]["code"]
          end
        end
      end
    end
    # 目的地の県名を抽出
    if @stations_des['result']['station'].class == Hash then
      @str_pref_d = @stations_des['result']['station']['prefecture']
    elsif @stations_des['result']['station'].class == Array then
      @str_pref_d = @stations_des['result']['station'][0]['prefecture']
    end
    # 目的地最寄り駅リストを取得
    @sta_d_arr = @stations_des['result']['station']
    # 目的地最寄り駅の名前を取得
    if @sta_d_arr.class == Hash then
      @station_d = @sta_d_arr['name']
    elsif @sta_d_arr.class == Array then
      @station_d = @sta_d_arr[0]['name']
    end
    @station_d.slice!(@station_d.index('駅'))
    url_str_d = 'http://api.ekispert.jp/v1/json/station/light?key=' + Rails.application.secrets.ekispert_key + '&name=' + @station_d
    @res_d = Faraday.get(url_str_d)

    
    @res_d_arr = JSON.parse(@res_d.body)["ResultSet"]["Point"]
    
    if @res_d_arr.class == Hash then
      to_code = @res_d_arr["Station"]["code"]
    else
      @res_d_arr.each_with_index do |s, index|
        if ( s['Station']['Name'] == @station_d || s['Station']['Name'] == @station_d + '(' + @str_pref_d + ')') && s['Prefecture']['Name'] == @str_pref_d
          to_code = s["Station"]["code"]
        end
      end
      if to_code.nil?
        @res_d_arr.each do |s|
          if s['Station']['Name'].include?(@station_d + '(') && s['Prefecture']['Name'] == @str_pref_d
            to_code = s["Station"]["code"]
          end
        end
      end
    end
    
    url_str_r = 'http://api.ekispert.jp/v1/json/search/course/light?key='+ Rails.application.secrets.ekispert_key + '&from=' + from_code + '&to=' + to_code
    @ResourceURL = JSON.parse(Faraday.get(url_str_r).body)["ResultSet"]["ResourceURI"]
  end
  
  def search_hotel
    # 緯度経度の座標変換　(世界測地系→日本測地系)
    @des = Destination.find_by(pid: params[:poem_id])
    @des_lat_ja = @des.latitude * 1.000106961 - @des.longitude * 0.000017467 - 0.004602017
    @des_lng_ja = @des.longitude * 1.000083049 + @des.latitude * 0.000046047 - 0.010041046
    
    @des_lat_int = (@des_lat_ja * 3600000).to_i
    @des_lng_int = (@des_lng_ja * 3600000).to_i
    
    # APIを呼び出すURLを作成
    @jaran_url = 'http://jws.jalan.net/APIAdvance/HotelSearch/V1/?order=4&xml_ptn=1&pict_size=0&key=' + Rails.application.secrets.jaran_key + '&x=' + @des_lng_int.to_s + '&y=' + @des_lat_int.to_s + '&range=3'
    @escaped_url_jaran = URI.escape(@jaran_url)

    # API を呼び出す
    @response_jaran = Faraday.get(@escaped_url_jaran)

    # XML 形式で返ってきた結果を取得する
    @hotel = Hash.from_xml(@response_jaran.body)
    @hotel_info = @hotel['Results']['Hotel']
    if @hotel_info.class == Hash
      @hotel_info = [@hotel_info]
    end
  end
  
  def search_des_sta_lanlng
    # APIを呼び出すURLを作成
    if @res_d_arr.class == Hash
      @yomi = @res_d_arr['Station']['Yomi']
    else
      @res_d_arr.each_with_index do |s, index|
        if ( s['Station']['Name'] == @station_d || s['Station']['Name'] == @station_d + '(' + @str_pref_d + ')') && s['Prefecture']['Name'] == @str_pref_d
          @yomi = s["Station"]["Yomi"]
        end
      end
      if @yomi.nil?
        @res_d_arr.each do |s|
          if s['Station']['Name'].include?(@station_d + '(') && s['Prefecture']['Name'] == @str_pref_d
            @yomi = s["Station"]["Yomi"]
          end
        end
      end
    end
    if @yomi.length < 2 || @yomi.index("えき").nil?
      @keyword_sta = @yomi + 'えき'
    else
      @keyword_sta = @yomi
    end
    @search_latlng_url = "https://maps.googleapis.com/maps/api/geocode/json?address=" + @keyword_sta + "&region=jp&key=" + Rails.application.secrets.googleapi_js_key
    @escaped_url_search_latlng = URI.escape(@search_latlng_url)
    
    # APIを呼び出し結果を出力
    @LatLng_des_station = JSON.parse(Faraday.get(@escaped_url_search_latlng).body)['results'][0]['geometry']['location']
    @tmp = JSON.parse(Faraday.get(@escaped_url_search_latlng).body)['results']
  end
end