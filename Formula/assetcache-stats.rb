class AssetcacheStats < Formula
  desc "Parse macOS Content Caching status into InfluxDB line protocol"
  homepage "https://github.com/johntrandall/assetcache-stats"
  url "https://github.com/johntrandall/assetcache-stats/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "9619ecdac02b7390d98e35a9940baf9c2b164cb22f03dec9e3e8b1eb818ca754"
  license "MIT"
  head "https://github.com/johntrandall/assetcache-stats.git", branch: "main"

  depends_on :macos

  def install
    bin.install "assetcache-stats"
    pkgshare.install "README.md", "LICENSE"
  end

  def caveats
    <<~EOS
      `assetcache-stats` reads /usr/bin/AssetCacheManagerUtil status, which
      requires root. For a service-account collector (e.g. invoked from
      telegraf, xyOps, or launchd), add a NOPASSWD sudoers rule scoped to
      the binary:

        echo "<user> ALL=(root) NOPASSWD: /usr/bin/AssetCacheManagerUtil" \\
          | sudo tee /etc/sudoers.d/assetcache-stats >/dev/null
        sudo chmod 0440 /etc/sudoers.d/assetcache-stats
        sudo visudo -c

      Then `assetcache-stats` emits one InfluxDB-line-protocol record on
      stdout per invocation. Compose with curl:

        assetcache-stats \\
          | curl -s --data-binary @- \\
              -H "Authorization: Token $INFLUX_TOKEN" \\
              "$INFLUX_URL/api/v2/write?org=$ORG&bucket=$BUCKET&precision=ns"
    EOS
  end

  test do
    assert_predicate bin/"assetcache-stats", :executable?
    # On macs without Content Caching activated (or without sudo to AssetCacheManagerUtil),
    # the script still emits exactly one row containing the measurement name + activated=0i.
    output = shell_output("#{bin}/assetcache-stats")
    assert_match "content_caching", output
    assert_match "activated=", output
    # Single line of output
    assert_equal 1, output.lines.count
  end
end
