json.array!(@books) do |book|
  json.extract! book, :id, :name, :isbn, :rate, :quantity
  json.url book_url(book, format: :json)
end
