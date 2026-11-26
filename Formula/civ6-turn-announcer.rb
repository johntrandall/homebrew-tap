class Civ6TurnAnnouncer < Formula
  desc "Spoken turn alerts for live multiplayer Civilization VI"
  homepage "https://github.com/johntrandall/civ6-turn-announcer"
  url "https://github.com/johntrandall/civ6-turn-announcer/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "f721d6ba778e71f37177aadf3f44b27acdaed41802b1ea0d3a5192dcee45551a"
  license "MIT"
  head "https://github.com/johntrandall/civ6-turn-announcer.git", branch: "main"

  depends_on "python@3.13"

  def install
    # Standard library only: no virtualenv or build step, the package directory runs as it is.
    libexec.install "src/civ6_turn_announcer"
    (bin/"civ6-turn-announcer").write <<~SH
      #!/bin/bash
      PYTHONPATH="#{libexec}" exec "#{Formula["python@3.13"].opt_bin}/python3.13" -m civ6_turn_announcer "$@"
    SH
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/civ6-turn-announcer --version")
    assert_match "Test alert", shell_output("#{bin}/civ6-turn-announcer --mode silent --test")
  end
end
