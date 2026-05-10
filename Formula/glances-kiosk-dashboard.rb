class GlancesKioskDashboard < Formula
  desc "Mac kiosk HTML dashboard backed by Glances + nettop + saturation pollers"
  homepage "https://github.com/johntrandall/glances-kiosk-dashboard"
  url "https://github.com/johntrandall/glances-kiosk-dashboard/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "055011394f93a4d82337cb471dc1f681962714b44f6af8fe3485b5b85a8af409"
  license "MIT"
  head "https://github.com/johntrandall/glances-kiosk-dashboard.git", branch: "main"

  depends_on "glances"
  depends_on :macos
  depends_on "speedtest-cli"

  def install
    libexec.install Dir["*"]

    # DR-001: pin to Apple system Python (stdlib only). Avoid surprises if a
    # Homebrew Python ends up first in PATH at launchd-spawn time.
    %w[server.py speedtest-runner.py].each do |script|
      path = libexec/script
      content = path.read.sub(/\A#!.*\n/, "#!/usr/bin/python3\n")
      path.write content
      chmod 0755, path
    end

    # speedtest-runner.py hardcodes /opt/homebrew/bin/speedtest. Repoint to
    # the formula's actual brew prefix so non-default prefixes work too.
    inreplace libexec/"speedtest-runner.py",
              %r{^SPEEDTEST_BIN = "/opt/homebrew/bin/speedtest"$},
              "SPEEDTEST_BIN = \"#{Formula["speedtest-cli"].opt_bin}/speedtest\""

    bin.install_symlink libexec/"server.py" => "glances-kiosk-dashboard"
    bin.install_symlink libexec/"speedtest-runner.py" => "glances-kiosk-dashboard-speedtest"
  end

  service do
    run [opt_libexec/"server.py", "--port", "61210", "--upstream", "http://127.0.0.1:61208"]
    keep_alive true
    log_path "/tmp/glances-kiosk-dashboard.stdout.log"
    error_log_path "/tmp/glances-kiosk-dashboard.stderr.log"
  end

  def caveats
    <<~EOS
      glances-kiosk-dashboard reverse-proxies the local Glances instance on
      127.0.0.1:61208 and serves a layout-customized HTML dashboard on :61210.

      Required: start the upstream Glances first.
        brew services start glances

      Then start the dashboard:
        brew services start glances-kiosk-dashboard
        open "http://$(hostname -s):61210/"

      Optional: enable the 30-min cadence speedtest worker (auto-skips on
      tethering, idle, or when nobody is viewing the dashboard):
        cp #{opt_libexec}/com.johnrandall.glances-kiosk-speedtest.plist \\
           ~/Library/LaunchAgents/

        # Edit ProgramArguments path to: #{opt_libexec}/speedtest-runner.py
        # (the bundled plist references the source-tree dev path).

        launchctl bootstrap gui/$(id -u) \\
          ~/Library/LaunchAgents/com.johnrandall.glances-kiosk-speedtest.plist

      Logs (default):
        /tmp/glances-kiosk-dashboard.stdout.log
        /tmp/glances-kiosk-dashboard.stderr.log
        /tmp/glances-kiosk-speedtest.{stdout,stderr}.log

      Read-only metrics. No auth — assume LAN/Tailscale-trusted.
    EOS
  end

  test do
    assert_predicate bin/"glances-kiosk-dashboard", :executable?
    output = shell_output("#{bin}/glances-kiosk-dashboard --help")
    assert_match "--port", output
    assert_match "--upstream", output
  end
end
