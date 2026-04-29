class ZkReindexLaunchd < Formula
  desc "Auto-reindex zk notebooks on macOS via a LaunchAgent (set-and-forget)"
  homepage "https://github.com/johntrandall/zk-reindex-launchd"
  url "https://github.com/johntrandall/zk-reindex-launchd/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "ae9e636f461c2c77c45140f2138af313d20cb3500e3ac504e233c755b17c0f9b"
  license "MIT"

  depends_on "zk"
  depends_on :macos

  def install
    bin.install "bin/zk-reindex-all"
    pkgshare.install "README.md", "LICENSE"
  end

  def post_install
    config_dir = Pathname.new(Dir.home)/".config/zk-reindex-launchd"
    config_file = config_dir/"notebooks.conf"
    return if config_file.exist?

    config_dir.mkpath
    config_file.write <<~CONFIG
      # zk-reindex-launchd: notebooks to reindex
      # Format: <path>[:<maxdepth>]
      # Lines starting with # are comments; blank lines are ignored.
      #
      # Examples:
      #   #{Dir.home}/notes              # full-depth scan
      #   #{Dir.home}/Obsidian:3         # cap descent at 3 levels
      #   #{Dir.home}/dev:2              # only catch <project>/.zk, skip subtrees
      #
      # Edits take effect on the next cycle (~5 min) — no service reload needed.

    CONFIG
    ohai "Seeded #{config_file}"
  end

  service do
    run [opt_bin/"zk-reindex-all"]
    interval 300
    process_type :background
    log_path "#{Dir.home}/Library/Logs/zk-reindex-all.log"
    error_log_path "#{Dir.home}/Library/Logs/zk-reindex-all.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      Edit your notebook list at:
        #{Dir.home}/.config/zk-reindex-launchd/notebooks.conf

      Format: one absolute path per line, optionally followed by `:N` for
      maxdepth (useful for ~/dev so you only catch <project>/.zk and skip
      deep repo subtrees). Edits are picked up on the next cycle — no
      service reload needed.

      Start the service:
        brew services start zk-reindex-launchd

      Tail the log:
        tail -f #{Dir.home}/Library/Logs/zk-reindex-all.log

      The agent runs every 5 minutes by default. Idle cost is well under
      1% of one CPU core, with ~zero SSD writes when nothing changed.
    EOS
  end

  test do
    assert_predicate bin/"zk-reindex-all", :executable?
    # Run with no roots configured — should print "no notebooks under" and exit 0
    output = shell_output("ZK_REINDEX_ROOTS=#{testpath}/empty #{bin}/zk-reindex-all")
    assert_match "no notebooks under", output
  end
end
