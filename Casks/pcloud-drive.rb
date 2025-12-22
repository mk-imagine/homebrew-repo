cask "pcloud-drive" do
  version "4.0.6"
  sha256 "e973f77d2ef32644e280493b949ce9c04513ea7978e6b66fbb602673ba881ce5"

  class PcloudDriveDownloadLogicStrategy < CurlDownloadStrategy
    def fetch(timeout: nil, **_options)
      require "net/http"
      require "uri"
      require "json"
      require "fileutils"

      initial_page_url = "https://www.pcloud.com/how-to-install-pcloud-drive-mac-os.html?download=mac"
      ohai "Fetching initial page to extract download codes: #{initial_page_url}"
      
      uri = URI.parse(initial_page_url)
      response = Net::HTTP.get_response(uri)
      unless response.is_a?(Net::HTTPSuccess)
        odie "Failed to fetch initial page: #{initial_page_url}. Status: #{response.code}"
      end
      page_content = response.body

      drive_dl_code_match = page_content.match(/var\s+driveDLcode\s*=\s*({[^{}]*});/m)
      unless drive_dl_code_match && drive_dl_code_match[1]
        odie "Could not find download code from pCloud website (#{initial_page_url})."
      end
      js_object_string = drive_dl_code_match[1]

      json_compatible_string = js_object_string.gsub(/'/, '"')
                                            .gsub(/,\s*([}\]])/, '\1') 
      
      begin
        parsed_codes = JSON.parse(json_compatible_string)
      rescue JSON::ParserError => e
        odie "Failed to parse download code as JSON. String was: '#{json_compatible_string}'. Error: #{e.message}"
      end

      api_code = parsed_codes['Mac']
      unless api_code
        odie "Could not find architecture for 'Mac' amongst download codes. Available architectures: #{parsed_codes.keys.join(", ")}"
      end
    #   ohai "Found API code for 'Mac': #{api_code}"

      api_url_string = "https://api.pcloud.com/getpublinkdownload?code=#{api_code}"
      api_uri = URI.parse(api_url_string)
      ohai "Fetching download link from API: #{api_uri}"

      api_response = Net::HTTP.get_response(api_uri)
      unless api_response.is_a?(Net::HTTPSuccess)
        odie "Failed to fetch from pCloud API: #{api_uri}. Status: #{api_response.code}. Body: #{api_response.body}"
      end
      api_response_body = api_response.body

      begin
        api_data = JSON.parse(api_response_body)
      rescue JSON::ParserError => e
        odie "Failed to parse API response as JSON. Error: #{e.message}. Response body: #{api_response_body}"
      end

      unless api_data["result"] == 0 && api_data["hosts"]&.first && api_data["path"]
        odie "API response indicates an error or did not contain expected 'hosts' or 'path'. Response: #{api_data.inspect}"
      end

      final_pkg_url = "https://#{api_data["hosts"].first}#{api_data["path"]}"
      ohai "Resolved final PKG URL: #{final_pkg_url}"
      
      incomplete_download_path = temporary_path 
      final_cached_path = Pathname.new(incomplete_download_path.to_s.chomp(".incomplete"))

    #   ohai "DEBUG: Curl will download to (incomplete path): #{incomplete_download_path}"
    #   ohai "DEBUG: Final cache path expected by Homebrew (after rename): #{final_cached_path}"

      system_command! "/usr/bin/curl",
                      args: [
                        "--fail",
                        "--location",
                        "--output", incomplete_download_path,
                        final_pkg_url
                      ],
                      print_stderr: true
      
    #   ohai "DEBUG: Curl command completed."

      unless File.exist?(incomplete_download_path)
        odie "Download failed: File does not exist at #{incomplete_download_path}."
      end
      
      file_size = File.size(incomplete_download_path)
    #   ohai "DEBUG: File EXISTS at #{incomplete_download_path} after curl. Size: #{file_size} bytes."
      
    #   ohai "Renaming incomplete download from #{incomplete_download_path} to #{final_cached_path}"
      begin
        FileUtils.mv(incomplete_download_path, final_cached_path)
      rescue StandardError => e
        odie "Failed to rename downloaded file from #{incomplete_download_path} to #{final_cached_path}: #{e.message}"
      end

      unless File.exist?(final_cached_path)
        odie "Rename failed: Final file does not exist at #{final_cached_path} after rename."
      end
    #   ohai "File successfully renamed to #{final_cached_path}."
    end
  end

  # Dummy URL: the filename part here should match the `pkg` stanza below.
  url "file://localhost/homebrew_cask_placeholders/#{token}/#{version}/pCloud%20Drive%20#{version}%20UNIVERSAL.pkg",
      using: PcloudDriveDownloadLogicStrategy

  name "pCloud Drive"
  desc "Mount and manage pCloud drive on local computer"
  homepage "https://www.pcloud.com/"
  
  auto_updates true
  depends_on cask: "macfuse"

  pkg "pCloud Drive #{version} UNIVERSAL.pkg"

  uninstall quit:    "com.pcloud.pcloud.macos",
            pkgutil: "com.mobileinno.pkg.pCloudDrive"
end