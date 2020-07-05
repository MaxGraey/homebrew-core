require "language/node"

class Emscripten < Formula
  desc "LLVM bytecode to JavaScript compiler"
  homepage "https://emscripten.org/"

  stable do
    url "https://github.com/emscripten-core/emscripten/archive/1.39.18.tar.gz"
    sha256 "aa0df2828096d161636467d4fc062bbeea31e372c122a05c9685bb6cb2d4064e"
  end

  bottle do
    cellar :any
    sha256 "b6f8f53965798b8143d8ec8c094c3f1769f75130cabe0a6dfcb89fe745c54a70" => :catalina
    sha256 "288cab4671f7b2b99119e5d738cbdcd1cf685c8118364a7642a3f01739f7fbf6" => :mojave
    sha256 "66617c1989c49350c360dc4d0561ccdc4a96c409e84b289d70190ae7c65a8716" => :high_sierra
  end

  head do
    url "https://github.com/emscripten-core/emscripten.git", :branch => "master"
  end

  depends_on "cmake" => :build
  depends_on "llvm"
  depends_on "binaryen"
  depends_on "node"
  depends_on "python@3.8"
  depends_on "yuicompressor"

  def install
    ENV.cxx14

    # All files from the repository are required as emscripten is a collection
    # of scripts which need to be installed in the same layout as in the Git
    # repository.
    libexec.install Dir["*"]

    cmake_args = [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DLLVM_ENABLE_PROJECTS='lld;clang'",
      "-DLLVM_TARGETS_TO_BUILD='X86;JSBackend'",
      "-DLLVM_INCLUDE_EXAMPLES=OFF",
      "-DLLVM_INCLUDE_TESTS=OFF",
      "-DCLANG_INCLUDE_TESTS=OFF",
      "-DOCAMLFIND=/usr/bin/false",
      "-DGO_EXECUTABLE=/usr/bin/false",
    ]

    mkdir "upstream/build" do
      system "cmake", "..", *cmake_args
      system "make"
      system "make", "install"
    end

    cd libexec do
      system "npm", "install", *Language::Node.local_npm_install_args
      rm_f "node_modules/ws/builderror.log" # Avoid references to Homebrew shims
    end

    %w[em++ em-config emar emcc emcmake emconfigure emlink.py emmake
       emranlib emrun emscons].each do |emscript|
      (bin/emscript).write_env_script libexec/emscript, :PYTHON => Formula["python@3.8"].opt_bin/"python3"
    end
  end

  test do
    system bin/"emcc"
    assert_predicate testpath/".emscripten", :exist?, "Failed to create sample config"
  end
end
