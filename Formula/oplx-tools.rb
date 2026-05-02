class OplxTools < Formula
  include Language::Python::Virtualenv

  desc "Generate, lint, and parse OmniPlan .oplx files (no OmniPlan needed)"
  homepage "https://github.com/johntrandall/oplx-tools"
  url "https://github.com/johntrandall/oplx-tools/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "6e54b68cae9a7aa4015125e14e9c919a91110ff4c3b77272deff22c6be24a50c"
  license "MIT"
  head "https://github.com/johntrandall/oplx-tools.git", branch: "main"

  depends_on "libyaml"
  depends_on "python@3.13"

  uses_from_macos "libxml2"
  uses_from_macos "libxslt"

  resource "lxml" do
    url "https://files.pythonhosted.org/packages/28/30/9abc9e34c657c33834eaf6cd02124c61bdf5944d802aa48e69be8da3585d/lxml-6.1.0.tar.gz"
    sha256 "bfd57d8008c4965709a919c3e9a98f76c2c7cb319086b3d26858250620023b13"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    venv = virtualenv_create(libexec, "python3.13")
    venv.pip_install resources
    venv.pip_install_and_link buildpath
  end

  test do
    assert_predicate bin/"oplx", :executable?
    output = shell_output("#{bin}/oplx --help")
    assert_match "OmniPlan", output

    # Round-trip: generate from a YAML, lint the result, parse it back.
    (testpath/"project.yaml").write <<~YAML
      title: Test Project
      start_date: 2026-06-01T13:00:00Z
      tasks:
        - id: t1
          title: Plan
          effort: 14400
        - id: t2
          title: Build
          effort: 28800
          depends_on: [t1]
    YAML

    system bin/"oplx", "generate", testpath/"project.yaml", "--out", testpath/"out.oplx"
    assert_path_exists testpath/"out.oplx"

    lint_output = shell_output("#{bin}/oplx lint #{testpath}/out.oplx")
    assert_match "no findings", lint_output

    parse_output = shell_output("#{bin}/oplx parse #{testpath}/out.oplx")
    assert_match "Plan", parse_output
    assert_match "Build", parse_output
  end
end
