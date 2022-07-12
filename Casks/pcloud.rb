cask 'pcloud-drive-M1' do
  version '3.11.6'
  sha256 '543d580d94bd9869d1c457563102132efa8db2205f1ecab98de92c5e65ff4e9d'

  url do
    require 'net/http'
    require 'json'
    api = 'https://api.pcloud.com/'
    code = 'XZ8uazVZhIfArB0E8rbWyTbLiC1d8mOubnzX'
    uri = URI(api + 'getpublinkdownload?code=' + code)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    data['hosts'][0] + data['path']
  end
  name 'pCloud Drive'
  homepage 'https://www.pcloud.com/'

  depends_on cask: 'macfuse'

  pkg '_pCloud Drive 3.11.6 macFUSE'

  uninstall quit:    'com.pcloud.pcloud.macos',
            pkgutil: 'com.mobileinno.pkg.pCloudDrive'
end
