cask "pcloud-drive" do
  # Each pCloud release has its own public-link code (the second CSV field).
  # Find a new one as `downloads_mac_code` in the JS of pCloud's download page,
  # or as the `code=` of the getpublinkdownload request that page makes, then
  # confirm it with https://api.pcloud.com/showpublink?code=<code>
  version "4.3.3,XZBi4YJZRSvki6qo2mbqOlWozl1s4FhQI9xy"
  sha256 "7bf387aa81aaa739061948c698eadac20ab14a73d23e02d4b67f6890cb649a2e"

  # The pCloud API only hands out short-lived download URLs for a public link.
  # This strategy asks it for a fresh one at fetch time; Homebrew's curl
  # strategy does the rest (download, cache, checksum).
  class PcloudPublinkDownloadStrategy < CurlDownloadStrategy
    def resolve_url_basename_time_file_size(url, timeout: nil)
      return super unless url.start_with?("https://api.pcloud.com/getpublinkdownload?")

      @pcloud_download_url ||= begin
        require "json"

        result = curl_output("--fail", "--silent", "--show-error", url, timeout:)
        raise CurlDownloadStrategyError.new(url, result.stderr.strip) unless result.success?

        response = JSON.parse(result.stdout)
        host = response["hosts"]&.first
        if response["result"] != 0 || host.nil? || response["path"].nil?
          raise CurlDownloadStrategyError.new(url, "pCloud API error: #{response["error"] || response.inspect}")
        end

        "https://#{host}#{response["path"]}"
      end

      super(@pcloud_download_url, timeout:)
    end
  end

  url "https://api.pcloud.com/getpublinkdownload?code=#{version.csv.second}",
      using: PcloudPublinkDownloadStrategy
  name "pCloud Drive"
  desc "Mount and manage pCloud drive on local computer"
  homepage "https://www.pcloud.com/"

  auto_updates true
  depends_on cask: "macfuse"
  depends_on :macos

  pkg "pCloud Drive #{version.csv.first} UNIVERSAL.pkg"

  uninstall quit:    "com.pcloud.pcloud.macos",
            pkgutil: "com.mobileinno.pkg.pCloudDrive"
end
