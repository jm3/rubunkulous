#!/opt/local/bin/ruby
# A reentrant link-checker for delicious power-users, stress-tested with stores of 12,000+ links.
# by jm3 (John Manoogian III)
#
# Features:
# * Resilient to control-c interrupts, will resume checking where left off.
# * Delicious API responses cached locally so they need only be retrieved once.
# * Dead links persisted in a Moneta cache for you to deal with as you please, e.g.
#
# % xatttr .moneta_cache/xattr_cache | xargs -n1 -I foo curl "http://api.delicious.com/delete?url=foo"
#
# Todo:
# * cool animated progress indicator with ncurses
# * test sax parsing to see if it's a faster load

require 'rubygems'
require 'curb'
require 'moneta'
require 'moneta/basic_file'
require 'moneta/xattr'
require 'net/https'
require 'rexml/document'
include REXML

# no longer needed:
#require "ridiculous"
#include Ridiculous

def pointer_key
  'index_pointer'
end

def link_cache
  f = '.cached_links.xml'
  File.writable?('.') ? File.join('.', f) : File.join(File.expand_path('~'), f)
end

def credentials
  creds = File.join( '.', 'creds.yml')
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
    `tidy -xml .cached_links.xml &> /dev/null`
  end

  puts "Loading link data saved from previous run (this could take a second...)"
  xmldoc = Document.new( File.new(link_cache))

  # not reliable: 
  # puts "Loaded #{xmldoc.root.size - 3} links." # subtract 3 elments for: 2 root node tags + 1 xml decl tag

  xmldoc.elements.to_a('posts/post')
end

def log_failed(url, desc, error)
  # truncate xattr names to 128 chars or suffer the consequences
  @cache.store(url[0..127], "#{desc} (#{url}) failed with #{error} at #{Time.now.to_s}") 
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
  last_index = @cache[pointer_key] || 0

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
        curl.follow_location = true
        curl.max_redirects = 3
      end
    rescue
      log_failed(url, desc, response ? response.response_code : 666)
    end

    @links_checked += 1
    @cache.store(pointer_key, last_index + @links_checked)
    next unless response

    if response.response_code != 200
      puts "x FAIL #{response.response_code} (#{@links_checked})"
      @num_fails += 1
      log_failed(url, desc, response.response_code)
    else
      puts "> OK #{url} (#{@links_checked})"
    end
  end
  print_report
end

check(links)
