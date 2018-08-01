# frozen_string_literal: true

require "bundler"
begin
  Bundler.load
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems"
  exit e.status_code
end

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
end

require "acts_as_paranoid"
require "minitest/autorun"

ENABLE_ACTIVE_STORAGE = ActiveRecord::VERSION::MAJOR > 5 || (ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR >= 2)
if ENABLE_ACTIVE_STORAGE
  # load ActiveStorage
  require "global_id"
  ActiveRecord::Base.include(GlobalID::Identification)
  GlobalID.app = "ActsAsParanoid"

  require "active_job"
  ActiveJob::Base.queue_adapter = :test

  require "active_support/cache"

  require "active_storage"
  require "active_storage/attached"
  require "active_storage/service/disk_service"
  if ActiveRecord::VERSION::MAJOR >= 6
    require "active_storage/reflection"
    ActiveRecord::Base.include(ActiveStorage::Reflection::ActiveRecordExtensions)
    ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)
    ActiveRecord::Base.include(ActiveStorage::Attached::Model)

    if ActiveRecord::VERSION::MINOR == 0
      module Rails
        def self.autoloaders
          Object.new.tap{|o| def o.zeitwerk_enabled?; false; end}
        end
      end
    end
  else
    ActiveRecord::Base.extend(ActiveStorage::Attached::Macros)
  end
  $: << "#{Gem.loaded_specs["activestorage"].full_gem_path}/app/models/"
  Dir.glob("#{Gem.loaded_specs["activestorage"].full_gem_path}/app/models/active_storage/*").each{|f| require f}
  Dir.glob("#{Gem.loaded_specs["activestorage"].full_gem_path}/app/jobs/active_storage/*").each{|f| require f}
  ActiveStorage::Blob.service = ActiveStorage::Service::DiskService.new(root: "test/tmp")
end

