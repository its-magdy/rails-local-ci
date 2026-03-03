# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/active_support/continuous_integration"

class ContinuousIntegrationTest < Minitest::Test
  def setup
    @CI = ActiveSupport::ContinuousIntegration.new
  end

  def test_successful_step
    output = capture_io { @CI.step "Success!", "which ruby > /dev/null" }.to_s
    assert_match(/Success! passed/, output)
    assert @CI.success?
  end

  def test_failed_step
    output = capture_io { @CI.step "Failed!", "which rubyxx > /dev/null" }.to_s
    assert_match(/Failed! failed/, output)
    refute @CI.success?
  end

  def test_report_with_only_successful_steps_combined_gives_success
    output = capture_io do
      @CI.report("CI") do
        step "Success!", "which ruby > /dev/null"
        step "Success again!", "which ruby > /dev/null"
      end
    end.to_s

    assert_match(/CI passed/, output)
    assert @CI.success?
  end

  def test_report_with_successful_and_failed_steps_combined_gives_failure
    output = capture_io do
      @CI.report("CI") do
        step "Success!", "which ruby > /dev/null"
        step "Failed!", "which rubyxx > /dev/null"
      end
    end.to_s

    assert_match(/CI failed/, output)
    refute @CI.success?
  end

  def test_echo_uses_terminal_coloring
    output = capture_io { @CI.echo "Hello", type: :success }.first.to_s
    assert_equal "\e[1;32mHello\e[0m\n", output
  end

  def test_heading
    output = capture_io { @CI.heading "Hello", "To all of you" }.first.to_s
    assert_match(/Hello[\s\S]*To all of you/, output)
  end

  def test_failure_output
    output = capture_io { @CI.failure "This sucks", "But such is the life of programming sometimes" }.first.to_s
    assert_equal "\e[1;31m\n\nThis sucks\e[0m\n\e[1;90mBut such is the life of programming sometimes\n\e[0m\n", output
  end
end
