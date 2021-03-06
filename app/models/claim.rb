class Claim < ActiveRecord::Base

  attr_accessible :description, :hunter_id, :perpetrator_id, :evidence_links_attributes

  belongs_to :hunter, class_name: 'User'
  belongs_to :perpetrator

  has_many :evidence_links, as: :evident, dependent: :destroy
  accepts_nested_attributes_for :evidence_links, :reject_if => lambda { |a| a[:link_text].blank? }, :allow_destroy => true
  validates_associated :evidence_links

  validates :description, presence: true

  scope :recent, order('created_at DESC')
  scope :for_author, lambda{|user_id| where(hunter_id: user_id)}
  scope :for_perp, lambda{|perp_id| where(perpetrator_id: perp_id)}
  scope :unexpired, where("claims.created_at > NOW() - INTERVAL '5 DAY' ")
  scope :expired, where("claims.created_at < NOW() - INTERVAL '5 DAY' ")

  def to_s
    hunter.try :username
  end

end
