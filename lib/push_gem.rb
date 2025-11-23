# frozen_string_literal: true

require "dotenv"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "bundler/gem_tasks"
require_relative "push_gem/version"

class PushGem
  attr_accessor :author, :gem

  def initialize(author:, gem:)
    @author = author
    @gem    = gem
  end

  def push
    validate_author!
    validate_gem!

    system("bundle install")

    puts "Pushing #{gem} gem..."

    build_gem
    push_to_github
    push_to_rubygems

    puts "Successfully pushed #{gem} gem to both GitHub Packages and RubyGems.org"
  end

  def check
    validate_author!
    validate_gem!

    RSpec::Core::RakeTask.new(:spec) do |t|
      t.verbose = false
    end

    RuboCop::RakeTask.new

    puts "Running tests for #{gem} gem..."

    Rake::Task["spec"].invoke
    Rake::Task["rubocop"].invoke
  end

  private

  def validate_author!
    abort("Gem author is required") if @author.nil? || @author.strip.empty?
  end

  def validate_gem!
    abort("Gem name is required") if @gem.nil? || @gem.strip.empty?
  end

  def build_gem
    puts "--- build ---"
    abort("Failed to build gem") unless system(build_gem_command)
  end

  def push_to_github
    puts "--- push to github packages ---"
    abort("Failed to push gem to GitHub Packages") unless system(github_push_command)
  end

  def push_to_rubygems
    puts "--- push to rubygems.org ---"
    abort("Failed to push gem to RubyGems.org") unless system(rubygems_push_command)
  end

  def build_gem_command
    "rake build"
  end

  def github_push_command
    "gem push --key github --host https://rubygems.pkg.github.com/#{author} " \
      "pkg/#{gem}-#{Object.const_get(camelized_gem_name)::VERSION}.gem"
  end

  def rubygems_push_command
    "gem push --host https://rubygems.org " \
      "pkg/#{gem}-#{Object.const_get(camelized_gem_name)::VERSION}.gem"
  end

  def camelized_gem_name
    gem.split("_").map(&:capitalize).join
  end
end

task :"gem:push", [:author, :gem] do |_t, args|
  Dotenv.load

  author = args[:author] || ENV.fetch("GEM_AUTHOR", nil)
  gem    = args[:gem]    || ENV.fetch("GEM_NAME", nil)

  pusher = PushGem.new(author:, gem:)
  pusher.push
end

task :"gem:check", [:author, :gem] do |_t, args|
  Dotenv.load

  author = args[:author] || ENV.fetch("GEM_AUTHOR", nil)
  gem    = args[:gem]    || ENV.fetch("GEM_NAME", nil)

  pusher = PushGem.new(author:, gem:)
  pusher.check
end
