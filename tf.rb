$:.unshift 'lib/'
require 'net/http'
require 'feedparser'
require 'uri'
require 'yaml'

require 'lib/hiveminder_api'
 
class GenericFeed
  
  attr_reader :name, :feed
  
  @url = ""
  @auth = ""
  @name = ""
  @plugin = nil
  @feeds = nil
  @tags = nil
  @hiveminder_config = nil
  
  def initialize(name, config)
    @url = config['url']
    @auth = config['auth']
    if config['plugin']
      @plugin = Object.const_get(config['plugin']).new
    end
    if config['tags']
      @tags = config['tags']
    end
  end
  
  def parse
    uri = URI.parse(@url)
    Net::HTTP.start(uri.host) do |http|
      req = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
      req.basic_auth @auth['login'],@auth['password'] if @auth
      response = http.request(req)
      @feed = FeedParser::Feed::new(response.body)
    end
  end
  
  def update(hiveminder_config)
    api = HiveminderApi.new(hiveminder_config)
    raise "Fuck, API not available" if (api.nil?)
    tags = @tags.split(" ")
    tag_query = ""
    tags.each do |t|
      tag_query << "/tag/#{t}"
    end
    
    tasks = api.download_tasks(tag_query)
    
    def tasks.find_by_summary(summary)
      found = self.select do |t|
        t['summary'] == summary
      end
      found[0] || nil
    end


    feed_items = @feed.items
    
    def feed_items.find_by_title(title)
      found = self.select do |t|
        t.title == title
      end
      found[0] || nil
    end
    
    #puts tasks.map{|t|t.summary}.join("\n")
    @feed.items.each do |item|
      #puts item.inspect
      if (tasks.find_by_summary(item.title).nil?)
        puts "adding: #{item.title} [#{@tags}]"
        api.add_task(item.title, :tags =>  @tags, :description => "#{item.content}\n---\nExternal Task from Feed '#{name}' - #{item.link}\nAdded by Jans Todo-Federator")
      end
    end
    
    # tasks missing in feed are considered done
    tasks.each do |t|
      #puts t.inspect
      if feed_items.find_by_title(t['summary']).nil?
        unless t['complete'] == 1
          puts "COMPLETE #{t['id']}"
          api.do_task(t['id'])
        end
      end
    end
    
  end
  
  
  
end


feeds = []
puts ENV['HOME']
config_file = "#{ENV['HOME']}/.todo_federator"
if (File.exists?(config_file))
  config = YAML.load_file(config_file)
else
  puts "No config file given. Create one at ~/.todo_federator"
  puts "See conf/example_conf for hints"
  exit 1
end
config['feeds'].each do |k, v|
  feeds << GenericFeed.new(k,v)
end

feeds.each do |f|
  f.parse
  f.update(config['hiveminder'])
end