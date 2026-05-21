class OllamaDynamicLaunch < Formula
  desc "Pick an Ollama host, model, and coding-CLI integration with fzf, then exec `ollama launch`"
  homepage "https://github.com/johntrandall/ollama-dynamic-launch"
  url "https://github.com/johntrandall/ollama-dynamic-launch/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "fa908b04fd2931840c2b0faf632eb781082198bb4027f08bfe571344f25a97f2"
  license "MIT"
  head "https://github.com/johntrandall/ollama-dynamic-launch.git", branch: "main"

  depends_on "fzf"
  depends_on "jq"
  # `curl` is a system binary on macOS and stock on most Linux distros, so no formal dep.
  # `ollama` is a Cask (brew install --cask ollama), not a formula — see caveats.

  def install
    bin.install "src/ollama-dynamic-launch"
    bin.install_symlink "ollama-dynamic-launch" => "odl"
    pkgshare.install "examples", "README.md", "CHANGELOG.md", "LICENSE"
  end

  def caveats
    <<~EOS
      ollama-dynamic-launch needs Ollama 0.22+ on PATH (for the `launch`
      subcommand). Homebrew distributes Ollama as a Cask:

        brew install --cask ollama

      Or download from https://ollama.com — verify with `ollama --version`.

      Seed your host config from the shipped example:

        mkdir -p ~/.config/ollama-dynamic-launch
        cp #{opt_pkgshare}/examples/hosts.tsv.example \\
           ~/.config/ollama-dynamic-launch/hosts.tsv
        $EDITOR ~/.config/ollama-dynamic-launch/hosts.tsv

      Then verify wiring:

        odl --check

      And launch interactively:

        odl
    EOS
  end

  test do
    assert_predicate bin/"ollama-dynamic-launch", :executable?
    assert_predicate bin/"odl", :exist?
    # --version short-circuits before any config / OLLAMA_BIN lookup,
    # so it works on a fresh-install machine with no hosts.tsv.
    output = shell_output("#{bin}/odl --version")
    assert_match "ollama-dynamic-launch 0.2.1", output
    # --help also short-circuits and mentions the documented flags.
    help = shell_output("#{bin}/odl --help")
    assert_match "--check", help
    assert_match "--version", help
    assert_match "ODL_CONFIG", help
    assert_match "OLLAMA_BIN", help
  end
end
