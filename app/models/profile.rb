class Profile < ActiveRecord::Base
  belongs_to :user
  attr_protected :is_active
  
  validates_format_of :email, :with => /^([^@\s]{1}+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message=>'does not look like an email address.'
  validates_length_of :email, :within => 3..100
  validates_uniqueness_of :email, :case_sensitive => false
  
  # Feeds
  has_many :feeds
  has_many :feed_items, :through => :feeds, :order => 'created_at desc'
  has_many :private_feed_items, :through => :feeds, :source => :feed_item, :conditions => {:is_public => false}, :order => 'created_at desc'
  has_many :public_feed_items, :through => :feeds, :source => :feed_item, :conditions => {:is_public => true}, :order => 'created_at desc'
  
  # Messages
  has_many :sent_messages,     :class_name => 'Message', :order => 'created_at desc', :foreign_key => 'sender_id'
  has_many :received_messages, :class_name => 'Message', :order => 'created_at desc', :foreign_key => 'receiver_id'
  has_many :unread_messages,   :class_name => 'Message', :conditions => {:read => false}, :foreign_key => 'receiver_id'

  # Friends
  has_many :friendships, :class_name  => "Friend", :foreign_key => 'inviter_id', :conditions => "status = #{Friend::ACCEPTED}"
  has_many :follower_friends, :class_name => "Friend", :foreign_key => "invited_id", :conditions => "status = #{Friend::PENDING}"
  has_many :following_friends, :class_name => "Friend", :foreign_key => "inviter_id", :conditions => "status = #{Friend::PENDING}"
  
  has_many :friends,   :through => :friendships, :source => :invited
  has_many :followers, :through => :follower_friends, :source => :inviter
  has_many :followings, :through => :following_friends, :source => :invited
  
  
  # Comments and Blogs
  has_many :comments, :as => :commentable, :order => 'created_at desc'
  has_many :blogs, :order => 'created_at desc'
  
  
  # Photos
  has_many :photos, :order => 'created_at DESC'
  
  #Forums
  has_many :forum_posts, :foreign_key => 'owner_id', :dependent => :destroy
  
  has_attached_file :icon,
    :styles => {
      :big => "150x150#",
      :medium => "100x100#",
      :small => "50x50#"
    },
    :default_url => "/avatar_default_:style.png",
    :path => ":rails_root/public/system/:attachment/:id/:style/:basename.:extension"
  
  cattr_accessor :featured_profile
  @@featured_profile = {:date=>Date.today-4, :profile=>nil}
  Profile::NOWHERE = 'Nowhere'

  def to_param
    "#{self.id}-#{f.to_safe_uri}"
  end
  
  
  def has_network?
    !Friend.find(:first, :conditions => ["invited_id = ? or inviter_id = ?", id, id]).blank?
  end
    
  def f
    if self.first_name.blank? && self.last_name.blank?
      user.login rescue 'Deleted user'
    else
       ((self.first_name || '') + ' ' + (self.last_name || '')).strip
     end
  end
  
  def location
    return Profile::NOWHERE if attributes['location'].blank?
    attributes['location']
  end
  
  def full_name
    f
  end
  
  def self.featured
    find_options = {
      :include => :user,
      :conditions => ["is_active = ? and about_me IS NOT NULL and user_id is not null", true],
    }
    find(:first, find_options.merge(:offset => rand(count(find_options)).floor)) 
  end  
  
  def no_data?
    (created_at <=> updated_at) == 0
  end

  
  def has_wall_with profile
    return false if profile.blank?
    !Comment.between_profiles(self, profile).empty?
  end
  
  def website= val
    write_attribute(:website, fix_http(val))
  end

  def blog= val
    write_attribute(:blog, fix_http(val))
  end

  def twitter= val
    write_attribute(:twitter, fix_http(val))
  end

  def facebook= val
    write_attribute(:facebook, fix_http(val))
  end

  def gtalk_name= val
    write_attribute(:gtalk_name, val)
  end

  def youtube_username= val
    write_attribute(:youtube_username, val)
  end
  
  # Friend Methods
  def friend_of? user
    user.in? friends
  end
  
  def followed_by? user
    user.in? followers
  end
  
  def following? user
    user.in? followings
  end
    
  def can_send_messages
    user.can_send_messages
  end

  
  protected
  def fix_http str
    return '' if str.blank?
    str.starts_with?('http') ? str : "http://#{str}"
  end
  
end
