class Lash < Formula
  include Language::Python::Virtualenv

  desc "Manifest-driven symlink installer (lash.json defines install + uninstall in sync)"
  homepage "https://github.com/johntrandall/lash"
  url "https://github.com/johntrandall/lash/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "b2369277d65c7729fcfe458be8762a3c17fc964684e8bdeeef1e715d9cfdbb5e"
  license "MIT"
  head "https://github.com/johntrandall/lash.git", branch: "main"

  depends_on "python@3.13"

  def install
    venv = virtualenv_create(libexec, "python3.13")
    venv.pip_install_and_link buildpath
  end

  test do
    assert_predicate bin/"lash", :executable?
    # `lash --help` should exit 0 and mention "manifest-driven"
    output = shell_output("#{bin}/lash --help")
    assert_match "manifest-driven", output
  end
end
