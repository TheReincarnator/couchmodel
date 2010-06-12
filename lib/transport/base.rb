require 'uri'
require 'cgi'
require 'net/http'

module Transport

  # Common transport layer for http transfers.
  class Base

    attr_reader :http_method
    attr_reader :url
    attr_reader :options
    attr_reader :headers
    attr_reader :parameters
    attr_reader :body
    attr_reader :response

    def initialize(http_method, url, options = { })
      @http_method  = http_method
      @uri          = URI.parse url
      @headers      = options[:headers]     || { }
      @parameters   = options[:parameters]  || { }
      @body         = options[:body]
    end

    def perform
      initialize_request_class
      initialize_request_path
      initialize_request
      initialize_request_body
      perform_request
    end

    private

    def initialize_request_class
      request_class_name = @http_method.to_s.capitalize
      raise NotImplementedError, "the request method #{http_method} is not implemented" unless Net::HTTP.const_defined?(request_class_name)
      @request_class = Net::HTTP.const_get request_class_name
    end

    def initialize_request_path
      serialize_parameters
      @request_path = @uri.path + @serialized_parameters
    end

    def serialize_parameters
      quote_parameters
      @serialized_parameters = if @parameters.nil? || @parameters.empty?
        ""
      else
        "?" + @quoted_parameters.collect do |key, value|
          value.is_a?(Array) ?
            value.map{ |element| "#{key}=#{element}" }.join("&") :
            "#{key}=#{value}"
        end.join("&")
      end
    end

    def quote_parameters
      @quoted_parameters = { }
      @parameters.each do |key, value|
        encoded_key = CGI.escape(key.to_s)
        @quoted_parameters[encoded_key] = value.is_a?(Array) ? value.map{ |element| CGI.escape element } : CGI.escape(value)
      end
    end

    def initialize_request
      @request = @request_class.new @request_path, @headers
    end

    def initialize_request_body
      return unless [ :post, :put ].include?(@http_method.to_sym)
      @request.body = @body ? @body : @serialized_parameters.sub(/^\?/, "")
    end

    def perform_request
      @response = Net::HTTP.start(@uri.host, @uri.port) do |connection|
        connection.request @request
      end
    end

    def self.request(http_method, url, options = { })
      transport = new http_method, url, options
      transport.perform
      transport.response
    end

  end

end
