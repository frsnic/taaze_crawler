class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]

  # GET /books
  # GET /books.json
  def index
    default_q = {
      name_not_cont_all: (1..9).to_a.map { |i| ["(#{i})", "（#{i}）", "(0#{i})", "（0#{i}）"] }.flatten,
      press_not_cont_all: %w(東立 九星文化出版社 台灣角川股份有限公司 旺福圖書 N/A 銘顯文化事業有限公司 上海譯文出版社 明日工作室股份有限公司 橘子 十田十 青文出版社股份有限公司 尖端出版 龍吟ROSE 台灣東販股份有限公司 桔子),
      rate_gt: 4.5
    }
    @q = Book.enabled.ransack(params[:q])
    @books = params[:q] ? @q.result(distinct: true).page(params[:page]) :
      Book.enabled.ransack(default_q).result.page(params[:page]).order(publish_at: :desc)
  end

  # GET /books/1
  # GET /books/1.json
  def show
  end

  # GET /books/new
  def new
    @book = Book.new
  end

  # GET /books/1/edit
  def edit
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    respond_to do |format|
      if @book.update(book_params)
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: 'Book was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def taaze
    taaze_crawler = Crawler::Taaze.new
    results = taaze_crawler.generate_title_hash
    Book.enabled.where.not(name: results).update_all(is_disabled: true)
    Book.correction
    render text: 'success'
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_book
    @book = Book.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def book_params
    params.require(:book).permit(:name, :isbn, :rate, :quantity)
  end

end
