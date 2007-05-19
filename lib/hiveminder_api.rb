require 'rubygems'
require 'http-access2'
#require 'jifty_api'
#require 'test/unit'

class HiveminderApi
  @client = nil
  @conf = {}
  
  @session_id
  def initialize(conf)
    @conf = conf
    @client = HTTPAccess2::Client.new(@conf['proxy'],"RubyHiveminderApi", "jan@krutisch.de")
    @moniker = 'humbug'
    login
  end
  
  def login
    res = call('Login', :address => @conf['mail'], :password => @conf['password'])
    #session_id
  end
    
  def call(klass, params)
    jifty_params = { "J:A-#{@moniker}" => klass}
    params.each do |k,v|
      jifty_params["J:A:F-#{k.to_s}-#{@moniker}"] = v.to_s
    end
    #puts jifty_params.inspect
    res = @client.post(@conf['site'] + "/__jifty/webservices/yaml",HTTP::Message.escape_query(jifty_params))
    if res.status = HTTP::Status::OK
      monika = YAML.load(res.body.content)[@moniker]
      return monika.nil? ? nil : monika.value
    else
      raise "Bad Status from Hiveminder: #{res.status}"
    end
  end
  
  def download_tasks(query="not/complete/starts/before/tomorrow/accepted/nothing")
    res = call('DownloadTasks', :query => query, :format => 'yaml')
    return nil if res.nil?      
    YAML.load(res['_content']['result']) 
  end
  
  def add_task(summary, options)
    task = options.select{|k,v| !%w(tags group_id priority due hide description).include?(k.to_s) }
    task = {:owner_id => @conf['mail'], :summary => summary}.merge(options)
    call('CreateTask', task)
  end

  def do_task(id)
    call('UpdateTask', :id => id, :complete => 1)
  end
  
private
  def session_id
    cookies = @client.cookie_manager.find(URI.parse(@conf['site'] + "/__jifty/webservices/yaml"))
    if matching = cookies.match(/JIFTY_SID_\d+=([^;]+)/)
      @session_id = matching[1]
    else
      @session_id = nil
    end
  end
end


# class HiveminderApiTests < Test::Unit::TestCase
#   def test_basic_init
#     api = HiveminderApi.new({'site' => 'http://hiveminder.com', 'mail' => 'hmtest@rasterizer.de', 'password' => 'testaccount' })
#     assert_not_nil api
#     res = api.add_task('Test-Taks', :tags => 'test ignore')
#     puts res.inspect
#     tasks = api.download_tasks
#     assert_not_nil tasks 
#     assert tasks.size > 0
#   end
# end