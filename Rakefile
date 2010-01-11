# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/tagalus.rb'

Hoe.new('tagalus', Tagalus::VERSION) do |p|
  p.rubyforge_name = 'carbonica' # if different than lowercase project name
  p.developer('Michael J. Edgar', 'adgar@carboni.ca')
  
  desc 'Post your blog announcement to blogger.'
  task :post_blogger do
    require 'blogger'
    p.with_config do |config, path|
      break unless config['blogs']
      subject, title, body, urls = p.announcement
      
      config['blogs'].each do |site|
        next unless site['url'] =~ /www\.blogger\.com/
        acc = Blogger::Account.new(site['user'],site['password'])
        post = Blogger::Post.new(:title => title, :content => body, :categories => p.blog_categories, :formatter => :rdiscount)
        acc.post(site['blog_id'], post)

      end
    end
  end
  
  desc 'Pushes rdocs to carbonica'
  task :carbonica => :redocs do
    sh "scp -r doc/ adgar@carboni.ca@carboni.ca:/var/www/html/projects/#{p.name}/"
  end
end

# vim: syntax=Ruby
