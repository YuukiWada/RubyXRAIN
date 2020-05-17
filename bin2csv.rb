#!/usr/bin/env ruby
# coding: utf-8
require "csv"
require "./lib/XRAIN.rb"

inputFile=ARGV[0]
outputDir=ARGV[1]

parameterData="#{outputDir}/#{File.basename(inputFile, ".*")}_header.dat"
outputFile="#{outputDir}/#{File.basename(inputFile, ".*")}.csv"

radar=Xrain.new(inputFile)

par=radar.parameter(true)
File.open(parameterData, "w") do |output|
  par.each do |line|
    output.puts(line)
  end
end

azimuth_num=radar.azimuth_num
range_num=radar.range_num
data=Array.new(azimuth_num){Array.new}

for i in 0..azimuth_num-1
  for j in 0..range_num-1
    data[i][j]=radar.value(i, j)
  end
end

CSV.open(outputFile, "w") do |output|
  data.each do |line|
    output.puts line
  end
end
