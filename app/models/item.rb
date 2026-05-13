class Item < ApplicationRecord
  scope :available, -> { includes(:circulation_status).where.not("circulation_statuses.name" => "Removed") }
  scope :removed, -> { includes(:circulation_status).where("circulation_statuses.name" => "Removed") }
  scope :on_shelf, -> { available.includes(:shelf).references(:shelf).where.not(shelves: { name: "web" }) }
  scope :on_web, -> { available.includes(:shelf).references(:shelf).where(name: "web") }
  scope :available_for, ->(user) {
    unless user.try(:has_role?, "Librarian")
      on_shelf
    end
  }

  include EnjuLibrary::EnjuItem
  include EnjuCirculation::EnjuItem
  include EnjuInventory::EnjuItem

  delegate :display_name, to: :shelf, prefix: true
  has_many :owns, dependent: :destroy
  has_many :agents, through: :owns
  has_many :donates, dependent: :destroy
  has_many :donors, through: :donates, source: :agent
  has_one :resource_import_result
  belongs_to :manifestation, touch: true
  belongs_to :bookstore, optional: true
  belongs_to :required_role, class_name: "Role"
  belongs_to :budget_type, optional: true
  has_one :accept, dependent: :destroy
  has_one :withdraw, dependent: :destroy
  has_many :item_custom_values, -> { joins(:item_custom_property).order(:position) }, inverse_of: :item, dependent: :destroy

  belongs_to :shelf, counter_cache: true
  accepts_nested_attributes_for :item_custom_values, reject_if: :all_blank

  scope :accepted_between, lambda { |from, to| includes(:accept).where("items.created_at BETWEEN ? AND ?", Time.zone.parse(from).beginning_of_day, Time.zone.parse(to).end_of_day) }

  # StudyLib item identifier:
  #   Ayyyy-mmdd-nnnc
  #   yyyy: year
  #   mmdd: month and day
  #   nnn : serial number
  #   c   : UPC-A / JAN-style check digit
  #
  # Accepted inputs:
  #   Ayyyy-mmdd-nnnc
  #   Ayyyy-mmdd-nnn
  #   yyyy-mmdd-nnn
  #   yyyymmddnnn
  #
  # Values are normalized before validation and saved as:
  #   Ayyyy-mmdd-nnnc
  #
  # If the date part is invalid, the value is not normalized and validation fails.
  # If the check digit is missing or wrong, it is calculated and corrected.
  STUDYLIB_ITEM_IDENTIFIER_FORMAT = /\AA\d{4}-\d{4}-\d{4}\z/

  validates :item_identifier, allow_blank: true, uniqueness: true,
    format: { with: STUDYLIB_ITEM_IDENTIFIER_FORMAT }
  validates :binding_item_identifier, allow_blank: true,
    format: { with: STUDYLIB_ITEM_IDENTIFIER_FORMAT }

  validate :validate_studylib_item_identifier_values

  validates :url, url: true, allow_blank: true, length: { maximum: 255 }
  validates :acquired_at, date: true, allow_blank: true

  strip_attributes only: [ :item_identifier, :binding_item_identifier,
    :call_number, :binding_call_number, :url ]

  before_validation :normalize_studylib_item_identifiers

  searchable do
    text :item_identifier, :note, :title, :creator, :contributor, :publisher,
      :binding_item_identifier
    string :item_identifier, multiple: true do
      [ item_identifier, binding_item_identifier ]
    end
    integer :required_role_id
    integer :manifestation_id
    integer :shelf_id
    integer :agent_ids, multiple: true
    time :created_at
    time :updated_at
    time :acquired_at
  end

  after_save do
    manifestation.index
    Sunspot.commit
  end
  after_destroy do
    manifestation.index
    Sunspot.commit
  end

  attr_accessor :library_id

  paginates_per 10

  def title
    manifestation&.original_title
  end

  def creator
    manifestation&.creator
  end

  def contributor
    manifestation&.contributor
  end

  def publisher
    manifestation&.publisher
  end

  def owned(agent)
    owns.find_by(agent_id: agent.id)
  end

  def manifestation_url
    Addressable::URI.parse("#{LibraryGroup.site_config.url}manifestations/#{manifestation.id}").normalize.to_s if manifestation
  end

  def removable?
    if defined?(EnjuCirculation)
      return false if circulation_status.name == "Removed"
      return false if checkouts.exists?

      true
    else
      true
    end
  end

  def self.csv_header(role: "Guest")
    Item.new.to_hash(role: role).keys
  end

  def to_hash(role: "Guest")
    record = {
      item_id: id,
      item_identifier: item_identifier,
      binding_item_identifier: binding_item_identifier,
      call_number: call_number,
      library: shelf&.library&.name,
      shelf: shelf&.name,
      item_note: note,
      accepted_at: accept&.created_at,
      acquired_at: acquired_at,
      item_created_at: created_at,
      item_updated_at: updated_at
    }

    if [ "Administrator", "Librarian" ].include?(role)
      record.merge!({
        bookstore: bookstore&.name,
        budget_type: budget_type&.name,
        item_required_role: required_role.name,
        item_price: price,
        memo: memo
      })

      ItemCustomProperty.order(:position).each do |custom_property|
        custom_value = item_custom_values.find_by(item_custom_property: custom_property)
        record[:"item:#{custom_property.name}"] = custom_value.try(:value)
      end

      if defined?(EnjuCirculation)
        record.merge!({
          use_restriction: use_restriction&.name,
          circulation_status: circulation_status&.name,
          checkout_type: checkout_type&.name,
          total_checkouts: checkouts.count
        })
      end
    end

    record
  end

  private

  def normalize_studylib_item_identifiers
    self.item_identifier = normalize_studylib_item_identifier(item_identifier)
    self.binding_item_identifier = normalize_studylib_item_identifier(binding_item_identifier)
  end

  def normalize_studylib_item_identifier(value)
    return value if value.blank?

    raw = value.to_s.strip.upcase
    digits = raw.delete_prefix("A").delete("-")

    return raw unless digits.match?(/\A\d{11,12}\z/)

    base_digits = digits[0, 11]

    return raw unless studylib_item_identifier_date_valid?(base_digits)

    check_digit = studylib_check_digit(base_digits)

    "A#{base_digits[0, 4]}-#{base_digits[4, 4]}-#{base_digits[8, 3]}#{check_digit}"
  end

  def validate_studylib_item_identifier_values
    validate_studylib_item_identifier_value(:item_identifier)
    validate_studylib_item_identifier_value(:binding_item_identifier)
  end

  def validate_studylib_item_identifier_value(attribute)
    value = public_send(attribute)
    return if value.blank?

    return unless value.match?(STUDYLIB_ITEM_IDENTIFIER_FORMAT)

    digits = value.delete_prefix("A").delete("-")
    base_digits = digits[0, 11]

    unless studylib_item_identifier_date_valid?(base_digits)
      errors.add(attribute, :invalid)
    end
  end

  def studylib_item_identifier_date_valid?(base_digits)
    year = base_digits[0, 4].to_i
    month = base_digits[4, 2].to_i
    day = base_digits[6, 2].to_i

    Date.valid_date?(year, month, day)
  end

  def studylib_check_digit(base_digits)
    digits = base_digits.chars.map(&:to_i)

    odd_sum = digits.values_at(0, 2, 4, 6, 8, 10).sum
    even_sum = digits.values_at(1, 3, 5, 7, 9).sum

    ((10 - ((odd_sum * 3 + even_sum) % 10)) % 10).to_s
  end
