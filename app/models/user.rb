class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me

  # references_and_referenced_in_many :messageboards
  # references_and_referenced_in_many :roles
  # references_and_referenced_in_many :topics
  
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false

  def superadmin?
    self.superadmin
  end

  def admins?(messageboard)
    superadmin? || roles.for(messageboard).as([:admin]).size > 0
  end

  def moderates?(messageboard)
    superadmin? || roles.for(messageboard).as([:admin, :moderator]).size > 0
  end

  def member_of?(messageboard)
    superadmin? || roles.for(messageboard).as([:admin, :moderator, :member]).size > 0
  end
  
  def member_of(messageboard, as=:member)
    roles << Role.create(:level => as, :messageboard => messageboard) and save
  end

  def admin_of(messageboard, as=:member)
    member_of(messageboard, :admin)
  end

  def logged_in?
    valid?
  end

end
