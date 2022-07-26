cask 'pcloud-drive' do
  name 'pCloud Drive'
  desc 'Utilities to mount and manage pCloud drive on local computer'
  homepage 'https://www.pcloud.com/'

  if Hardware::CPU.intel?
    version '3.11.6'
    arch = "Mac"
    sha256 '557c319c64fdbda0fdad871fe7a058735a9cd96742a4472cf0061c80cd5a23cb'
    pkg 'pCloud Drive 3.11.6.pkg'
    dlUrl = "https://www.pcloud.com/how-to-install-pcloud-drive-mac-os.html?download=mac"
  else
    version '3.11.7'
    arch = "MacM1"
    sha256 '07d063d7a2868832e633d257a6243642224d6c32e7faff6fd64a911f0079dc07'
    pkg 'pCloud Drive 3.11.7 macFUSE.pkg'
    dlUrl = "https://www.pcloud.com/how-to-install-pcloud-drive-mac-os-m1.html?download=macm1"
  end

  url do
    require 'net/http'
    require 'uri'
    require 'json'
    uri = URI.parse(dlUrl)
    response = Net::HTTP.get_response(uri)
    dlCodes = response.body[/(driveDLcode = {[^}]*})/]
    dlCodes = dlCodes[/({[^}]*})/].chars.reject {|char| char.ord == 10}.reject {|char| char.ord == 32}.reject {|char| char.ord == 9}.join.gsub!("'", '"')
    dlCodes = JSON.parse(dlCodes)
    api = 'https://api.pcloud.com/'
    dlcode = dlCodes[arch]
    uri = URI(api + 'getpublinkdownload?code=' + dlcode)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    data['hosts'][0] + data['path']
  end

  depends_on cask: 'macfuse'

  uninstall quit:    'com.pcloud.pcloud.macos',
            pkgutil: 'com.mobileinno.pkg.pCloudDrive'

end
