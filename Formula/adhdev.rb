require "language/node"

class Adhdev < Formula
  desc "Control plane for your coding agents — remote control CLI and IDE agents"
  homepage "https://adhf.dev"
  url "https://registry.npmjs.org/adhdev/-/adhdev-1.0.73.tgz"
  sha256 "07948752dbf83214dc40943f3e9ae0291b0f5cd12bbb4ddb9287e1c4e3d995e9"
  license "AGPL-3.0-only"

  depends_on "node"

  def install
    # The adhdev npm package pulls in native addons (better-sqlite3,
    # node-datachannel, node-pty, @adhdev/ghostty-vt-node). The install below is
    # tuned so they resolve to their published prebuilt .node binaries rather than
    # compiling from source, which is both faster and more robust here.
    #
    # ignore_scripts: false — the addons place their .node bindings in
    #   install/postinstall scripts (prebuild-install, node-gyp). The default
    #   ignore_scripts: true would skip them and the CLI would crash at runtime.
    #
    # .grep_v("--build-from-source") — std_npm_args hardcodes --build-from-source,
    #   which forces the addons to skip prebuilts and compile from source.
    #   node-datachannel in particular then needs cmake/pkg-config and a full
    #   libdatachannel build. Every platform Homebrew builds on has a matching
    #   prebuilt, so we strip the flag and let prebuild-install fetch it.
    #
    # --min-release-age=0 — std_npm_args injects --min-release-age=<cooldown days>
    #   to skip freshly published (possibly compromised) releases, but adhdev's own
    #   first-party deps (@adhdev/mesh-shared, @adhdev/daemon-core,
    #   @adhdev/ghostty-vt-node) are pinned as "*" and are often published the same
    #   day as the adhdev release, so the cooldown rejects them with ETARGET. These
    #   are our own trusted packages; npm is last-wins for the repeated flag, so
    #   this disables the cooldown for this install only.
    system "npm", "install",
           *std_npm_args(prefix: libexec, ignore_scripts: false).grep_v("--build-from-source"),
           "--min-release-age=0"
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/adhdev --version")
    assert_path_exists bin/"adhdev-mcp"
    assert_path_exists bin/"adhmux"
  end
end
