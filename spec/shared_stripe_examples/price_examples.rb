require 'spec_helper'

shared_examples 'Price API' do

  it "creates a stripe price" do
    price = Stripe::Price.create(currency: 'usd', unit_amount: 20)

    expect(price.id).to match(/^test_price/)
    expect(price.currency.to_hash).to eq('usd')
    expect(price.metadata.to_hash).to eq({})
    expect(price.billing_scheme).to eq('per unit')
  end

  describe "listing price" do
    before do
      3.times do
        Stripe::Price.create(currency: 'usd', unit_amount: 20)
      end
    end

    it "without params retrieves all stripe setup_intent" do
      expect(Stripe::Price.all.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::Price.all(limit: 2).count).to eq(2)
    end
  end

  it "retrieves a stripe price" do
    original = Stripe::Price.create()
    price = Stripe::Price.retrieve(original.id)

    expect(price.id).to eq(original.id)
    expect(price.metadata.to_hash).to eq(original.metadata.to_hash)
  end

  it "cannot retrieve a price that doesn't exist" do
    expect { Stripe::Price.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('price')
      expect(e.http_status).to eq(404)
    }
  end
end
