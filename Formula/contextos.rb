class Contextos < Formula
  include Language::Python::Virtualenv

  desc "Local memory layer for Claude Code"
  homepage "https://github.com/harsh779/contextos-claude-memory"
  head "https://github.com/harsh779/contextos-claude-memory.git", branch: "main"
  license "MIT"

  depends_on "python@3.12"

  def install
    virtualenv_install_with_resources
  end

  test do
    system "#{bin}/contextos", "--version"
  end
end
