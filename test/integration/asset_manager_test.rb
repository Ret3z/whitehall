require 'test_helper'

class AssetManagerIntegrationTest < ActiveSupport::TestCase
  test 'creating an asset uploads it to asset manager and saves it to the file system' do
    Whitehall.stubs(:use_asset_manager).returns(true)

    filename = '960x640_jpeg.jpg'
    organisation = FactoryGirl.build(
      :organisation,
      organisation_logo_type_id: OrganisationLogoType::CustomLogo.id,
      logo: File.open(Rails.root.join('test', 'fixtures', 'images', filename))
    )

    # ensure asset is sent to asset manager
    Services.asset_manager.expects(:create_whitehall_asset).with do |args|
      args[:file].is_a?(File) &&
        args[:legacy_url_path] =~ /#{filename}/
    end

    organisation.save!

    # ensure asset is saved to the file system
    assert File.exist?(organisation.logo.path)
  end

  test 'removing an asset removes it from file system and asset manager' do
    Whitehall.stubs(:use_asset_manager).returns(true)

    organisation = FactoryGirl.create(
      :organisation,
      organisation_logo_type_id: OrganisationLogoType::CustomLogo.id,
      logo: File.open(Rails.root.join('test', 'fixtures', 'images', '960x640_jpeg.jpg'))
    )
    VirusScanHelpers.simulate_virus_scan(organisation.logo)
    organisation.reload

    logo_path = organisation.logo.path
    assert File.exist?(logo_path)

    Services.asset_manager.stubs(:whitehall_asset).returns('id' => 'http://asset-manager/assets/asset-id')
    Services.asset_manager.expects(:delete_asset)

    organisation.remove_logo!
    organisation.reload

    refute File.exist?(logo_path)
    refute organisation.logo.present?
  end
end
