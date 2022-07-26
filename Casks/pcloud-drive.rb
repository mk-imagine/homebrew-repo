#
# Cask:: pcloud-drive
# Recipe:: default
# Authors:: Mark Kim, Tom Gross
#
# Copyright:: © 2022,  Mark Kim
# License:: GPLv3.0
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cask "pcloud-drive" do
  name "pCloud Drive"
  desc "Utilities to mount and manage pCloud drive on local computer"
  homepage "https://www.pcloud.com/"

  if Hardware::CPU.intel?
    version "3.11.6"
    arch = "Mac"
    sha256 "557c319c64fdbda0fdad871fe7a058735a9cd96742a4472cf0061c80cd5a23cb"
    pkg "pCloud Drive #{version.to_s}.pkg"
    dlUrl = "https://www.pcloud.com/how-to-install-pcloud-drive-mac-os.html?download=mac"
  else
    version "3.11.7"
    arch = "MacM1"
    sha256 "07d063d7a2868832e633d257a6243642224d6c32e7faff6fd64a911f0079dc07"
    pkg "pCloud Drive #{version.to_s} macFUSE.pkg"
    dlUrl = "https://www.pcloud.com/how-to-install-pcloud-drive-mac-os-m1.html?download=macm1"
  end

  url do
    require "net/http"
    require "uri"
    require "json"
    uri = URI.parse(dlUrl)
    response = Net::HTTP.get_response(uri)
    dlCodes = response.body[/(driveDLcode = {[^}]*})/]
    dlCodes = dlCodes[/({[^}]*})/].chars.reject {|char| char.ord == 10}.reject {|char| char.ord == 32}.reject {|char| char.ord == 9}.join.gsub!("'", '"')
    dlCodes = JSON.parse(dlCodes)
    api = "https://api.pcloud.com/"
    dlcode = dlCodes[arch]
    uri = URI(api + "getpublinkdownload?code=" + dlcode)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    data["hosts"][0] + data["path"]
  end

  depends_on cask: "macfuse"

  uninstall quit:    "com.pcloud.pcloud.macos",
            pkgutil: "com.mobileinno.pkg.pCloudDrive"

end
