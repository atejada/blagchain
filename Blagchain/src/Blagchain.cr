###################################################
#@Author: Blag
#@Name: Blagchain.cr
#@Location: d-shop Toronto
###################################################

require "kemal"
require "json"
require "openssl"
require "uuid"

class Block
  @@chains = [{index: 0, prev_hash: "", hash: "0000000000000000000000000000000000000000000000000000000000000000", proof: "0000", 
               transactions: [{article: "", description: "", from: "", to: "", amount: 0.0}]}]  
  @@products = [{index: -1, article: "", description: "", from: "", to: "", amount: 0.0}] 
  @@products.delete({index: -1, article: "", description: "", from: "", to: "", amount: 0.0})
  property hash, nonce, prev, data, time, index, transactions
  
  def initialize(index : Int32, prev : String, 
                 transactions : Array({article: String, description: String, from: String, to: String, amount: Float64}))
    @transactions = [{article: "", description: "", from: "", to: "", amount: 0.0}]
    @transactions = transactions
    @index = index
    @prev = prev
    @hash = OpenSSL::Digest.new("SHA256")
    @nonce = 0
    @time = 0_i64
    @index, @nonce, @prev, @hash, @transactions = compute_hash_with_proof_of_work()
    add_block(index: @index,prev_hash: @prev.to_s,hash: @hash.to_s,proof: @nonce.to_s, 
              transactions: {article: @transactions[0][:article], 
                             description: @transactions[0][:description], 
                             from: @transactions[0][:from],
                             to: @transactions[0][:to],
                             amount: @transactions[0][:amount]})
   end

  def compute_hash_with_proof_of_work(difficulty : String = "0000")
    loop do
      @time = Time.now.epoch
      @hash.update(@index.to_s + @time.to_s + @prev)
      if @hash.hexdigest.starts_with?("0000")
        @transactions = transactions
        return {@index, @nonce, @prev, @hash, @transactions, @time}
      else
        @nonce += 1
      end  
    end
  end

  def add_block(index : Int32, prev_hash : String, hash : String, proof : String,
                transactions : {article: String, description: String, from: String, to: String, amount: Float64})
    @@chains.push({index: index, prev_hash: prev_hash, hash: hash, proof: proof, transactions: [transactions]})
  end

  def self.chains
    @@chains
  end

  def add_product(index : Int32, article : String, description : String, from : String, to : String, amount : Float64)
    @@products.push({index: index, article: article, description: description, from: from, to: to, amount: amount})
  end

  def self.products
    @@products
  end
    
end

class User
  @@c_users = [{user: "", amount: 0.0}]
  property c_user : String, c_amount : Float64
  
  def initialize()
    @c_user = UUID.random().to_s.gsub("-"){""}
    @c_amount = 100.0
    add_user(@c_user, @c_amount)
  end
  
  def add_user(c_user : String, c_amount : Float64)
    @@c_users.push({user: c_user, amount: c_amount})
  end
  
  def self.c_users
    @@c_users
  end
  
end 

get "/" do |env|
  env.response.content_type = "application/json"
  n_user = User.new
  {user: n_user.c_user, amount: n_user.c_amount}.to_json
end

get "/users" do |env|
  env.response.content_type = "application/json"
  User.c_users.delete({user: "",amount: 0.0})
  User.c_users.to_json
end

get "/transactions" do |env|
  env.response.content_type = "application/json"
  Block.chains.to_json
end

get "/products" do |env|
  env.response.content_type = "application/json"
  Block.products.to_json
end

post "/addTransaction" do |env|
  user = env.params.body["user"]
  article = env.params.body["article"]
  description = env.params.body["description"]
  price =  env.params.body["price"]
  previous = Block.chains[Block.chains.size - 1]
  block = Block.new previous[:index] + 1, previous[:hash], [{article: article, description: description, from: user, to: "", amount: price.to_f(64)}]
  index = Block.products.size + 1
  block.add_product(index: index, article: article, description: description, from: user, to: "", amount: price.to_f(64))
end

post "/sellProduct" do |env|
  index = env.params.body["index"].to_i
  price = env.params.body["price"]
  article = env.params.body["article"]
  description = env.params.body["description"]
  from = env.params.body["from"]
  to = env.params.body["to"]
  Block.products.delete_at(index)
  previous = Block.chains[Block.chains.size - 1]
  Block.new previous[:index] + 1, previous[:hash], [{article: article, description: description, from: from, to: to, amount: price.to_f(64)}]
end

Kemal.run