# Silence deprecation halfway through the test
I18n.enforce_available_locales = true

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.verbose = false

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def setup_db
  ActiveRecord::Schema.define(version: 1) do # rubocop:disable Metrics/BlockLength
    create_table :paranoid_times do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_belongs_dependant_id
      t.integer   :not_paranoid_id

      timestamps t
    end

    create_table :paranoid_booleans do |t|
      t.string    :name
      t.boolean   :is_deleted
      t.integer   :paranoid_time_id
      t.integer   :paranoid_with_counter_caches_count
      t.integer   :custom_counter_cache
      timestamps t
    end

    create_table :paranoid_strings do |t|
      t.string    :name
      t.string    :deleted
    end

    create_table :not_paranoids do |t|
      t.string    :name
      t.integer   :paranoid_time_id

      timestamps t
    end

    create_table :has_one_not_paranoids do |t|
      t.string    :name
      t.integer   :paranoid_time_id

      timestamps t
    end

    create_table :paranoid_has_many_dependants do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_time_id
      t.string    :paranoid_time_polymorphic_with_deleted_type
      t.integer   :paranoid_belongs_dependant_id

      timestamps t
    end

    create_table :paranoid_belongs_dependants do |t|
      t.string    :name
      t.datetime  :deleted_at

      timestamps t
    end

    create_table :paranoid_has_one_dependants do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_boolean_id

      timestamps t
    end

    create_table :paranoid_with_callbacks do |t|
      t.string    :name
      t.datetime  :deleted_at

      timestamps t
    end

    create_table :paranoid_destroy_companies do |t|
      t.string :name
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_delete_companies do |t|
      t.string :name
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_products do |t|
      t.integer :paranoid_destroy_company_id
      t.integer :paranoid_delete_company_id
      t.string :name
      t.datetime :deleted_at

      timestamps t
    end

    create_table :super_paranoids do |t|
      t.string :type
      t.references :has_many_inherited_super_paranoidz,
                   index: { name: "index__sp_id_on_has_many_isp" }
      t.datetime :deleted_at

      timestamps t
    end

    create_table :has_many_inherited_super_paranoidzs do |t|
      t.references :super_paranoidz, index: { name: "index_has_many_isp_on_sp_id" }
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_many_many_parent_lefts do |t|
      t.string :name
      timestamps t
    end

    create_table :paranoid_many_many_parent_rights do |t|
      t.string :name
      timestamps t
    end

    create_table :paranoid_many_many_children do |t|
      t.integer :paranoid_many_many_parent_left_id
      t.integer :paranoid_many_many_parent_right_id
      t.datetime :deleted_at
      timestamps t
    end

    create_table :paranoid_with_scoped_validations do |t|
      t.string :name
      t.string :category
      t.datetime :deleted_at
      timestamps t
    end

    create_table :paranoid_forests do |t|
      t.string   :name
      t.boolean  :rainforest
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_trees do |t|
      t.integer  :paranoid_forest_id
      t.string   :name
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_polygons do |t|
      t.integer :sides
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_androids do |t|
      t.datetime :deleted_at
    end

    create_table :paranoid_sections do |t|
      t.integer   :paranoid_time_id
      t.integer   :paranoid_thing_id
      t.string    :paranoid_thing_type
      t.datetime :deleted_at
    end

    create_table :paranoid_boolean_not_nullables do |t|
      t.string :name
      t.boolean :deleted, :boolean, null: false, default: false
    end

    create_table :paranoid_belongs_to_polymorphics do |t|
      t.string :name
      t.string :parent_type
      t.integer :parent_id
      t.datetime :deleted_at

      timestamps t
    end

    create_table :not_paranoid_has_many_as_parents do |t|
      t.string :name

      timestamps t
    end

    create_table :paranoid_has_many_as_parents do |t|
      t.string :name
      t.datetime :deleted_at

      timestamps t
    end

    create_table :paranoid_no_double_tap_destroys_fullies do |t|
      t.datetime :deleted_at
    end

    create_table :paranoid_with_counter_caches do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_boolean_id

      timestamps t
    end

    if ENABLE_ACTIVE_STORAGE
      create_table :active_storage_attachments do |t|
        t.string :name, null: false
        t.string :record_type, null: false
        t.bigint :record_id, null: false
        t.bigint :blob_id, null: false
        t.datetime :created_at, null: false
        t.index [:blob_id], name: "index_active_storage_attachments_on_blob_id"
        t.index [:record_type, :record_id, :name, :blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
      end

      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.bigint :byte_size, null: false
        t.string :checksum, null: false
        t.datetime :created_at, null: false
        t.index [:key], name: "index_active_storage_blobs_on_key", unique: true
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength

def timestamps(table)
  table.column  :created_at, :timestamp, null: false
  table.column  :updated_at, :timestamp, null: false
end

def teardown_db
  ActiveRecord::Base.connection.data_sources.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

def clean_active_storage_attachments
  Dir.glob("test/tmp/*").each{|f| FileUtils.rm_r(f)}
end

class ParanoidTime < ActiveRecord::Base
  acts_as_paranoid

  validates_uniqueness_of :name

  has_many :paranoid_has_many_dependants, dependent: :destroy
  has_many :paranoid_booleans, dependent: :destroy
  has_many :not_paranoids, dependent: :delete_all
  has_many :paranoid_sections, dependent: :destroy

  has_one :has_one_not_paranoid, dependent: :destroy

  belongs_to :not_paranoid, dependent: :destroy

  if ENABLE_ACTIVE_STORAGE
    has_one_attached :main_file
    has_many_attached :files
    has_one_attached :undependent_main_file, dependent: false
    has_many_attached :undependent_files, dependent: false
  end
end

class ParanoidBoolean < ActiveRecord::Base
  acts_as_paranoid column_type: "boolean", column: "is_deleted"
  validates_as_paranoid
  validates_uniqueness_of_without_deleted :name

  belongs_to :paranoid_time
  has_one :paranoid_has_one_dependant, dependent: :destroy
  has_many :paranoid_with_counter_cache, dependent: :destroy
  has_many :paranoid_with_custom_counter_cache, dependent: :destroy
end

class ParanoidString < ActiveRecord::Base
  acts_as_paranoid column_type: "string", column: "deleted", deleted_value: "dead"
end

class NotParanoid < ActiveRecord::Base
end

class ParanoidNoDoubleTapDestroysFully < ActiveRecord::Base
  acts_as_paranoid double_tap_destroys_fully: false
end

class HasOneNotParanoid < ActiveRecord::Base
  belongs_to :paranoid_time, with_deleted: true
end

class DoubleHasOneNotParanoid < HasOneNotParanoid
  belongs_to :paranoid_time, with_deleted: true
  begin
    verbose = $VERBOSE
    $VERBOSE = false
    belongs_to :paranoid_time, with_deleted: true
  ensure
    $VERBOSE = verbose
  end
end

class ParanoidWithCounterCache < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_boolean, counter_cache: true
end

class ParanoidWithCustomCounterCache < ActiveRecord::Base
  self.table_name = "paranoid_with_counter_caches"

  acts_as_paranoid
  belongs_to :paranoid_boolean, counter_cache: :custom_counter_cache
end

class ParanoidWithCounterCacheOnOptionalBelognsTo < ActiveRecord::Base
  self.table_name = "paranoid_with_counter_caches"

  acts_as_paranoid
  if ActiveRecord::VERSION::MAJOR < 5
    belongs_to :paranoid_boolean, counter_cache: true, required: false
  else
    belongs_to :paranoid_boolean, counter_cache: true, optional: true
  end
end

class ParanoidHasManyDependant < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_time
  belongs_to :paranoid_time_with_scope,
             -> { where(name: "hello").includes(:not_paranoid) },
             class_name: "ParanoidTime", foreign_key: :paranoid_time_id
  belongs_to :paranoid_time_with_deleted, class_name: "ParanoidTime",
                                          foreign_key: :paranoid_time_id, with_deleted: true
  belongs_to :paranoid_time_with_scope_with_deleted,
             -> { where(name: "hello").includes(:not_paranoid) },
             class_name: "ParanoidTime", foreign_key: :paranoid_time_id, with_deleted: true
  belongs_to :paranoid_time_polymorphic_with_deleted, class_name: "ParanoidTime",
                                                      foreign_key: :paranoid_time_id,
                                                      polymorphic: true, with_deleted: true

  belongs_to :paranoid_belongs_dependant, dependent: :destroy
end

class ParanoidBelongsDependant < ActiveRecord::Base
  acts_as_paranoid

  has_many :paranoid_has_many_dependants
end

class ParanoidHasOneDependant < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :paranoid_boolean
end

class ParanoidWithCallback < ActiveRecord::Base
  acts_as_paranoid

  attr_accessor :called_before_destroy, :called_after_destroy,
                :called_after_commit_on_destroy, :called_before_recover,
                :called_after_recover

  before_destroy :call_me_before_destroy
  after_destroy :call_me_after_destroy

  after_commit :call_me_after_commit_on_destroy, on: :destroy

  before_recover :call_me_before_recover
  after_recover :call_me_after_recover

  set_callback :initialize, lambda { @called_before_destroy = @called_after_destroy = @called_after_commit_on_destroy = @called_before_recover = @called_after_recover = 0 }

  def call_me_before_destroy
    @called_before_destroy += 1
  end

  def call_me_after_destroy
    @called_after_destroy += 1
  end

  def call_me_after_commit_on_destroy
    @called_after_commit_on_destroy += 1
  end

  def call_me_before_recover
    @called_before_recover += 1
  end

  def call_me_after_recover
    @called_after_recover += 1
  end
end

class ParanoidDestroyCompany < ActiveRecord::Base
  acts_as_paranoid
  validates :name, presence: true
  has_many :paranoid_products, dependent: :destroy
end

class ParanoidDeleteCompany < ActiveRecord::Base
  acts_as_paranoid
  validates :name, presence: true
  has_many :paranoid_products, dependent: :delete_all
end

class ParanoidProduct < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_destroy_company
  belongs_to :paranoid_delete_company
  validates_presence_of :name
end

class SuperParanoid < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :has_many_inherited_super_paranoidz
end

class HasManyInheritedSuperParanoidz < ActiveRecord::Base
  has_many :super_paranoidz, class_name: "InheritedParanoid", dependent: :destroy
end

class InheritedParanoid < SuperParanoid
  acts_as_paranoid
end

class ParanoidManyManyParentLeft < ActiveRecord::Base
  has_many :paranoid_many_many_children
  has_many :paranoid_many_many_parent_rights, through: :paranoid_many_many_children
end

class ParanoidManyManyParentRight < ActiveRecord::Base
  has_many :paranoid_many_many_children
  has_many :paranoid_many_many_parent_lefts, through: :paranoid_many_many_children
end

class ParanoidManyManyChild < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_many_many_parent_left
  belongs_to :paranoid_many_many_parent_right
end

class ParanoidWithScopedValidation < ActiveRecord::Base
  acts_as_paranoid
  validates_uniqueness_of :name, scope: :category
end

class ParanoidBelongsToPolymorphic < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :parent, polymorphic: true, with_deleted: true
end

class NotParanoidHasManyAsParent < ActiveRecord::Base
  has_many :paranoid_belongs_to_polymorphics, as: :parent, dependent: :destroy
end

class ParanoidHasManyAsParent < ActiveRecord::Base
  acts_as_paranoid
  has_many :paranoid_belongs_to_polymorphics, as: :parent, dependent: :destroy
end

class ParanoidBaseTest < ActiveSupport::TestCase
  if ENABLE_ACTIVE_STORAGE
    self.file_fixture_path = 'test/fixtures'
  end

  def setup
    setup_db

    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      ParanoidTime.create! name: name
      ParanoidBoolean.create! name: name
    end

    ParanoidString.create! name: "strings can be paranoid"
    NotParanoid.create! name: "no paranoid goals"
    ParanoidWithCallback.create! name: "paranoid with callbacks"
  end

  def teardown
    teardown_db
    clean_active_storage_attachments
  end

  def assert_empty(collection)
    assert(collection.respond_to?(:empty?) && collection.empty?)
  end

  def assert_paranoid_deletion(model)
    row = find_row(model)
    assert_not_nil row, "#{model.class} entirely deleted"
    assert_not_nil row["deleted_at"], "Deleted at not set"
  end

  def assert_non_paranoid_deletion(model)
    row = find_row(model)
    assert_nil row, "#{model.class} still exists"
  end

  def find_row(model)
    sql = "select deleted_at from #{model.class.table_name} where id = #{model.id}"
    # puts sql here if you want to debug
    model.class.connection.select_one(sql)
  end
end

class ParanoidForest < ActiveRecord::Base
  acts_as_paranoid

  ActiveRecord::Base.logger = Logger.new(StringIO.new)

  scope :rainforest, -> { where(rainforest: true) }

  has_many :paranoid_trees, dependent: :destroy
end

class ParanoidTree < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_forest
  validates_presence_of :name
end

class ParanoidPolygon < ActiveRecord::Base
  acts_as_paranoid
  default_scope { where("sides = ?", 3) }
end

class ParanoidAndroid < ActiveRecord::Base
  acts_as_paranoid
end

class ParanoidSection < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_time
  belongs_to :paranoid_thing, polymorphic: true, dependent: :destroy
end

class ParanoidBooleanNotNullable < ActiveRecord::Base
  acts_as_paranoid column: "deleted", column_type: "boolean", allow_nulls: false
end

class ParanoidWithExplicitTableNameAfterMacro < ActiveRecord::Base
  acts_as_paranoid
  self.table_name = "explicit_table"
end
