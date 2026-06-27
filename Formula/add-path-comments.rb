# add-path-comments/Formula/add-path-comments.rb
class AddPathComments < Formula
  desc "Add file path comments to TypeScript/TSX, Rust, and Python projects"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments"
  url "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments/archive/refs/tags/v1.0.4.tar.gz"
  sha256 "d2a17fafd35dfec6b4b71ce1ffc109be68c44943ac98ed130bd960d34f4ef454"
  license "MIT"
  version "1.0.4"

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
