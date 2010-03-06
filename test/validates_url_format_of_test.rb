require 'rubygems'
require 'test/unit'
require 'active_record'
require "#{File.dirname(__FILE__)}/../init"

class Model
  begin  # Rails 3
    include ActiveModel::Validations
  rescue NameError  # Rails 2.*
	  # ActiveRecord validations without database
    # Thanks to http://www.prestonlee.com/archives/182
    def save() end
    def save!() end
    def new_record?() false end
    def update_attribute() end  # Needed by Rails 2.1.
    def self.human_name() end
    def self.human_attribute_name(_) end
    def initialize
      @errors = ActiveRecord::Errors.new(self)
      def @errors.[](key)  # Return errors in same format as Rails 3.
        Array(on(key))
      end
    end
    def self.self_and_descendants_from_active_record() [self] end
    def self.self_and_descendents_from_active_record() [self] end  # Needed by Rails 2.2.
    include ActiveRecord::Validations
  end
    
  extend ValidatesUrlFormatOf

  attr_accessor :url_complete
  validates_url_format_of :url_complete
  
  attr_accessor :url_simple
  validates_url_format_of :url_simple,
    :allow_ip       => false,
    :allow_auth     => false,
    :allow_domain   => true,
    :allow_port     => false,
    :allow_query    => false,
    :allow_fragment => false
  
  attr_accessor :url_without_domain
  validates_url_format_of :url_without_domain, :allow_domain => false
  
  attr_accessor :url_without_ip
  validates_url_format_of :url_without_ip, :allow_ip => false
  
  attr_accessor :url_without_port
  validates_url_format_of :url_without_port, :allow_port => false
  
  attr_accessor :url_without_query
  validates_url_format_of :url_without_query, :allow_query => false
  
  attr_accessor :url_without_fragment
  validates_url_format_of :url_without_fragment, :allow_fragment => false
  
  attr_accessor :custom_url
  validates_url_format_of :custom_url, :message => 'custom message'
end

class ValidatesUrlFormatOfTest < Test::Unit::TestCase
  
  def test_simple
    assert_urls_valid :url_simple,
      "http://example.com/"
      "http://www.example.com/a/"
      "https://www.example.com/a/b/a-index.html"
    assert_urls_invalid :url_simple,
      'http://192.168.2.1/',
      'http://example.com/?abc',
      'http://www.example.com/#foo',
      'http://user:pass@example.com/'
  end
  
  def test_without_ip
    assert_urls_valid :url_without_ip, 
      'http://example.com/',
      'http://example.com:5321/',
      'http://example.com/index',
      'http://example.com/index?foo=bar&x=y',
      'http://example.com/index#anchor',
      'http://example.com/index?foo=bar&x=y#anchor'
      
    assert_urls_invalid :url_without_ip,
      'http://1.1.1/'
      'http://192.168.2.1/'
  end
  
  def test_without_port
    assert_urls_valid :url_without_port, 
      'http://example.com/',
      'http://1.1.1.1/index',
      'http://123.123.123.123/index?foo=bar&x=y',
      'http://example.com/index#anchor',
      'http://example.com/index?foo=bar&x=y#anchor'
      
    assert_urls_invalid :url_without_port,
      'http://example.com:/',
      'http://1.1.1.1:1234/index',
      'http://123.123.123.123:80/index?foo=bar&x=y',
      'http://example.com:70000/index#anchor',
      'http://example.com:999/index?foo=bar&x=y#anchor'
  end
  
  def test_without_query
    assert_urls_valid :url_without_query, 
      'http://example.com/',
      'http://1.1.1.1/index',
      'http://example.com:421/index#anchor'
      
    assert_urls_invalid :url_without_query,
      'http://example.com?',
      'http://example.com/?',
      'http://1.1.1.1:1234/index?a=b'
  end
  
  def test_without_anchor
    assert_urls_valid :url_without_fragment,
      'http://example.com/',
      'http://1.1.1.1/index',
      'http://top:secret@example.com:421/stuff/?foo=bar'
      
    assert_urls_invalid :url_without_fragment,
      'http://example.com#',
      'http://example.com/#',
      'http://1.1.1.1/index#chapter-2'
  end
  
  def test_should_allow_valid_urls
    assert_urls_valid :url_complete,
      'http://example.com/',
      'http://www.example.com/',
      'http://sub.domain.example.com/',
      'http://bbc.co.uk/',
      'http://example.com/?foo',
      'http://example.com:8000/',
      'http://www.sub.example.com/page.html?foo=bar&baz=%23#anchor',
      'http://user:pass@example.com/',
      'http://user:@example.com/',
      'http://example.com/~user',
      'http://example.xy/',  # Not a real TLD, but we're fine with anything of 2-6 chars
      'http://example.museum/',
      'http://1.0.255.249/',
      'http://1.2.3.4:80/',
      'HttP://example.com/',
      'https://example.com/',
#      'http://räksmörgås.nu/',  # IDN
      'http://xn--rksmrgs-5wao1o.nu/'  # Punycode
  end
  
  def test_should_reject_invalid_urls
    assert_urls_invalid :url_complete,
      nil, 1, "", " ", "url",
      'http://example.com',
      "www.example.com",
      "http://ex ample.com",
      "http://example.com/foo bar",
      'http://example.com?foo',
      'http://example.com:8000',
      'http://user:pass@example.com',
      'http://user:@example.com',
      'http://256.0.0.1',
      'http://u:u:u@example.com',
      'http://r?ksmorgas.com',
      'http://example.com/?url=http://example.com',
      
      # Explicit TLD root period
      'http://example.com.',
      'http://example.com./foo',
      
      # These can all be valid local URLs, but should not be considered valid
      # for public consumption.
      "http://example",
      "http://example.c",
      'http://example.toolongtld'
  end
  
  def test_can_override_defaults
    object = build_object(:custom_url, "x")
    assert_equal ['custom message'], object.errors[:custom_url]
  end
  
  private
  
  def build_object(attribute,value)
    object = Model.new
    object.send "#{attribute}=", value
    object.valid?
    object
  end
  
  def assert_urls_valid(attribute, *urls)
    for url in urls
      object = build_object(attribute, url)
      assert object.errors[attribute].empty?, "#{url.inspect} should have been accepted"
    end
  end
  
  def assert_urls_invalid(attribute, *urls)
    for url in urls
      object = build_object(attribute, url)
      assert !object.errors[attribute].empty?, "#{url.inspect} should have been rejected"
    end
  end
  
end
