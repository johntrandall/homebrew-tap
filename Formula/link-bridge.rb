class LinkBridge < Formula
  desc "Local pages that turn a web link into an app link (Obsidian, Finder, vaults)"
  homepage "https://github.com/johntrandall/link-bridge"
  url "https://github.com/johntrandall/link-bridge/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "5e5e9ee553aefcad76186cad0607575af4c2382143f56191d8c043ac091b1a65"
  license "MIT"
  head "https://github.com/johntrandall/link-bridge.git", branch: "main"

  depends_on :macos # the reveal:// handler is an osacompile applet; `open -R` is Finder
  depends_on "python@3.14"

  def install
    # The script finds public/ and handler/ one level above itself, so it lives in libexec/bin
    # with public/ and handler/ beside it (same shape as the repo), shebang on brew's python.
    # test/ sits beside handler/ because install-handler runs the decoder's tests before building.
    libexec.install "public", "handler", "frontdoor", "test"
    (libexec/"bin").mkpath
    script = libexec/"bin/link-bridge"
    python = formula_opt_bin("python@3.14")/"python3.14"
    script.write File.read("bin/link-bridge").sub(/\A#!.*\n/, "#!#{python} -I\n")
    chmod 0755, script
    %w[handler/install.sh frontdoor/install.sh frontdoor/uninstall.sh].each { |f| chmod 0755, libexec/f }
    bin.install_symlink script
    pkgshare.install "README.md"
  end

  service do
    run [opt_bin/"link-bridge", "serve"]
    keep_alive true
    log_path "#{Dir.home}/Library/Logs/link-bridge.log"
    error_log_path "#{Dir.home}/Library/Logs/link-bridge.log"
  end

  def caveats
    <<~EOS
      Serves http://localhost:5465 (loopback only). Start it with:
        brew services start link-bridge

      /reveal links need the handler app once per Mac:
        link-bridge install-handler     # builds ~/Applications/Reveal in Finder.app
        link-bridge doctor
      Optional, to drop the port from links (Caddy on 127.0.0.1:80 as a root daemon):
        brew install caddy && link-bridge install-front-door

      /vault-setup links (open or create an Obsidian vault) need the companion tool:
        brew install johntrandall/tap/obsidian-vault-setup && obsidian-vault-setup install-finder-button
    EOS
  end

  test do
    assert_predicate bin/"link-bridge", :executable?
    assert_match "install-handler", shell_output("#{bin}/link-bridge --help")
    assert_match "/reveal#", shell_output("#{bin}/link-bridge url #{testpath}")
    port = free_port
    pid = spawn bin/"link-bridge", "serve", "--port", port.to_s
    begin
      sleep 2
      assert_match "Reveal in Finder", shell_output("curl -s http://127.0.0.1:#{port}/reveal")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
