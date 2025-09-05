# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    render Views::PagesHome.new
  end
end
