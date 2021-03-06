# Cloud Foundry 2012.02.03 Beta
# Copyright (c) [2009-2012] VMware, Inc. All Rights Reserved. 
# 
# This product is licensed to you under the Apache License, Version 2.0 (the "License").  
# You may not use this product except in compliance with the License.  
# 
# This product includes a number of subcomponents with
# separate copyright notices and license terms. Your use of these
# subcomponents is subject to the terms and conditions of the 
# subcomponent's license, as noted in the LICENSE file. 

require File.expand_path("../../spec_helper", __FILE__)

require "rack/test"
require "json"

describe ACM::Controller::ApiController do
  include Rack::Test::Methods

  def app
    @app ||= ACM::Controller::RackController.new
  end

  describe "when creating a permission set" do
    before(:each) do
      @logger = ACM::Config.logger
    end

    it "should create it with the correct permission set" do
      basic_authorize "admin", "password"

      permission_set_data = {
        :name => "app_space",
        :additional_info => "{component => cloud_controller}",
        :permissions => [:read_appspace.to_s, :write_appspace.to_s, :delete_appspace.to_s]
      }

      post "/permission_sets", {}, { "CONTENT_TYPE" => "application/json", :input => permission_set_data.to_json() }
      @logger.debug("post /permission_sets last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should eql("http://example.org/permission_sets/#{body[:name]}")

      body[:name].to_s.should eql(permission_set_data[:name].to_s)
      body[:permissions].sort().should eql(permission_set_data[:permissions].sort())
      body[:additional_info].should eql(permission_set_data[:additional_info])

      body[:meta][:created].should_not be_nil
      body[:meta][:updated].should_not be_nil
      body[:meta][:schema].should eql("urn:acm:schemas:1.0")
    end

    it "should be able to create a permission set without any assigned permissions" do
      basic_authorize "admin", "password"

      permission_set_data = {
        :name => "app_space"
      }

      post "/permission_sets", {}, { "CONTENT_TYPE" => "application/json", :input => permission_set_data.to_json() }
      @logger.debug("post /permission_sets last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should eql("http://example.org/permission_sets/#{body[:name]}")

      body[:name].to_s.should eql(permission_set_data[:name].to_s)
      body[:permissions].size().should eql(0)
      body[:additional_info].should eql(permission_set_data[:additional_info])

      body[:meta][:created].should_not be_nil
      body[:meta][:updated].should_not be_nil
      body[:meta][:schema].should eql("urn:acm:schemas:1.0")
    end

    it "should not be possible to create a permission set without a name" do
      basic_authorize "admin", "password"

      permission_set_data = {
        :name => nil
      }

      post "/permission_sets", {}, { "CONTENT_TYPE" => "application/json", :input => permission_set_data.to_json() }
      @logger.debug("post /permission_sets last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1001)
      body[:description].should include("Invalid request")
    end

    it "should not be possible to create a permission set with invalid json" do
      basic_authorize "admin", "password"

      permission_set_data = {
        :name => "app_space",
        :permissions => "read"
      }

      post "/permission_sets", {}, { "CONTENT_TYPE" => "application/json", :input => permission_set_data.to_json() }
      @logger.debug("post /permission_sets last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1001)
      body[:description].should include("Invalid request")
    end

    it "should not be possible to create a permission set empty input" do
      basic_authorize "admin", "password"

      post "/permission_sets", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("post /permission_sets last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1001)
      body[:description].should include("Invalid request")
    end

  end

  describe "when reading a permission set" do

    before(:each) do
      @logger = ACM::Config.logger
    end

    it "should read the correct permission set" do
      basic_authorize "admin", "password"

      permission_set_data = {
        :name => "www_staging",
        :additional_info => "{component => cloud_controller}",
        :permissions => [:read_appspace, :write_appspace, :delete_appspace]
      }

      post "/permission_sets", {}, { "CONTENT_TYPE" => "application/json", :input => permission_set_data.to_json() }
      @logger.debug("post /permission_sets last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should eql("http://example.org/permission_sets/#{body[:name]}")

      original_ps = last_response.body

      get "/permission_sets/#{body[:name]}", {}, { "CONTENT_TYPE" => "application/json" }
      @logger.debug("get /permission_sets/#{body[:id]} last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      fetched_ps = last_response.body
      last_response.original_headers["Location"].should be_nil

      original_ps.should eql(fetched_ps)

    end

    it "should return an error if an invalid permission set is requested" do
      basic_authorize "admin", "password"

      get "/permission_sets/12345", {}, { "CONTENT_TYPE" => "application/json" }
      last_response.status.should eql(404)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1000)
      body[:description].should include("not found")
    end

    it "should return an error if an empty permission set is requested" do
      basic_authorize "admin", "password"

      get "/permission_sets", {}, { "CONTENT_TYPE" => "application/json" }
      last_response.status.should eql(404)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8, schema=urn:acm:schemas:1.0")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1000)
      body[:description].should include("not found")
    end

  end
end
