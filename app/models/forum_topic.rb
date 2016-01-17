class ForumTopic < ActiveRecord::Base
  validates_presence_of :title, :owner_id, :forum_id
  belongs_to :owner, :class_name => "Profile"
  belongs_to :forum
  
  has_many :posts, :class_name => "ForumPost", :foreign_key => "topic_id", :dependent => :destroy
  
  def to_param
    "#{self.id}-#{title.to_safe_uri}"
  end
  
  def after_create
    feed_item = FeedItem.create(:item => self)
  end
  
  def users
    posts.collect{|p| p.owner.user}.uniq
  end
  
end