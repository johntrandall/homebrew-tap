class HalfSheetLabel < Formula
  include Language::Python::Virtualenv

  desc "Impose a shipping label PDF onto half-sheet 2-up stock and print it"
  homepage "https://github.com/johntrandall/half-sheet-label"
  url "https://github.com/johntrandall/half-sheet-label/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "75a88c89e5f933c942499e3f9f3bd5db6a6600c41fdc39b4841429373d230d95"
  license "MIT"
  head "https://github.com/johntrandall/half-sheet-label.git", branch: "main"

  depends_on "ghostscript"
  depends_on :macos
  depends_on "python@3.13"

  resource "pypdf" do
    url "https://files.pythonhosted.org/packages/1a/7f/5bc369dedae6750e23fc9ce82f6396258f92ed80ae0137732738a6d4ffce/pypdf-6.16.0.tar.gz"
    sha256 "dfc5b0afeb5e02e9ee1dce71c09071f062d1a4030d2925f03a5daee0ee975ed8"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "half-sheet-label", shell_output("#{bin}/half-sheet-label --version")
  end
end
