class Civ6TurnAnnouncer < Formula
  desc "Spoken turn alerts for live multiplayer Civilization VI"
  homepage "https://github.com/johntrandall/civ6-turn-announcer"
  url "https://github.com/johntrandall/civ6-turn-announcer/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "a07bbc98cbfd7348a3ead6a3b77bcac8a16b7ecd9dd2d7ce4d11d4136d9c4fa5"
  license "MIT"
  head "https://github.com/johntrandall/civ6-turn-announcer.git", branch: "main"

  depends_on "python@3.13"

  def install
    # Standard library only: no virtualenv or build step, the package directory runs as it is.
    libexec.install "src/civ6_turn_announcer"
    (bin/"civ6-turn-announcer").write <<~SH
      #!/bin/bash
      PYTHONPATH="#{libexec}" exec "#{formula_opt_bin("python@3.13")}/python3.13" -m civ6_turn_announcer "$@"
    SH
  end

  service do
    run [opt_bin/"civ6-turn-announcer"]
    keep_alive true
    log_path var/"log/civ6-turn-announcer.log"
    error_log_path var/"log/civ6-turn-announcer.log"
  end

  def caveats
    <<~EOS
      To start it at login under its own name in System Settings > Login Items:
        civ6-turn-announcer --install-login-item
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/civ6-turn-announcer --version")
    assert_match "Test alert", shell_output("#{bin}/civ6-turn-announcer --mode silent --test")
  end
end
