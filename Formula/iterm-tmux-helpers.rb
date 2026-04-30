class ItermTmuxHelpers < Formula
  include Language::Python::Virtualenv

  desc "iTerm2 + tmux integration helpers for -CC control mode on macOS"
  homepage "https://github.com/johntrandall/iterm-tmux-helpers"
  url "https://github.com/johntrandall/iterm-tmux-helpers/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "92f7818f7cc61303c06093627598daa4ae2ce181d0259e201a225a9c9f8b5a84"
  license "MIT"
  head "https://github.com/johntrandall/iterm-tmux-helpers.git", branch: "main"

  depends_on "fzf"
  depends_on "python@3.13"
  depends_on "tmux"
  depends_on :macos # uses iTerm2's macOS-specific Python API

  resource "iterm2" do
    url "https://files.pythonhosted.org/packages/88/60/3e078e279b3142341ad359961b30d05fff73fa6fcc741861da65937edbe6/iterm2-2.15.tar.gz"
    sha256 "bf4cd83f5f571c60eeb20f1aa9d8defc59df31a0b823c97ab3f17091752d9d02"
  end

  resource "protobuf" do
    url "https://files.pythonhosted.org/packages/6b/6b/a0e95cad1ad7cc3f2c6821fcab91671bd5b78bd42afb357bb4765f29bc41/protobuf-7.34.1.tar.gz"
    sha256 "9ce42245e704cc5027be797c1db1eb93184d44d1cdd71811fb2d9b25ad541280"
  end

  resource "websockets" do
    url "https://files.pythonhosted.org/packages/04/24/4b2031d72e840ce4c1ccb255f693b15c334757fc50023e4db9537080b8c4/websockets-16.0.tar.gz"
    sha256 "5f6261a5e56e8d5c42a4497b364ea24d94d9563e8fbd44e78ac40879c60179b5"
  end

  def install
    venv = virtualenv_create(libexec, "python3.13")
    venv.pip_install resources

    # Install all bin/ files (including the _version_check.py helper next to scripts)
    bin.install Dir["bin/itmux-*"]
    libexec.install "bin/_version_check.py"

    # Backward-compat shim: tmux-chooser → itmux-chooser
    bin.install_symlink bin/"itmux-chooser" => "tmux-chooser"

    # Rewrite Python script shebangs to point at the venv interpreter
    # so `import iterm2` resolves. Also patch sys.path to find _version_check.
    %w[itmux-attach-all itmux-tidy-from-tmux itmux-tidy-from-iterm].each do |script|
      path = bin/script
      content = File.read(path)
      content.sub!(/\A#!.*\n/, "#!#{libexec}/bin/python\n")
      content.sub!(
        %r{sys\.path\.insert\(0, os\.path\.dirname\(os\.path\.realpath\(__file__\)\)\)},
        "sys.path.insert(0, '#{libexec}')",
      )
      File.write(path, content)
      chmod 0755, path
    end

    # Stash docs alongside for `brew home` / share inspection
    pkgshare.install "README.md"
    pkgshare.install "AGENTS.md" if File.exist?("AGENTS.md")
    pkgshare.install "TODO.md"   if File.exist?("TODO.md")
  end

  def caveats
    <<~EOS
      iterm-tmux-helpers requires iTerm2 with the Python API enabled:
        iTerm2 → Settings → General → Magic → Enable Python API

      Recommended iTerm defaults:
        defaults write com.googlecode.iterm2 AutoHideTmuxClientSession -int 1
        defaults write com.googlecode.iterm2 OpenTmuxWindowsIn -int 1

      To use itmux-chooser as your default new-window action, set the
      iTerm profile Command to:
        #{HOMEBREW_PREFIX}/bin/itmux-chooser

      Verified against tmux 3.6a and iTerm2 3.6.x. The scripts emit a
      one-line stderr warning on version mismatch — silence with:
        export ITMUX_SUPPRESS_VERSION_WARN=1
    EOS
  end

  test do
    # Smoke-test 1: scripts are present and executable.
    %w[itmux-chooser itmux-attach-all itmux-tidy-from-tmux itmux-tidy-from-iterm tmux-chooser].each do |script|
      assert_predicate bin/script, :executable?, "#{script} not executable"
    end

    # Smoke-test 2: Python scripts are syntactically valid (won't fully run
    # without a live iTerm2 + tmux environment, but parse must succeed).
    %w[itmux-attach-all itmux-tidy-from-tmux itmux-tidy-from-iterm].each do |script|
      system libexec/"bin/python", "-c", "import ast; ast.parse(open('#{bin}/#{script}').read())"
    end

    # Smoke-test 3: the version-check helper imports and runs without error
    # in the brew-built venv.
    system libexec/"bin/python", "-c",
           "import sys; sys.path.insert(0, '#{libexec}'); " \
           "import _version_check; _version_check.warn_if_versions_unverified()"
  end
end
