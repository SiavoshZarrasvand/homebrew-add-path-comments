class AddPathComments < Formula
  desc "Add file path comments to TypeScript/TSX, Rust, and Python projects"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments"
  url "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "ec4728beb9523125bb0c04c1c21206abe3ea0f522cbe57675bf6fcd6052779a9"
  license "MIT"
  version "1.0.1"

  depends_on :macos

  def install
    chmod 0755, "add-path-comments"
    bin.install "add-path-comments"
  end

  test do
    output = shell_output("#{bin}/add-path-comments --version")
    assert_match version.to_s, output
  end
end
