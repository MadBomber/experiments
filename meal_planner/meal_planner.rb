#!/usr/bin/env ruby

require 'hashie'

# multi-week
class Plan < Hashie::Mash
end

# has name, parts, which type of meal it is most appropriate for
class Recipe
	@@all = []
	attr_reader :name
	attr_reader :parts
	attr_reader :meals
	def initialize(a_string, &block)
		@name  = a_string
		@parts = []
		@meals = []
		instance_eval(&block) if block_given?
		@@all << self
	end
	def meal(*args)
		@meals << args
		@meals.flatten!
	end
	def buy(*args)
		@parts << args
		@parts.flatten!
	end
	def breakfast
		:breakfast
	end
	def lunch
		:lunch
	end
	def dinner
		:dinner
	end
	def snack
		:snack
	end
	class << self
	  def all
	    @@all
	  end
	  def a_breakfast
	    all.select {|r| r.meal.include? :breakfast}.sample
	  end
	  def a_lunch
	    all.select {|r| r.meal.include? :lunch}.sample
	  end
	  def a_dinner
	    all.select {|r| r.meal.include? :dinner}.sample
	  end
	  def a_snack
	    all.select {|r| r.meal.include? :snack}.sample
	  end
	end
end

# one of sunday .. saturday
class Day < Hashie::Mash
end

# seven days
class Week < Hashie::Mash
end



Recipe.new('cereal') {
  meal :breakfast, :lunch, :dinner
  buy :milk, :raisen_bran_regular
}

Recipe.new('sandwich') {
  meal :lunch, :dinner
  buy :bread, :mustard
  buy :ham_slices, :chicken_slices, :turkey_slices
  buy :chips
}

Recipe.new('pudding') do
	meal snack
	buy :chocolate_pudding
end

Recipe.new('ice cream sandwich') do
	meal snack
	buy :ice_cream_sandwich
end

Recipe.new('cookies') do
	meal snack
	buy :butter, :chocolate_chips, :milk
end

Recipe.new('muffins') do
	meal snack, breakfast
	buy :muffin_mix, :chocolate_chips, :milk
end

Recipe.new('nacon and eggs') do
	meal breakfast
	buy :bacon, :eggs, :milk
end

Recipe.new('pancakes') do
	meal breakfast
	buy :pancake_mix, :milk
end

Recipe.new('french toast') do
	meal breakfast
	buy :bread, :eggs, :butter, :milk
end

Recipe.new('hot pockets') do
	meal breakfast, lunch, dinner
	buy :ham_and_cheese_hot_pockets
end

Recipe.new('tecquitas') do
	meal breakfast, lunch, dinner
	buy :ham_and_cheese_tecquitas
end

Recipe.new('chicken and rice') do
	meal dinner
	buy :chicken, :rice
end

Recipe.new('donuts') do
	meal breakfast
	buy :donuts
end

Recipe.new('mini-cinnies') do
	meal breakfast
	buy :mini_cinnies
end

Recipe.new('carry out') do
	meal lunch, dinner
	buy :sonic, :white_castle, :chic_fil_a, :pizza_hut
end



$DOW = %w[ sunday monday tuesday wednesday thursday friday saturday ]
$MPD = %w[ breakfast lunch dinner snack ]

$plan = Plan.new
$plan.week = [Week.new, Week.new]

$DOW.each do |day|
  eval "$plan.week.first.#{day}=Day.new"
  $MPD.each do |meal|
	eval "$plan.week[0].#{day}.#{meal}=Recipe.a_#{meal}"
  end
end

eval "$plan.week[1] = $plan.week[0].dup"


