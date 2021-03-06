class CommentsController < ApplicationController
  require "net/http"
  require "json"
  require 'pp'
  

  def usage
  end
  
  
  def index
    @comments = {} # 全てのコメントはこれに入れてフロントへ送る
    comment_count = 0 # 上記commentsハッシュに入ってるコメントの数
    
    #セッションIDを作成
    if session[:user_id]
      @session_id = session[:user_id]
    else
      @session_id = rand(1..10000000000) 
      session[:user_id] = @session_id
    end
      
    @keyword = params[:twitter_keyword]
    
    if request.xhr? # jQuery(Ajax)からの呼び出しか判定
      
      # Twitter ===================================================================================
      if params[:twitter_keyword] != ""
        twitter = TwitterApi.new()
        
        begin
          # 最新のツイートのみリストで取得
          tweets, @latest_tweet_id = twitter.search(@keyword, 10, params[:latest_tweet_id])
          tweets_regexed = twitter.regex(tweets, @keyword)
          comment_count = push_comments(tweets_regexed, comment_count)
          
        rescue => exception
          flash[:notice] = exception
          tweets = []
        end
      else
        @latest_tweet_id = params[:latest_tweet_id]
      end #=========================================================================================
      
      # Youtube ===================================================================================
      @next_page_token = params[:next_page_token] # 前回取得時のnextPageToken(初回は0)
      if params[:youtube_url] != ""
        key = Settings.youtube_api.main_key # API Key
        youtube_uri_head = 'https://www.googleapis.com/youtube/v3/'
        youtube_url = params[:youtube_url]
        video_id = youtube_url.match(/https:.+v=(.+)$/)[1]
        @video_id = video_id
        @chat_id = params[:chat_id]
        if @chat_id == ""
          @chat_id = youtube_get_chatId(key, youtube_uri_head, @video_id)
        end
        youtube_quantity = 5 # 取得するコメントの数
        
        # Chat Idを利用してコメント, nextPageTokenを取得
        res_getChat_json, @next_page_token = youtube_get_chat(
          key, youtube_uri_head, @chat_id, youtube_quantity, @next_page_token)
        
        if res_getChat_json["items"] != []
          res_getChat_list_standard, youtube_status = youtube_fix_comments_list_standard(res_getChat_json)
          comment_count = push_comments(res_getChat_list_standard.reverse, comment_count)
        end
      end #=========================================================================================
      
      
    else # Ajaxリクエストじゃなかった場合
    end
    
    ActionCable.server.broadcast'room_channel',
    message:  {
      :comments => @comments, 
      :styles => false, 
      :session => @session_id,
      :status => youtube_status
    }
    
    #Ajaxリクエストならjsを返す
    respond_to do |format|
      format.html
      format.js { render 'comments/Ajax/index.js.erb' }
    end
  
  end
  
  def youtube_get_chatId(key, uri_head, video_id)
    uri_detail = 'videos?'
    uri_query  = "key=#{key}&id=#{@video_id}&part=liveStreamingDetails"
    
    uri_chatId = URI.parse(uri_head + uri_detail + uri_query)
    res_chatId = Net::HTTP::get_response(uri_chatId)
    res_chatId_json = JSON.parse(res_chatId.body)
    liveStreamingDetails =  res_chatId_json["items"][0]["liveStreamingDetails"]
    chat_id = liveStreamingDetails['activeLiveChatId']
        
    return chat_id
  end
  
  
  def youtube_get_chat(key, uri_head, chat_id, youtube_quantity, next_page_token)
    uri_detail = 'liveChat/messages?'
    # part = id: comment id, authorDetails: some details of commment user
    uri_query  = "key=#{key}&liveChatId=#{chat_id}&maxResults=#{youtube_quantity}&part=snippet" 
    
    if next_page_token != "0" # nextpagetokenがある場合
      uri_getChat = URI.parse( uri_head + uri_detail +  uri_query + "&pageToken=#{next_page_token}" )
    else # nextpagetokenがない場合(初回)
      uri_getChat = URI.parse( uri_head + uri_detail +  uri_query )
    end
    
    res_getChat = Net::HTTP::get_response(uri_getChat)  
    res_getChat_json = JSON.parse(res_getChat.body)
    next_page_token = res_getChat_json["nextPageToken"]
    
    return res_getChat_json, next_page_token
  end
  
  
  def youtube_fix_comments_list_standard(res_getChat_json)
    res_getChat_list = []
    status = true
    items = res_getChat_json["items"]
    if items #コメントが取得できたら配列にコメントを格納
      for item in res_getChat_json["items"] do
        res_getChat_list.push({:target => "Youtube", :text => item["snippet"]["displayMessage"]})
      end
    else
      status = false
    end
    return res_getChat_list, status
  end
  
  
  def push_comments(comments_list, comment_count)
    for item in comments_list do
      @comments[comment_count] = item
      comment_count += 1
    end
    return comment_count
  end


  def changeStyles
    ActionCable.server.broadcast'room_channel',
    message:  {
      :comments => false, 
      :styles => JSON.parse(params[:settings]),
      :session => @session_id
    }
  end
  
end
