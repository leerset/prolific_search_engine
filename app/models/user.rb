class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :concepts
  has_one :auth

  has_many :user_addresses
  has_many :addresses, through: :user_addresses
  has_many :user_citizenships
  has_many :citizenships, through: :user_citizenships
  has_many :user_languages
  has_many :languages, through: :user_languages
  has_many :user_roles
  has_many :roles, through: :user_roles
  has_many :user_inventions
  has_many :inventions, through: :user_inventions
  has_many :user_organizations
  has_many :organizations, through: :user_organizations

  before_create :generate_access_token
  after_create :create_auth

  has_attached_file :resume,
    path: ':rails_root/public/user/:id/resume/:filename',
    url: '/user/:id/resume/:filename'
  validates_attachment_content_type :resume,
    :content_type => [ 'image/png', 'image/jpeg',
      'application/zip',
      'application/xlsx', 'audio/mpeg', 'audio/mp3' ]

  def full_name
    screen_name || [firstname, lastname].join(' ')
  end

  def god?
    self.roles.find_by(code: 'god').present?
  end

  def oa?(organization)
    organization_roles(organization).find_by(code: 'organization_administrator').present?
  end

  def inventor?(invention)
    invention_roles(invention).find_by(code: 'inventor').present?
  end

  def organization_roles(organization)
    self.user_organizations.where(organization: organization).map(&:role)
  end

  def invention_roles(invention)
    self.user_inventions.where(invention: invention).map(&:role)
  end

  def update_resume(resume_file)
    # resume_file[:filename]
    # resume_file[:type]
    # resume_file[:tempfile]
    # binding.pry
    self.resume = resume_file[:tempfile]
    self.resume.save
    self.resume_filepath = self.resume.url
    self.save!
  end

  def create_auth
    self.build_auth(secure_random: Auth.generate_secure_random).save!
  end

  def expired?
    DateTime.now >= self.expires_at
  end

  def set_expiration
    self.expires_at = DateTime.now + 1    # 1 day
  end

  def authenticate?(password)
    self.password == password
  end

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists_access_token?(access_token)
    self.set_expiration
    self.access_token
  end

  def update_access_token
    self.generate_access_token
    self.save
  end

  private

  def self.exists_access_token?(access_token)
    User.where(access_token: access_token).present?
  end
end
