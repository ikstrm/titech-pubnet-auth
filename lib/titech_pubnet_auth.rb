# -*- coding: utf-8 -*-

require 'mechanize'
require 'uri'
require 'yaml'

$:.unshift File.dirname(__FILE__)
require 'titech_pubnet_auth/extension'


class TitechPubnetAuth
  BASE_DIR = File.expand_path('..',File.dirname(__FILE__))

  SAMPLE_URI = URI.parse('http://github.com')

  def initialize
    @agent, @agent_with_proxy = Mechanize.new, Mechanize.new
    [@agent,@agent_with_proxy].each{|agent|
      agent.follow_meta_refresh = true
      agent.open_timeout = 3
    }
    proxy = YAML.load(File::open(File::expand_path('config/proxy.yml',BASE_DIR),'r'))['http_proxy']
    @agent_with_proxy.set_proxy(proxy['ip'], proxy['port'])
    
    @private = YAML.load(File::open(File::expand_path('config/private.yml',BASE_DIR),'r'))['private']
  end

  def auth
    return false if not network_available?
    return true if is_connected?

    auth_page = @agent.get(SAMPLE_URI)
    return false if auth_page.uri.hostname != 'wlanauth.noc.titech.ac.jp'

    form = auth_page.form
    form.buttonClicked = 4
    form.redirect_url = SAMPLE_URI
    form.username = @private['username']
    form.password = @private['password']
    form.submit

    return is_connected?
  end


  def is_connected?
    return @agent_with_proxy.get(SAMPLE_URI).uri.hostname == SAMPLE_URI.hostname
  rescue
    # retry without the proxy
    return @agent.get(SAMPLE_URI) == SAMPLE_URI.hostname
  end

  def network_available?
    @agent.get('http://portal.titech.ac.jp')
    return true
  rescue => e
    return false
  end

end