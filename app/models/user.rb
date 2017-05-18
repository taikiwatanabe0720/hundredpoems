class User < ActiveRecord::Base
    
#各変数のルール
    validates :name, presence: true, length: {maximum: 20}
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
    validates :address, presence: true

#新規登録時のパスワード確認
    has_secure_password
    

# Stationモデルとの関連付け
    has_one :station
end
