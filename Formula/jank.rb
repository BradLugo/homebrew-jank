class Jank < Formula
  desc "Native Clojure dialect hosted on LLVM"
  homepage "https://jank-lang.org"
  url "https://github.com/jank-lang/jank.git", branch: "main"
  version "0.1"
  license "MPL-2.0"

  depends_on "cmake" => :build
  depends_on "git-lfs" => :build
  depends_on "ninja" => :build

  depends_on "bdw-gc"
  depends_on "boost"
  depends_on "libzip"
  depends_on "llvm@19"
  depends_on "openssl"

  def install
    ENV.prepend_path "PATH", Formula["git-lfs"].opt_bin
    ENV.prepend_path "PATH", Formula["llvm@19"].opt_bin

    ENV.append "LDFLAGS", "-Wl,-rpath,#{Formula["llvm@19"].opt_lib}"

    ENV.append "CPPFLAGS", "-L#{Formula["llvm@19"].opt_include}"
    ENV.append "CPPFLAGS", "-fno-sized-deallocation"

    jank_install_dir = OS.linux? ? libexec : bin
    inreplace "compiler+runtime/cmake/install.cmake",
              '\\$ORIGIN',
              jank_install_dir

    if OS.mac?
      ENV["SDKROOT"] = MacOS.sdk_path
    else
      ENV["CC"] = Formula["llvm@19"].opt_bin/"clang"
      ENV["CXX"] = Formula["llvm@19"].opt_bin/"clang++"
    end

    cd "compiler+runtime"

    system "./bin/configure",
           "-GNinja",
           "-DHOMEBREW_ALLOW_FETCHCONTENT=ON",
           *std_cmake_args
    system "./bin/compile"
    system "./bin/install"
  end

  test do
    test_file = testpath/"test.jank"
    test_file.write <<~JANK
      ((fn [] (+ 5 7)))
    JANK

    assert_equal "12", shell_output("#{bin}/jank run #{test_file}").strip.lines.last

    assert_path_exists test_file
    assert_predicate jank, :executable?, "jank must be executable"
  end
end
