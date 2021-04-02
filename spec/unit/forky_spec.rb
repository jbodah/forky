# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Forky do
  it 'should have a version number' do
    expect(::Forky::VERSION).to_not be_nil
  end

  it 'does something useful' do
    expect(true).to eq true
  end
end
