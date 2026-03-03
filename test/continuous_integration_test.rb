# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/active_support/continuous_integration"

class ContinuousIntegrationTest < Minitest::Test
  def setup
    @CI = ActiveSupport::ContinuousIntegration.new
  end

  def test_successful_step
    output = capture_io { @CI.step "Success!", "true" }.to_s
    assert_match(/Success! passed/, output)
    assert @CI.success?
  end

  def test_failed_step
    output = capture_io { @CI.step "Failed!", "false" }.to_s
    assert_match(/Failed! failed/, output)
    refute @CI.success?
  end

  def test_run_with_only_successful_steps_combined_gives_success
    output = capture_io do
      @CI.run("CI", nil) do
        step "Success!", "true"
        step "Success again!", "true"
      end
    end.to_s

    assert_match(/CI passed/, output)
    assert @CI.success?
  end

  def test_run_with_successful_and_failed_steps_combined_gives_failure
    output = capture_io do
      assert_raises(SystemExit) do
        @CI.run("CI", nil) do
          step "Success!", "true"
          step "Failed!", "false"
        end
      end
    end.to_s

    assert_match(/CI failed/, output)
    refute @CI.success?
  end

  def test_run_with_successful_and_failed_steps_combined_presents_a_failure_summary
    output = capture_io do
      assert_raises(SystemExit) do
        @CI.run("CI", nil) do
          step "Success!", "true"
          step "Failed!", "false"
          step "Also success!", "true"
          step "Also failed!", "false"
        end
      end
    end.to_s

    refute_match(/↳ Success/, output)
    refute_match(/↳ Also success/, output)
    assert_match(/↳ Failed! failed/, output)
    assert_match(/↳ Also failed! failed/, output)
  end

  def test_run_with_only_one_failing_step_does_not_print_a_failure_summary
    output = capture_io do
      assert_raises(SystemExit) do
        @CI.run("CI", nil) do
          step "Failed!", "false"
        end
      end
    end.to_s

    refute_match(/↳ Failed/, output)
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

  def test_sequential_group_with_all_passing_steps
    output = capture_io do
      @CI.group("Checks") do
        step "Pass 1", "true"
        step "Pass 2", "true"
      end
    end.to_s

    assert @CI.success?
    assert_match(/Pass 1 passed/, output)
    assert_match(/Pass 2 passed/, output)
  end

  def test_sequential_group_with_a_failing_step
    output = capture_io do
      @CI.group("Checks") do
        step "Pass", "true"
        step "Fail", "false"
      end
    end.to_s

    refute @CI.success?
    assert_match(/Fail failed/, output)
  end

  def test_parallel_group_with_all_passing_steps
    output = capture_io do
      @CI.group("Checks", parallel: 2) do
        step "Pass 1", "true"
        step "Pass 2", "true"
      end
    end.to_s

    assert @CI.success?
    assert_match(/Pass 1 passed/, output)
    assert_match(/Pass 2 passed/, output)
  end

  def test_parallel_group_with_a_failing_step
    output = capture_io do
      @CI.group("Checks", parallel: 2) do
        step "Pass", "true"
        step "Fail", "false"
      end
    end.to_s

    refute @CI.success?
    assert_match(/Fail failed/, output)
  end

  def test_parallel_group_provides_a_tty_via_pty
    begin
      require "pty"
    rescue LoadError
      skip "PTY not available"
    end

    output = capture_io do
      @CI.group("Checks", parallel: 2) do
        step "TTY", "sh", "-c", "test -t 1"
      end
    end.to_s

    assert_match(/TTY passed/, output)
  end

  def test_parallel_group_falls_back_to_open3_when_pty_is_unavailable
    skip "assert_called_on_instance_of requires ActiveSupport test helpers"
  end

  def test_parallel_group_timing
    capture_io do
      started = Time.now.to_f
      @CI.group("Checks", parallel: 2) do
        step "Sleep 1", "sleep 0.2"
        step "Sleep 2", "sleep 0.2"
      end
      elapsed = Time.now.to_f - started

      assert elapsed < 0.35, "Expected parallel execution to complete in ~0.2s, took #{elapsed}s"
    end

    assert @CI.success?
  end

  def test_sub_groups_cannot_be_parallelized
    exception = assert_raises ArgumentError do
      capture_io do
        @CI.group("Outer", parallel: 2) do
          group "Inner", parallel: 2 do
            step "Test", "true"
          end
        end
      end
    end
    assert_equal "Sub-groups cannot be parallelized. Remove the `parallel:` option from the \"Inner\" group.", exception.message
  end

  def test_nested_group_within_sequential_group
    output = capture_io do
      @CI.group("Outer") do
        step "Style", "true"
        group "Tests" do
          step "Unit", "true"
          step "System", "true"
        end
      end
    end.to_s

    assert @CI.success?
    assert_match(/Unit passed/, output)
    assert_match(/System passed/, output)
  end

  def test_nested_group_within_parallel_group
    output = capture_io do
      @CI.group("Checks", parallel: 2) do
        step "Style", "true"
        group "Tests" do
          step "Unit", "true"
          step "System", "true"
        end
      end
    end.to_s

    assert @CI.success?
    assert_match(/Style passed/, output)
    assert_match(/Unit passed/, output)
    assert_match(/System passed/, output)
  end

  def test_step_restores_previous_signal_handler
    custom_handler = proc { }
    Signal.trap("INT", custom_handler)

    capture_io { @CI.step "Pass", "true" }

    current = Signal.trap("INT", "DEFAULT")
    assert_equal custom_handler, current
  ensure
    Signal.trap("INT", "DEFAULT")
  end

  def test_parallel_group_restores_previous_signal_handler
    custom_handler = proc { }
    Signal.trap("INT", custom_handler)

    capture_io do
      @CI.group("Checks", parallel: 2) do
        step "Pass", "true"
      end
    end

    current = Signal.trap("INT", "DEFAULT")
    assert_equal custom_handler, current
  ensure
    Signal.trap("INT", "DEFAULT")
  end

  def test_parallel_group_handles_spawn_errors_as_failed_steps
    Dir.mktmpdir do |dir|
      script = File.join(dir, "nope.sh")
      File.write(script, "#!/bin/sh\nexit 0")
      File.chmod(0o000, script)

      output = capture_io do
        @CI.group("Checks", parallel: 2) do
          step "No permission", script
        end
      end.to_s

      refute @CI.success?
      assert_match(/No permission failed/, output)
    end
  end

  def test_parallel_group_cleans_up_temp_files_on_completion
    temp_files_before = Dir.glob(File.join(Dir.tmpdir, "ci-*.log"))

    capture_io do
      @CI.group("Checks", parallel: 2) do
        step "Pass", "true"
        step "Fail", "false"
      end
    end

    temp_files_after = Dir.glob(File.join(Dir.tmpdir, "ci-*.log"))
    assert_equal temp_files_before, temp_files_after
  end

  %w[-f --fail-fast].each do |flag|
    define_method(:"test_run_aborts_immediately_on_failure_with_#{flag.gsub(/^-+/, '').gsub('-', '_')}_flag") do
      output = with_argv([flag]) do
        capture_io do
          assert_raises SystemExit do
            @CI.run("CI", nil) do
              step "Success!", "true"
              step "Failed!", "false"
              step "Should not run", "true"
            end
          end
        end
      end.to_s

      refute_match(/Should not run/, output)
    end

    define_method(:"test_parallel_group_stops_launching_new_steps_with_#{flag.gsub(/^-+/, '').gsub('-', '_')}_flag") do
      output = with_argv([flag]) do
        capture_io do
          assert_raises SystemExit do
            @CI.run("CI", nil) do
              group "Checks", parallel: 2 do
                step "Fail", "false"
                step "Should not run 1", "true"
                step "Should not run 2", "true"
                step "Should not run 3", "true"
              end
            end
          end
        end
      end.to_s

      # With parallel: 2, one thread gets "Fail" and the other may dequeue one
      # task before observing the failure — but subsequent tasks must be skipped.
      refute_match(/Should not run 3/, output)
    end
  end

  private
    def with_argv(argv)
      original_argv = ARGV.dup
      ARGV.replace(argv)

      yield
    ensure
      ARGV.replace(original_argv)
    end
end
