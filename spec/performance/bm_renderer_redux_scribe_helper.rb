# How to run:
# bundle exec ruby -Ilib spec/performance/bm_renderer_redux_scribe_helper.rb

require 'colloquy'
require "benchmark"

class Benchmarking
  include Colloquy
  include Colloquy::Helpers::Scribe
  def initialize
    Colloquy.root = "examples"
  end
end

$renderer = Benchmarking.new

Benchmark.bmbm do |x|
  x.report { 
    100000.downto(1) do
      $renderer.scribe[:testing].log_visit(:mobile => "8086001291", :circle => "KL", :entry_point => "*522#", :uri => "BOLLY" )
    end
  }
end