end

# ## Schema Information
#
# Table name: `items`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `bigint`           | `not null, primary key`
# **`acquired_at`**              | `datetime`         |
# **`binded_at`**                | `datetime`         |
# **`binding_call_number`**      | `string`           |
# **`binding_item_identifier`**  | `string`           |
# **`call_number`**              | `string`           |
# **`include_supplements`**      | `boolean`          | `default(FALSE), not null`
# **`item_identifier`**          | `string`           |
# **`lock_version`**             | `integer`          | `default(0), not null`
# **`memo`**                     | `text`             |
# **`missing_since`**            | `date`             |
# **`note`**                     | `text`             |
# **`price`**                    | `integer`          |
# **`url`**                      | `string`           |
# **`created_at`**               | `datetime`         | `not null`
# **`updated_at`**               | `datetime`         | `not null`
# **`bookstore_id`**             | `bigint`           |
# **`budget_type_id`**           | `bigint`           |
# **`checkout_type_id`**         | `bigint`           | `default(1), not null`
# **`circulation_status_id`**    | `bigint`           | `default(5), not null`
# **`manifestation_id`**         | `bigint`           | `not null`
# **`required_role_id`**         | `bigint`           | `default(1), not null`
# **`shelf_id`**                 | `bigint`           | `default(1), not null`
#
# ### Indexes
#
# * `index_items_on_binding_item_identifier`:
#     * **`binding_item_identifier`**
# * `index_items_on_bookstore_id`:
#     * **`bookstore_id`**
# * `index_items_on_checkout_type_id`:
#     * **`checkout_type_id`**
# * `index_items_on_circulation_status_id`:
#     * **`circulation_status_id`**
# * `index_items_on_item_identifier` (_unique_ _where_ (((item_identifier)::text <> ''::text) AND (item_identifier IS NOT NULL))):
#     * **`item_identifier`**
# * `index_items_on_manifestation_id`:
#     * **`manifestation_id`**
# * `index_items_on_required_role_id`:
#     * **`required_role_id`**
# * `index_items_on_shelf_id`:
#     * **`shelf_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`bookstore_id => bookstores.id`**
# * `fk_rails_...`:
#     * **`budget_type_id => budget_types.id`**
# * `fk_rails_...`:
#     * **`checkout_type_id => checkout_types.id`**
# * `fk_rails_...`:
#     * **`circulation_status_id => circulation_statuses.id`**
# * `fk_rails_...`:
#     * **`manifestation_id => manifestations.id`**
# * `fk_rails_...`:
#     * **`required_role_id => roles.id`**
# * `fk_rails_...`:
#     * **`shelf_id => shelves.id`**
#
