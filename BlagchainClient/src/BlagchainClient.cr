###################################################
#@Author: Blag
#@Name: BlagchainClient.cr
#@Location: d-shop Toronto
###################################################

require "kemal"
require "http/client"
require "kemal-session"
require "kemal-flash"

Kemal::Session.config.cookie_name = "session_id"
Kemal::Session.config.secret = "some_secret"
Kemal::Session.config.gc_interval = 2.minutes

class BlagchainUser
  JSON.mapping(
      user: String,
      amount: Float64
      )
end

class Transactions
  JSON.mapping({ 
      article: String,
      description: String,
      from: String,
      to: String,
      amount: Float64  
  })
end

class BlagchainTransactions
  JSON.mapping({
      index: Int32,
      prev_hash: String,
      hash: String,
      proof: String,
      transactions: Array(Transactions)
      })
end

class Products
  JSON.mapping({
      index: Int32,
      article: String,
      description: String,
      from: String,
      to: String,
      amount: Float64    
  })
end

def get_user
  response = HTTP::Client.get "http://localhost:3000"
  response.body.lines
end

def get_transactions
  response = HTTP::Client.get "http://localhost:3000/transactions"
  response.body.lines
end

def get_products
  response = HTTP::Client.get "http://localhost:3000/products"
  response.body.lines
end

get "/" do |env|
  value = get_user()
  blagchainUser = BlagchainUser.from_json(value[0])
  env.session.string("user", blagchainUser.user)
  env.session.float("amount", blagchainUser.amount)
  env.session.bool("flag", false)
  env.redirect "/Blagchain"
end

get "/Blagchain" do |env|
  blagchainUser_user = env.session.string("user")
  blagchainUser_amount = env.session.float("amount")
  transactions = get_transactions()
  products = get_products()
  notice = env.flash["notice"]?
  blagchainTransactions = Array(BlagchainTransactions).from_json(transactions[0])
  if blagchainTransactions.size > 0 && env.session.bool("flag") == true 
    blagCoins = blagchainTransactions[blagchainTransactions.size - 1]
    if blagCoins.transactions[0].to == env.session.string("user")
      amount = env.session.float("amount") + blagCoins.transactions[0].amount
      env.session.float("amount", amount)
      env.session.bool("flag", false)
    end
  end
  blagchainProducts = Array(Products).from_json(products[0])
  render "views/index.ecr"
end

post "/sellArticle" do |env|
  user = env.params.body["user"]
  article = env.params.body["article"]
  description = env.params.body["description"]
  price = env.params.body["price"]
  amount = (env.session.float("amount") - 0.1).round(2)
  env.session.float("amount", amount)
  HTTP::Client.post("http://localhost:3000/addTransaction", form: "user=" + user + 
                    "&article=" + article + "&description=" + description + "&price=" + price)
  env.session.bool("flag", true)
  env.redirect "/Blagchain"
end

post "/buyArticle" do |env|
  index = env.params.body["index"]
  price = env.params.body["hiddenprice"].to_f(64)
  article = env.params.body["hiddenarticle"]
  description = env.params.body["hiddendescription"]
  from = env.params.body["hiddenfrom"]
  to = env.params.body["hiddento"]
  amount = (env.session.float("amount") - price - 0.1).round(2)
  if amount > 0
    env.session.float("amount", amount)
    HTTP::Client.post("http://localhost:3000/sellProduct", form: "index=" + index +
                      "&article=" + article + "&description=" + description + 
                      "&from=" + from + "&to=" + to + "&price=" + price.to_s)
  else
    env.flash["notice"] = "You don't have enough Blagcoin for this transaction!"
  end
  env.redirect "/Blagchain"  
end

Kemal.config.port = 3001
Kemal.run
