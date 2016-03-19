require 'bundler'
require './auth.rb'
require './settings.rb'
require 'yaml'
Bundler.require
tokens = {}
unless File.exist? "./.config"
  puts "初回起動時は設定が必要です"
  auth = Auth.new Consumer_key,Consumer_secret
  puts "行け #{auth.authorize_url}"
  print "PINを入力してね=> ";auth.pin gets.to_i
  tokens[:access_token] = auth.access_token
  tokens[:access_token_secret] = auth.access_token_secret
  open("./.config","w") do |f|
    YAML.dump(tokens,f)
  end
end
if File.exist? "./.config"
  tokens = YAML.load_file "./.config"
end

begin
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = Consumer_key
    config.consumer_secret     = Consumer_secret
    config.access_token        = tokens[:access_token]
    config.access_token_secret = tokens[:access_token_secret]
  end

  my_screen_name =  client.user.screen_name
  my_id = client.user.id

  retry_count = 0
  client2 = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = Consumer_key
    config.consumer_secret     = Consumer_secret
    config.access_token        = tokens[:access_token]
    config.access_token_secret = tokens[:access_token_secret]
  end

  client2.user do |object|
    if object.is_a? Twitter::Tweet
      if object.user.id == my_id && object.text =~ /^@#{my_screen_name}\s###update_name###\s+/
        puts object.text.sub /^@#{my_screen_name}\s###update_name###\s/,""
        new_user_name = object.text.sub /^@#{my_screen_name}\s###update_name###\s/,""
        new_user_name.sub! /\n/,""
        client.update_profile(name:new_user_name) if new_user_name.length <= 20
      end
    end
  end
rescue Twitter::Error::ServerError => e
  p e
  retry_count += 1
  if retry_count < 5 # エラーが出たら再接続（再ツイートではない）
    sleep 30
    retry
  end
rescue Twitter::Error::ClientError => e
  p e
rescue => e
  p e
else
  retry_count = 0
end


