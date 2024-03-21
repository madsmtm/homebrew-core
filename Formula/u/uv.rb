class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.23.tar.gz"
  sha256 "7a491529c2aef1b2243ffc221f716303b1ec5d55896c055fd7b35a44e6973661"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "12b6a3593b9ea79aa3ced660f1452c774dd72f77fc5d4bd0bfbc06f4afbdc023"
    sha256 cellar: :any,                 arm64_ventura:  "3c3c486bda6668360b6baa52b11b53ce404ab91eb676145047c9634120c3392b"
    sha256 cellar: :any,                 arm64_monterey: "ecce4ff8425bcb5ba066d07e690e2eca3dc7e0a848f151becac8bf4f9f91685f"
    sha256 cellar: :any,                 sonoma:         "7eb51b553de5bc853f6e4d5be4d438c3db34566f9317d9df7ddd65414550d1c2"
    sha256 cellar: :any,                 ventura:        "704d8631ccd6ed5683bfa2f0d4d5278a86ca9810ae2f00e0c6f6080da2e20328"
    sha256 cellar: :any,                 monterey:       "101eb337469a452770d7c281b42fce4662a4edf55665f2b530181110f507b305"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "d6ba29bcba66ccd657a8d95897a9608debe1a8324e1356c5da96ea21c1e5f660"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
