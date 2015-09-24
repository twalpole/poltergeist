POLTERGEIST_ROOT = File.expand_path('../..', __FILE__)
$:.unshift(POLTERGEIST_ROOT + '/lib')

require 'bundler/setup'

require 'rspec'
require 'capybara/spec/spec_helper'
require 'capybara/poltergeist'

require 'support/test_app'
require 'support/spec_logger'

Capybara.register_driver :poltergeist do |app|
  debug = !ENV['DEBUG'].nil?
  options = {
    logger: TestSessions.logger,
    inspector: debug,
    debug: debug
  }

  options[:phantomjs] = './phantomjs2/phantomjs' if ENV['TRAVIS'] && ENV['USE_PHANTOMJS2']

  Capybara::Poltergeist::Driver.new(
    app, options
  )
end

module TestSessions
  def self.logger
    @logger ||= SpecLogger.new
  end

  Poltergeist = Capybara::Session.new(:poltergeist, TestApp)
end

RSpec.configure do |config|
  config.before do
    TestSessions.logger.reset
  end

  config.after do
    if ENV['DEBUG']
      puts TestSessions.logger.messages
    elsif ENV['TRAVIS'] && example.exception
      example.exception.message << "\n\nDebug info:\n" + TestSessions.logger.messages.join("\n")
    end
  end

  Capybara::SpecHelper.configure(config)

  config.before(:each) do
    Capybara.default_wait_time = 0
  end

  config.before(:each, :requires => :js) do
    Capybara.default_wait_time = 1
  end
end
