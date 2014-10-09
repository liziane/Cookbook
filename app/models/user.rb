class User
  include Mongoid::Document
  field :email,                 type: String, default: ""
  index({ email: 1 })
  field :provider,              type: String
  field :oauth_token,           type: String
  field :oauth_expires_at,      type: Time
  field :uid,                   type: String
  index({ provider: 1, uid: 1})
  field :name,                  type: String
  index({ name: 1 })

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.email = auth.info.email
    end
  end
end
