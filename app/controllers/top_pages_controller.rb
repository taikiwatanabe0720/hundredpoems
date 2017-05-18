class TopPagesController < ApplicationController
  def home
    # 百人一首を全件取得する
    # View に表示するため @ を付けた変数名にする
    @destinations = Destination.all.page(params[:page]).per(15)
  end
  
  def app
  end
  
  def hundred
  end
  
end
