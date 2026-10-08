class ClaudeBrowser < Formula
  include Language::Python::Shebang

  desc "One throwaway, pre-signed-in Chrome instance per Claude Code session"
  homepage "https://github.com/johntrandall/claude-browser-pool"
  url "https://github.com/johntrandall/claude-browser-pool/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "f38dce3233bc5b6c564eb4fcfc85062514b16898ca137bad3c5bf05abb3cf7c1"
  license "MIT"
  head "https://github.com/johntrandall/claude-browser-pool.git", branch: "main"

  depends_on "fileicon"
  depends_on "johntrandall/tap/chrome-cookie-graft"
  depends_on "jq"
  depends_on :macos
  depends_on "python@3.13"

  def install
    libexec.install "bin/claude-browser", "bin/make-claude-chrome-icon"
    rewrite_shebang detected_python_shebang, libexec/"claude-browser"
    bin.install_symlink libexec/"claude-browser"
    pkgshare.install "hooks", "tests"
  end

  service do
    # Backstop teardown: detach agents whose process has exited and remove
    # browsers that are dead, unattached, abandoned or idle. Every 15 min.
    run [opt_bin/"claude-browser", "gc"]
    run_type :interval
    interval 900
    log_path "#{Dir.home}/Library/Logs/claude-browser-gc.log"
    error_log_path "#{Dir.home}/Library/Logs/claude-browser-gc.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      Map each Claude account to the main-Chrome profile signed in to it:
        #{Dir.home}/.config/claude-browser/config.json
        { "accounts": { "work": "Profile 3" } }

      Register the Claude Code hooks in ~/.claude/settings.json:
        SessionStart: #{opt_pkgshare}/hooks/claude-browser-session-start.sh
        SessionEnd:   #{opt_pkgshare}/hooks/claude-browser-session-end.sh
        PostToolUse (matcher mcp__claude-in-chrome__select_browser):
                      #{opt_pkgshare}/hooks/claude-browser-select-attach.sh

      Then, once per Mac and once per account (one human click each):
        claude-browser template init
        claude-browser template pair <account>

      Per-instance Dock icons need Pillow (install uv, or pip install pillow).

      Backstop cleanup of idle or abandoned agent browsers (every 15 min):
        brew services start claude-browser
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/claude-browser --version")
    (testpath/"config.json").write <<~JSON
      {"root": "#{testpath}/root", "accounts": {"work": "Profile 3"}}
    JSON
    ENV["CLAUDE_BROWSER_CONFIG"] = testpath/"config.json"
    output = shell_output("#{bin}/claude-browser config --json")
    assert_match "Profile 3", output
    assert_match "#{testpath}/root", output
    assert_match "no base template", shell_output("#{bin}/claude-browser template list")
  end
end
