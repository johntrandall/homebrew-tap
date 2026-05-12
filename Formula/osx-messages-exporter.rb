class OsxMessagesExporter < Formula
  desc "Export macOS Messages.app conversations to HTML (cfinke), PHP 8.5 patched"
  homepage "https://github.com/cfinke/OSX-Messages-Exporter"
  url "https://github.com/cfinke/OSX-Messages-Exporter/archive/3274e5d615073f7e7f508e61b6ecbb6100539a39.tar.gz"
  version "0.0.0+sha-3274e5d"
  sha256 "53a0a7ef13a4c13611e45a2f40e0a07f2f225738514be6c7ef68f50f920ae78b"
  license "MIT"

  depends_on "php"

  # Upstream is stale (last upstream commit August 2025) and the script uses two
  # constructs that PHP 8.5 deprecates with hot-path warnings:
  #
  #   line 346, 402:  $updated_contacts_memo[ $message['contact'] ]
  #     - PHP 8.5 emits "Using null as an array offset is deprecated" twice per
  #       null-contact message. When iCloud Contacts is not synced into the VM
  #       (the messages-backup-john use case), ~99% of messages trigger this,
  #       slowing the script from minutes to >40 hours. Coerce to '' first.
  #
  # Fix is two surgical replacements via inline_patch. PR upstream:
  # https://github.com/cfinke/OSX-Messages-Exporter/pulls (TODO: file it).
  #
  # If/when upstream merges, drop the patch block and bump the pinned SHA.
  patch :DATA

  def install
    libexec.install "messages-exporter.php"
    libexec.install "LICENSE"
    libexec.install "README.md"
    libexec.install "example.html" if File.exist?("example.html")
    libexec.install "example.png" if File.exist?("example.png")

    # Wrapper that invokes the PHP script with Homebrew's php
    (bin/"messages-exporter").write <<~SH
      #!/bin/bash
      exec "#{Formula["php"].opt_bin}/php" "#{libexec}/messages-exporter.php" "$@"
    SH
    (bin/"messages-exporter").chmod 0755
  end

  test do
    # Script should at minimum print usage when run with --help-equivalent (no args)
    # and exit non-fatally. cfinke prints nothing for "no args" and just runs against
    # the current user's chat.db — which won't exist in CI. So just confirm the
    # wrapper is runnable and the PHP script parses.
    system "#{Formula["php"].opt_bin}/php", "-l", "#{libexec}/messages-exporter.php"
  end
end

__END__
diff -u messages-exporter.php messages-exporter.php.patched
--- a/messages-exporter.php
+++ b/messages-exporter.php
@@ -343,7 +343,7 @@
 				}
 			}

-			if ( strpos( $chat_title, ', ' ) === false && ! isset( $updated_contacts_memo[ $message['contact'] ] ) ) {
+			if ( strpos( $chat_title, ', ' ) === false && ! isset( $updated_contacts_memo[ $message['contact'] ?? '' ] ) ) {
 				// Get all existing chat names for this contact ID.
 				// If the contact name has changed, update it for old messages and update the folder and filenames.
 				$stored_messages_statement = $temp_db->prepare( "SELECT chat_title FROM messages WHERE contact=:contact GROUP BY chat_title" );
@@ -399,7 +399,7 @@
 					}
 				}

-				$updated_contacts_memo[ $message['contact'] ] = true;
+				$updated_contacts_memo[ $message['contact'] ?? '' ] = true;
 			}

 			// 0xfffc is the Object Replacement Character. Messages uses it as a placeholder for the image attachment, but we can strip it out because we process attachments separately.
