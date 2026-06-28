# add-path-comments/Formula/add-path-comments.rb
class AddPathComments < Formula
  desc "Add file path comments to TypeScript/TSX, Rust, and Python projects"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments"
  url "https://github.com/SiavoshZarrasvand/homebrew-add-path-comments/archive/refs/tags/v1.0.5.tar.gz"
  sha256 "cadef61422c17b0bca37d987faf177d757c2637c4a1543cd28b498798dc8d058"
  license "MIT"
  version "1.0.5"

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
