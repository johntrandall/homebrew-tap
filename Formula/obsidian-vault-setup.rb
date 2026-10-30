class ObsidianVaultSetup < Formula
  include Language::Python::Virtualenv

  desc "Make any folder an Obsidian vault with your plugin roster, via Obsidian's CLI"
  homepage "https://github.com/johntrandall/obsidian-vault-setup"
  url "https://github.com/johntrandall/obsidian-vault-setup/archive/refs/tags/v0.1.12.tar.gz"
  sha256 "137d2bc762ff4c291d4a1b02b0be3adbd3dd35c758abdc6dfa28584b35ab31ff"
  license "MIT"
  head "https://github.com/johntrandall/obsidian-vault-setup.git", branch: "main"

  depends_on "libyaml"
  depends_on :macos # drives Obsidian.app through its CLI; Finder button via osacompile
  depends_on "python@3.14"

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources

    # The script finds config.example.yaml and finder/ two levels above itself, so it lives in
    # libexec/bin next to the venv's python, with its shebang pointed at that python.
    libexec.install "config.example.yaml", "finder"
    script = libexec/"bin/obsidian-vault-setup"
    script.write File.read("bin/obsidian-vault-setup").sub(/\A#!.*\n/, "#!#{libexec}/bin/python\n")
    chmod 0755, script

    bin.install_symlink script
    bin.install_symlink script => "obsidian-new-vault"
    bin.install_symlink script => "obsidian-open-vault"
    pkgshare.install "README.md"
  end

  def caveats
    <<~EOS
      Requires Obsidian >= 1.12 with Settings > General > Command line interface switched on,
      and Obsidian running.

      One-time setup:
        obsidian-vault-setup init-config            # ~/.config/obsidian-vault-setup/config.yaml
        obsidian-vault-setup install-finder-button  # ~/Applications/Open in Obsidian.app
        obsidian-vault-setup doctor

      Then Command-drag "Open in Obsidian" from ~/Applications into a Finder window's toolbar.
    EOS
  end

  test do
    assert_predicate bin/"obsidian-vault-setup", :executable?
    system libexec/"bin/python", "-c", "import yaml"
    assert_match "init-config", shell_output("#{bin}/obsidian-vault-setup --help")
    ENV["XDG_CONFIG_HOME"] = testpath
    system bin/"obsidian-vault-setup", "init-config"
    assert_path_exists testpath/"obsidian-vault-setup/config.yaml"
  end
end
