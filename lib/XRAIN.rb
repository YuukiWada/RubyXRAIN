#!/usr/bin/env ruby
# coding: utf-8
require "time"
require "RubyROOT"
include Root
include RootApp
include Math

$pi=Math::PI

def signed_hex(input)
  value=input.hex
  if value>32767 then
    value+=-2**16
  end
  return value
end

def read_elevation(inputFile)
  file=`hexdump -vC #{inputFile}`
  file.each_line do |line|
    line.chomp!
    parse=line.split("\s")
    row=parse[0].to_i(16)
    if row==48 then
      ele_hex="#{parse[1]}#{parse[2]}"
      value=signed_hex(ele_hex)
      elevation=(value.to_f*0.01).round(2)
      return elevation
    end
  end
end

def extract_elevation(date, start_time, ele_first, ele_second, ele_num)
  elevation=Array.new
  elevation << read_elevation("../data/NOUMI00000-#{date}-#{ele_first}-RZH0-EL#{sprintf("%02d", 1)}0000")
  elevation << read_elevation("../data/NOUMI00000-#{date}-#{ele_second}-RZH0-EL#{sprintf("%02d", 2)}0000")
  for i in 3..12
    elapse=(((i-3).to_f/2.0).floor)*60.0
    time_object=Time.parse("#{date}_#{start_time}00")
    time_process=time_object+elapse
    time=time_process.strftime("%H%M")
    elevation << read_elevation("../data/NOUMI00000-#{date}-#{time}-RZH0-EL#{sprintf("%02d", i)}0000")
  end
  elevation.sort!
  ybins=Array.new
  ybins[0]=0.0
  for i in 1..11
    ybins[i]=((elevation[i]+elevation[i-1])/2.0).round(2)
  end
  ybins[12]=(elevation[11]+(elevation[11]-elevation[10])/2.0).round(2)
  return ybins
end

def extract_name(date, ele_first, ele_second, start_time, type)
  fileName=Array.new
  fileName << "../data/NOUMI00000-#{date}-#{ele_first}-#{type}-EL#{sprintf("%02d", 1)}0000"
  fileName << "../data/NOUMI00000-#{date}-#{ele_second}-#{type}-EL#{sprintf("%02d", 2)}0000"
  for i in 3..12
    elapse=(((i-3).to_f/2.0).floor)*60.0
    time_object=Time.parse("#{date}_#{start_time}00")
    time_process=time_object+elapse
    time=time_process.strftime("%H%M")
    fileName << "../data/NOUMI00000-#{date}-#{time}-#{type}-EL#{sprintf("%02d", i)}0000"
  end
  return fileName
end

def read_date(inputFile, sector_num)
  data=Array.new(sector_num){Array.new}
  file=`hexdump -vC #{inputFile}`
  n=0
  file.each_line do |line|
    line.chomp!
    parse=line.split("\s")
    row=parse[0].to_i(16)
    if (row>=512)&&(row<325712) then
      for i in 1..16
        sector=n/1084
        data[sector] << parse[i]
        n+=1
      end
    end
  end
  return data
end

def inerpret_raw(raw, sector, range)
  value=Array.new
  elevation_int=signed_hex(raw[sector][4]+raw[sector][5])
  value[0]=(elevation_int.to_f*0.01).round(2)
  azimuth_start_int=signed_hex(raw[sector][0]+raw[sector][1])
  azimuth_end_int=signed_hex(raw[sector][2]+raw[sector][3])
  value[1]=((azimuth_start_int.to_f+azimuth_end_int.to_f)*0.5*0.01).round(2)
  reflection_int=(raw[sector][16+2*range]+raw[sector][17+2*range]).hex
  value[2]=((reflection_int-32768).to_f/100.0).round(2)
  return value
end

def elevation_range_search(inputFile, elevation)
  elevation_now=read_elevation(inputFile)
  result=Array.new
  for i in 0..elevation.length-2
    if (elevation_now>=elevation[i])&&(elevation_now<elevation[i+1])
      result[0]=elevation[i]
      result[1]=elevation[i+1]
    end
  end
  return result
end

event_num=9
ele_num=12  
date=["20161208", "20170113", "20170113", "20170115", "20170206", "20171205", "20171211", "20181218", "20190122"]
#start_time=["0016", "0141", "0506", "0531", "0511", "1831", "1751", "2351", "0101"]
#ele_first=["0015", "0145", "0507", "0531", "0511", "1835", "1753", "2353", "0105"]
#ele_second=["0014", "0144", "0506", "0532", "0512", "1834", "1754", "2352", "0104"]
start_time=["0011", "0141", "0506", "0531", "0511", "1831", "1751", "2351", "0101"]
ele_first=["0011", "0141", "0507", "0531", "0511", "1831", "1751", "2351", "0101"]
ele_second=["0012", "0142", "0506", "0532", "0512", "1832", "1752", "2352", "0102"]

azimuth_center=47
azimuth_step=1.2

sector_num=300
range_num=534
range_step=0.15
range_max=80.1

vertical_length=5.0
vertical_num=1000
vertical_step=(vertical_length/vertical_num.to_f).round(3)

elevation_list=[0.0, 1.35, 2.15, 3.1, 4.2, 5.45, 6.8, 8.25, 9.8, 11.45, 13.2, 15.05, 16.95]

#type=["RZH0", "RZDR", "RKDP"]
type=["RZH0"]

c0=Root::TCanvas.create("c0", "c0", 640, 480)

type.each do |type|
  hist=Array.new
  for n in 0..event_num-1
    hist[n]=Root::TH2F.create("h#{n}", "h#{n}", range_num, 0.0, range_max, vertical_num, 0.0, vertical_length)
    inputFile=extract_name(date[n], ele_first[n], ele_second[n], start_time[n], type)
    inputFile.each do |inputFile|
      puts inputFile
      raw=read_date(inputFile, sector_num)
      elevation=elevation_range_search(inputFile, elevation_list)
      for i in 50..250
        range_dist=(0.5+i.to_f)*range_step
        value=inerpret_raw(raw, azimuth_center-1, i)
        if ((type=="RZH0")&&(value[2]>0.0))||(type!="RZH0") then
          elevation_min=range_dist*tan(elevation[0]*$pi/180.0)
          elevation_max=range_dist*tan(elevation[1]*$pi/180.0)
          min_index=(elevation_min/vertical_step).floor
          max_index=(elevation_max/vertical_step).floor
          for j in min_index..max_index-1
            elevation_dist=(0.5+j.to_f)*vertical_step
            hist[n].Fill(range_dist, elevation_dist, value[2])
          end
        end
      end
    end
    hist[n].Draw("colz")
    hist[n].GetXaxis().SetRangeUser(7.5, 37.5)
    c0.Update()
    c0.SaveAs("output/#{type}_#{n}.png")
  end
end
  
