# frozen_string_literal: true

# Formula for the Bushpilot runtime bundle (frank321/homebrew-bushpilot tap).
#
# The upstream project ships a prebuilt, self-contained runtime zip as a GitHub
# Release asset (built by docs/build_release.sh). This formula installs that
# bundle under libexec and exposes the three user-facing commands as bin
# wrappers. The scripts resolve their own directory via SCRIPT_DIR/BASH_SOURCE
# and keep all mutable state (the MLX venv, downloaded model weights, logs) under
# ~/.bushpilot/, so the Cellar install can stay read-only exactly as Homebrew
# requires -- nothing is ever written next to the installed files.
#
# Self-symlinking guard: start_mlx_server.sh / launch_tool.sh normally symlink
# themselves into a writable $PATH dir. They detect a Cellar install and skip
# that, so they never clobber these wrappers. See the guard in each script.
class Bushpilot < Formula
  desc "Local LLM cockpit for Apple Silicon: hardware-aware MLX model server"
  homepage "https://github.com/frank321/bushpilot"
  url "https://github.com/frank321/bushpilot/releases/download/v0.1.0/bushpilot.zip"
  sha256 "0b120b6cb372e508b7c7aab456121c0bacbd36a44a916e52c48feab9fd0af86f"
  license "MIT"

  # livecheck lets `brew livecheck` (and the tap's scheduled bump workflow) find
  # new versions from the upstream project's GitHub Releases without any
  # hardcoded version in this file. :github_latest reads the repo's "latest
  # release" tag from the GitHub API, so url must be the repo (== homepage here);
  # the asset URL above has no version pattern of its own and fails to resolve.
  # No custom regex -- the default strategy handles the v-prefix. The
  # update-formula workflow rewrites url/sha256 when a newer tag appears.
  livecheck do
    url :homepage
    strategy :github_latest
  end

  # Apple Silicon + macOS only -- the MLX backend and the whole window of models
  # this catalog targets are arm64/Metal. Intel Macs and Linux are out of scope.
  #
  # Dependency order below is Homebrew's required ordering (arch and macOS-style
  # deps sort among the named ones), not logical grouping -- brew style enforces it.
  depends_on arch: :arm64
  # fzf powers the interactive model/tool pickers.
  depends_on "fzf"
  depends_on :macos
  # Python >=3.10 is required by mlx-vlm. The server's own bootstrap creates its
  # venv from a suitable python3 it finds, but declaring it means `brew install`
  # pulls one in rather than relying on whatever the user happens to have.
  depends_on "python@3.12"

  def install
    # The release zip extracts to a top-level "bushpilot/" directory.
    libexec.install Dir["*"]

    # model_advisor.py is a thin shim over the bushpilot/ package -- both ship
    # together, and PYTHONPATH must include libexec for `import bushpilot` to
    # resolve (the scripts already set PYTHONPATH="$SCRIPT_DIR" internally, this
    # is belt-and-braces for anything invoking the shim directly).
    bin.install_symlink libexec/"start_mlx_server.sh" => "bushpilot-server"
    bin.install_symlink libexec/"launch_tool.sh"      => "bushpilot"
    bin.install_symlink libexec/"uninstall.sh"        => "bushpilot-uninstall"
  end

  def caveats
    <<~EOS
      Bushpilot keeps everything it downloads (MLX venv, model weights, logs) under:
        ~/.bushpilot/

      To start the model server:
        bushpilot-server

      To attach a coding tool (Claude Code, OpenCode, Aider, Cline, Pi):
        bushpilot

      To remove downloaded models and state:
        bushpilot-uninstall

      The original script names are also available in:
        #{opt_libexec}
    EOS
  end

  test do
    # The advisor is the one piece that runs with no Apple Silicon GPU work and
    # no downloaded model -- a pure-logic JSON emit. Proves the bundle, the
    # python dependency link, and the bushpilot/ package all landed intact.
    #
    # Note: Homebrew's python@3.12 provides `python3.12`, NOT `python3` -- the
    # unversioned name only comes from the unversioned `python` formula, which
    # may be a different version. The wrong name silently yields exit 127.
    python = formula_opt_bin("python@3.12")/"python3.12"
    assert_match(/"id"\s*:/, shell_output("#{python} #{libexec}/model_advisor.py --list-json"))
    assert_path_exists libexec/"models.json"
    assert_predicate libexec/"bushpilot", :directory?
  end
end
