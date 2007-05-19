class JiftyApi
  
  @client = nil
  
 
 def initialize(proxy)
   @conf = conf
   @client = HTTPAccess2::Client.new(proxy,"RubyHiveminderApi", "")
 end
 
 def call(klass, params)
   # TODO: Refactor into a multi_call which allows for more than one function call per request
   moniker = 'fnord'
   jifty_params = { "J:A-#{@moniker}" => klass}
   params.each do |k,v|
     jifty_params["J:A:F-#{k.to_s}-#{@moniker}"] = v.to_s
   end
   #puts jifty_params.inspect
   res = @client.post(@conf['site'] + "/__jifty/webservices/yaml",HTTP::Message.escape_query(jifty_params))
   if res.status = HTTP::Status::OK
     moniker_result = YAML.load(res.body.content)[@moniker]
     return moniker_result.nil? ? nil : moniker_result.value
   else
     raise "Bad Status from Hiveminder: #{res.status}"
   end
 end
 
 
 
end