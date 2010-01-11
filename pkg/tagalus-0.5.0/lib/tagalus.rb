require 'net/http'
require 'time'
require File.dirname(__FILE__)+"/xmlstruct.rb"
# = tagalus
#
# This module encapsulates the API for tagal.us, a site which helps users
# define tags on twitter or other websites. The basic elements are tags,
# definitions, and comments - and these 3 objects can be written and read
# to/from tagal.us using this gem.
#
# There's just 6 useful methods - 3 that read, and 3 that write.
#
# Exmaple usage:
#    acc = tagalus::Account.new("1290185015890")
#    acc.define("apisandbox") #=> <Definition>
#    acc.comments("apisandbox").each do |comm|
#      puts comm.text+"\n"
#    end
#    acc.post_comment "apisandbox", "Testing, 1,2,3!" #=> <Comment>
#
# This module uses the Carboni.ca XML base, which means you can set which
# XML parser it will use - simply use
#    tagalus.parser = :nokogiri # can be :nokogiri, :hpricot, :rexml, or :libxml
# to change the parser.
#
module Tagalus
  VERSION = '0.5.0'
  
  API_ROOT = 'api.tagal.us'
  
  class TagalusError < StandardError; end
  
  # The list of parsers you are allowed to use with the tagalus module.
  AVAILABLE_PARSERS = [:nokogiri, :hpricot, :rexml, :libxml]
  # Sets which XML parser to use. Must be in AVAILABLE_PARSERS
  def self.parser=(val)
    raise UnsupportedParserError.new("An unsupported parser was provided: #{val}") unless AVAILABLE_PARSERS.include? val
    @@parser = val
    case @@parser
    when :nokogiri
      require 'nokogiri'
    when :hpricot
      require 'hpricot'
    when :rexml
      require 'rexml/document'
    when :libxml
      require 'libxml'
    end
  end
  Tagalus.parser = :rexml
  def self.parser
    @@parser
  end
  
  # = Account
  #
  # Encapsulates a user's account on tagal.us. Currently the tagal.us API is rather
  # limited, but it is fully supported. Example usage:
  #
  #    acc = tagalus::Account.new("1290185015890")
  #    acc.define("apisandbox") #=> <Definition>
  #    acc.post_comment "apisandbox", "Testing, 1,2,3!" #=> <Comment>
  #
  class Account
    
    include CanParse
    
    # Creates a new Account object, with API Key +key+. This key is necessary to
    # create tags, definitions, and comments on the server. Read-only operations don't
    # require a key.
    def initialize(key="")
      @api_key = key
    end
    
    # Retrieves the most authoritative definition of the tag with name or id +tag+
    def define tag
      path = "/tag/#{tag}/show.xml"
      doc = http_get path
      Definition.new(:xml => xpath(doc,"//definition").first)
    end
    
    # Retrieves all the definitions for the tag with name or id +tag+
    def all_definitions tag
      path = "/definition/#{tag}/show.xml"
      doc = http_get path
      
      definitions = []
      xpath(doc,"//definition").each do |entry|
        definitions << Definition.new(:xml => entry)
      end
      definitions
    end
    
    # Retrieves all the comments for the tag with name or id +tag+
    def comments tag
      path = "/comment/#{tag}/show.xml"
      doc = http_get path
      
      comments = []
      xpath(doc, "//comment").each do |entry|
        comments << Comment.new(:xml => entry)
      end
      comments
    end
    
    # creates a comment on tagal.us. The tag must have already been created, or an error will be
    # thrown. +comment+ is a string. +tag+ can be either a tagalus::Tag, String, or Fixnum.
    def post_comment tag, comment
      tag_params = (tag.is_a? String) ? { :the_tag => tag } : {:tag_id => (tag.is_a? Tag) ? tag.id : tag }
      tag_params.merge! :the_comment => comment
      path = "/comment/create.xml"
      doc = http_post path, tag_params
      Comment.new(:xml => doc)
    end
    
    # defines a tag on tagal.us. The tag must have already been created, or an error will be
    # thrown. +definition+ is a string. +tag+ can be either a tagalus::Tag, String, or Fixnum.
    def post_definition tag, definition
      tag_params = (tag.is_a? String) ? { :the_tag => tag } : {:tag_id => (tag.is_a? Tag) ? tag.id : tag }
      tag_params.merge! :the_definition => definition
      path = "/definition/create.xml"
      doc = http_post path, tag_params
      puts doc.to_s
      Definition.new(:xml => doc)
    end
    
    # creates a tag on tagal.us. The tag must not have already been created, or an error will be
    # thrown. +tag+ and +definition+ are both strings.
    def create_tag tag, definition
      tag_params =  { :the_tag => tag, :the_definition => definition } 
      path = "/tag/create.xml"
      doc = http_post path, tag_params
      
      definition = Definition.new(:xml => xpath(doc,"//definition").first)
      result = Tag.new(:xml => doc)
      result.definitions = [definition]
      result
    end
    
    # Helper method for retrieving URLs via GET while escaping parameters and including API-specific
    # parameters
    def http_get(path, query_params = {})
      query_params.merge!(:api_key => @api_key, :api_version => "0001")
      http = Net::HTTP.new API_ROOT
      path = path + "?" + URI.escape(query_params.map {|k,v| "#{k}=#{v}"}.join("&"), /[^-_!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]/n)
      resp = http.get(path)
      raise tagalus::tagalusError.new("Error while querying the path #{path}") if resp.body =~ /something went wrong/
      xml_doc(resp.body)
    end
    
    # Helper method for retrieving URLs via POST while escaping parameters and including API-specific
    # parameters
    def http_post(path, query_params = {})
      query_params.merge!(:api_key => @api_key, :api_version => "0001")
      http = Net::HTTP.new API_ROOT
      data = URI.escape(query_params.map {|k,v| "#{k}=#{v}"}.join("&"), /[^-_!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]/n)
      resp = http.post(path, data)
      xml_doc(resp.body)
    end
  end
  
  # = Tag
  # Represents a tag retrieved or posted to tagal.us. Fields available:
  #  [:id] - the ID of the definition
  #  [:tag] - the name of the tag being defined
  #  [:updated_at] - When the comment was last updated
  #  [:created_at] - When the comment was initially created
  class Tag < XMLStruct
    attr_accessor :definitions
    field :tag, :node, "//the-tag"
    field :id, :node, "//id"
    field :updated_at, :proc, lambda { |entry| Time.xmlschema(xml_content(xpath(entry,"//updated-at").first)) }
    field :created_at, :proc, lambda { |entry| Time.xmlschema(xml_content(xpath(entry,"//created-at").first)) }
    def post_initialize; @id = @id.to_i; end
  end
  
  # = Definition
  # Represents a definition retrieved or posted on tagal.us. Fields available:
  #  [:id] - the ID of the definition
  #  [:meta_info] - no idea what this is, seems to always be empty
  #  [:tag_id] - the ID of the tag being defined
  #  [:text] - the text of the definition
  #  [:user_id] - the ID of the user posting the comment
  #  [:updated_at] - When the comment was last updated
  #  [:created_at] - When the comment was initially created
  #  [:authority] - The number of up-votes minus the number of down-votes.
  class Definition < XMLStruct
    field :text, :node, ".//the-definition"
    field :tag_id, :node, ".//tag-id"
    field :id, :node, ".//id"
    field :authority, :node, ".//authority"
    field :user_id, :node, ".//user-id"
    field :meta_info, :node, ".//meta-info"
    field :updated_at, :proc, lambda { |entry| Time.xmlschema(xml_content(xpath(entry,".//updated-at").first)) }
    field :created_at, :proc, lambda { |entry| Time.xmlschema(xml_content(xpath(entry,".//created-at").first)) }
    def post_initialize
      @tag_id = @tag_id.to_i; @id = @id.to_i; @user_id = @user_id.to_i
    end
  end
  
  # = Comment
  # Represents a comment retrieved from tagal.us. Fields available:
  #  [:id] - the ID of the comment
  #  [:meta_info] - no idea what this is, seems to always be empty
  #  [:tag_id] - the ID of the tag
  #  [:text] - the text of the comment
  #  [:user_id] - the ID of the user posting the comment
  #  [:updated_at] - When the comment was last updated
  #  [:created_at] - When the comment was initially created
  class Comment < XMLStruct
    field :id, :node, "id"
    field :meta_info, :node, "meta_info"
    field :tag_id, :node, "tag-id"
    field :text, :node, "the-comment"
    field :user_id, :node, "user-id"
    field :updated_at, :proc, lambda { |entry| Time.xmlschema(xml_content(xpath(entry,"//updated-at").first)) }
    field :created_at, :proc, lambda { |entry| Time.xmlschema(xml_content(xpath(entry,"//created-at").first)) }
    def post_initialize #:nodoc:
      @tag_id = @tag_id.to_i; @id = @id.to_i; @user_id = @user_id.to_i
    end
  end
end
