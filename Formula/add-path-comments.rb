# add-path-comments/Formula/add-path-comments.rb
class AddPathComments < Formula
  desc "Add file path comments to TypeScript/TSX, Rust, and Python projects"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments"
  url "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments/archive/refs/tags/v1.0.6.tar.gz"
  sha256 "4094c613a3de14c3370f4a05de5742af80125ea100575721c166547060bff85a"
  license "MIT"
  version "1.0.6"

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
