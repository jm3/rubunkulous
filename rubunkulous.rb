#!/usr/bin/env ruby

# Ru-BUNK-u-lous.
# n. A reentrant link-checker for delicious power-users, stress-tested with stores of 12,000+ links.
# by jm3 (John Manoogian III)

require 'rubygems'
require 'curb'
require 'moneta'
require 'moneta/basic_file'
require 'moneta/xattr'
require 'net/https'
require 'rexml/document'
include REXML

Pointer_Key = 'index_pointer'
Max_XAttr_Key_Length = 126 # i swear to christ...

@start_override = 0

ARGV.each do|arg|
  if arg =~ /--start=(\d+)/ or arg =~ /^(\d+)$/
    @start_override = $1.to_i
  end
end

def link_cache
  f = '.cached_links.xml'
  File.writable?('.') ? File.join('.', f) : File.join(File.expand_path('~'), f)
end

def credentials
  creds = File.join( '.', 'credentials.yml')
  return [] unless File.exist?(creds)
  creds = YAML.load(File.read(creds))[:delicious]
  [creds[:user], creds[:password]]
end

def fetch_links
  @response = ''
  begin    
    url = URI.parse( 'https://api.del.icio.us/v1/posts/all')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start do |http|
      if !url.query.nil?
        path = url.path + "?" + url.query
      else
        path = url.path
      end
      req = Net::HTTP::Get.new(path)
      user, password = credentials
      req.basic_auth user, password
      res = http.request(req)
      @response = res.body
    end
  rescue Net::HTTPError
    raise "Can't connect to the server, please check the username/password.\nError: #{$!} \n"
  end
  
  begin
    @doc = Document.new @response
  rescue REXML::ParseException
    raise "\nPosts#find XML parsing failed\nError: #{$!}\n"
  end
end

def links
  # Check if we've got cached XML from a previous run
  unless File.exists?(link_cache)
    puts "Caching Delicious locally to avoid making slow API calls more than once."
    xml = fetch_links
    File.open(link_cache, 'w') {|f| f.write(xml) }

    # by default, the Delicious API returns reponses with encoding errors; this fixes them:
    if `which tidy`.empty?
      puts "WARNING: you don't have tidy installed, which means that occasional errors in Delicious's API xml may hang up Rubunkulous. Try: sudo port install tidy  to get it."
    else
      `tidy -xml .cached_links.xml &> /dev/null`
    end
  end

  puts "Loading link data saved from previous run (this could take a second...)"
  xmldoc = Document.new( File.new(link_cache))
  xmldoc.elements.to_a('posts/post')
end

def log_failed(url, desc, error)
  # truncate xattr key names to 128 chars or suffer the consequences
  @cache.store(url[0..Max_XAttr_Key_Length], "#{desc} (#{url}) failed with #{error} at #{Time.now.to_s}") 
end

def check(links)
  return unless links.size > 0
  interrupted = false
  trap("INT") { interrupted = true }

  @links_checked, @num_fails, @total_links = 0,0,0

  def print_report
    puts "\n#{@links_checked} links checked (#{@num_fails} failures) - #{@total_links - @links_checked} links to go."
    puts "\nTo clear last-checked counter and re-check all links, type: \nxattr .moneta_cache/xattr_cache -index_pointer"
  end

  @cache = Moneta::Xattr.new(:file => File.join(File.dirname(__FILE__), ".moneta_cache", "xattr_cache"))
  last_index = (@start_override > 0 ? @start_override : nil) || @cache[Pointer_Key] || 0

  puts "Left off at link ##{last_index} (of #{links.size} total links)." if last_index > 0

  # skip previously checked links
  links = links[last_index..links.size]
  @total_links = links.size
  puts "#{@total_links} links to check."

  links.each do |link|

    if interrupted
      print_report
      exit
    end

    url  = link.attributes['href']
    desc = link.attributes['description']

    begin
      response = Curl::Easy.perform(url) do |curl|
        curl.follow_location  = true
        curl.max_redirects    = 2
        curl.connect_timeout  = 3
        curl.timeout          = 5 # total request timeout; saves us from having to wait for the request to complete if you bookmarked a 500mb file or something...
      end
    rescue
      log_failed(url, desc, response ? response.response_code : 666)
    end

    @links_checked += 1
    @cache.store(Pointer_Key, last_index + @links_checked)
    next unless response

    if response.response_code != 200
      puts "x FAIL #{response.response_code} #{url} (#{@links_checked})"
      @num_fails += 1
      log_failed(url, desc, response.response_code)
    else
      puts "> OK #{url} (#{@links_checked})"
    end
  end
  print_report
end

check(links)
