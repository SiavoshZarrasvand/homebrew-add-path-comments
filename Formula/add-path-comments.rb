# add-path-comments/Formula/add-path-comments.rb
class AddPathComments < Formula
  desc "Add file path comments to TypeScript/TSX, Rust, and Python projects"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments"
  url "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "4d34da0045e8f0d507e66cde15b63de9488644e6c4a1506a903fd6d9be993e3a"
  license "MIT"
  version "1.0.7"

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
