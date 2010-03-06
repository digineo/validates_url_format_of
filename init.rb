module ValidatesUrlFormatOf
  
  module Pattern
    # Inspired by http://flanders.co.nz/2009/11/08/a-good-url-regular-expression-repost/s
    
    IPv4_PART = /\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]/  # 0-255
    IPv4      = /#{IPv4_PART}(\.#{IPv4_PART}){3}/
    AUTH      = /[^\s:@]+:[^\s:@]*@/
    DOMAIN    = /(xn--)?[^\W_]+([-.][^\W_]+)*\.[a-z]{2,6}/
    PORT      = /(6553[0-5]|655[0-2]\d|65[0-4]\d\d|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}|0)/ # 0-65535
    QUERY     = /((\?([-\w~!$+|.,*:]|%[a-f\d{2}])+=?([-\w~!$+|.,*:=]|%[a-f\d]{2})*)(&([-\w~!$+|.,*:]|%[a-f\d{2}])+=?([-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*/
    PATH      = /((\/([-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+/
    FRAGMENT  = /#([-\w~!$+|.,*:=]|%[a-f\d]{2})*/
  end
  
  def validates_url_format_of(*attr_names)
    configuration = {
      :allow_ip        => true,
      :allow_auth      => true,
      :allow_domain    => true,
      :allow_port      => true,
      :allow_query     => true,
      :allow_fragment  => true,
      :require_slash   => true,
      :protocols       => ["https?"]
    }
    configuration.update(attr_names.extract_options!)
    
    # protocol
    raise ArgumentError, "at least one protocol must be allowed" if configuration[:protocols].empty?
    regexp = "(" + configuration[:protocols].join("|") + ")"
    regexp << ":\\/\\/"
    
    # auth
    if configuration[:allow_auth]
      regexp << "(" << Pattern::AUTH.to_s << ")?"
    end
    
    # ip or domain
    parts = []
    parts << Pattern::IPv4   if configuration[:allow_ip]
    parts << Pattern::DOMAIN if configuration[:allow_domain]
    raise ArgumentError, "ip or domain must be allowed" if parts.empty?
    regexp << "(" << parts.join("|") << ")"
    
    # optional port
    if configuration[:allow_port]
      regexp << "(:" << Pattern::PORT.to_s << ")?"
    end
    
    # path
    regexp << Pattern::PATH.to_s
    
    # optional query
    if configuration[:allow_query]
      regexp << Pattern::QUERY.to_s
    end
    
    # optional fragment
    if configuration[:allow_fragment]
      regexp << "(" << Pattern::FRAGMENT.to_s << ")?"
    end
    
    configuration[:with] = Regexp.new("^" << regexp << "$","i")
    
    attr_names.each do |attr_name|
      validates_format_of(attr_name, configuration)
    end
  end
  
end

ActiveRecord::Base.extend(ValidatesUrlFormatOf)
