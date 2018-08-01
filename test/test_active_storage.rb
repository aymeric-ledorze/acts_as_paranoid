require "test_helper"

class ParanoidActiveStorageTest < ParanoidBaseTest
  def create_file_blob(filename: "hello.txt", content_type: "text/plain", metadata: nil)
    ActiveStorage::Blob.create_after_upload! io: file_fixture(filename).open, filename: filename, content_type: content_type, metadata: metadata
  end

  def test_paranoid_active_storage
    unless ENABLE_ACTIVE_STORAGE
      skip "ActiveStorage is only available for Rails >= 5.2"
    end
    pt = ParanoidTime.create(main_file: create_file_blob, files: [create_file_blob, create_file_blob], undependent_main_file: create_file_blob, undependent_files: [create_file_blob, create_file_blob])
    pt.destroy
  end
end
