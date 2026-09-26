class ChromeCookieGraft < Formula
  desc "Copy session cookies between Chrome profiles, holding back identity hosts"
  homepage "https://github.com/johntrandall/chrome-cookie-graft"
  url "https://github.com/johntrandall/chrome-cookie-graft/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "dcb41f0da398bcc338cb14461e2d11e021573eb383f6ce6832a5346fdf38465f"
  license "MIT"
  head "https://github.com/johntrandall/chrome-cookie-graft.git", branch: "main"
  version "0.1.3"

  depends_on :macos

  def install
    bin.install "bin/chrome-cookie-graft"
    pkgshare.install "README.md", "LICENSE", "config.example.json"
  end

  def post_install
    config_dir = Pathname.new(Dir.home)/".config/chrome-cookie-graft"
    config_file = config_dir/"config.json"
    return if config_file.exist?

    config_dir.mkpath
    config_file.write (pkgshare/"config.example.json").read
    ohai "Seeded #{config_file} — edit 'source' and 'targets' before first run"
  end

  service do
    run [opt_bin/"chrome-cookie-graft"]
    # run_type :interval is REQUIRED for `interval` to emit StartInterval.
    # Without it Homebrew writes RunAtLoad only -- the job fires once at login
    # and never again, while still looking like a daily service.
    run_type :interval
    interval 86400
    run_at_load true
    log_path "#{Dir.home}/Library/Logs/chrome-cookie-graft.log"
    error_log_path "#{Dir.home}/Library/Logs/chrome-cookie-graft.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      Configure which profiles to copy between:
        #{Dir.home}/.config/chrome-cookie-graft/config.json

      'source' and 'targets' are profile DIRECTORY names (e.g. "Default",
      "Profile 3"), not display names. chrome://version shows the active
      one as "Profile Path".

      'protect' outranks everything, including an explicit 'only' allowlist —
      hosts listed there are never copied, so each target keeps its own
      identity for those sites.

      Run it once by hand first:
        chrome-cookie-graft -n          # dry run
        chrome-cookie-graft

      Then enable the daily run:
        brew services start chrome-cookie-graft

      A target profile that is open in Chrome is SKIPPED — Chrome flushes its
      own in-memory cookie jar on exit and would discard the write. Close that
      profile's windows and re-run. After 'stale_days' without a successful
      graft the tool warns and exits non-zero.
    EOS
  end

  test do
    assert_predicate bin/"chrome-cookie-graft", :executable?
    (testpath/"c.json").write <<~JSON
      {"source": "A", "targets": ["B"], "only": ["*.example.com"]}
    JSON
    output = shell_output("#{bin}/chrome-cookie-graft -c #{testpath}/c.json --print-config")
    assert_match "example.com", output
    assert_match "claude.ai", output   # protect defaults are always present
  end
end
