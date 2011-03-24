module Sauce
  module Jasmine
    class Runner
      def initialize
        @config = Config.new
        @server = Server.new(@config)
      end

      def run
        setup
        begin
          run_tests
        ensure
          teardown
        end
      end

      def setup
        @server.start
        @tunnel = Sauce::Connect.new(:domain => @config.tunnel_domain,
                                         :host => @server.host,
                                         :port => @server.port,
                                         :quiet => @config.quiet_tunnel?)
        @tunnel.wait_until_ready
      end
      
      def run_tests
        puts "running tests..."
        results = Sauce::Config.new.browsers.map do |browser_spec|
          run_tests_in_browser(*browser_spec)
        end
        success = results.all? do |run_result|
          run_result.values.all? {|suite_result| suite_result['result'] == "passed"}
        end
        if success
          puts "Success!"
        else
          puts "Failure:"
          p results
          at_exit { exit!(1) }
        end
      end

      def teardown
        puts "tearing down tunnel"
        @tunnel.disconnect
      end

      def run_tests_in_browser(os, browser, browser_version)
        driver = SeleniumDriver.new(os, browser, browser_version, @config.tunnel_domain)
        driver.connect
        begin
          while !driver.tests_have_finished?
            sleep 0.1
          end
          result = driver.test_results
        ensure
          driver.disconnect
          return result
        end
      end
    end
  end
end

