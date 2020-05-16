#!/usr/bin/env ruby
# coding: utf-8

class Xrain
  
  def initialize(inputFile, display=true)
    if display then
      credit()
    end
    data_1st=(`hexdump -vC #{inputFile}`).split("\n")
    @parameter=extract_par(data_1st)
    data_2nd=extract_1st(data_1st)
    @data=extract_2nd(data_2nd)
    @sector_header=extract_sector_header(data_2nd)
  end

  def extract_1st(file)
    sector_num=@parameter[23]
    range_num=@parameter[22]
    data=Array.new(sector_num){Array.new}
    n=0
    byte=16+2*range_num
    file.each do |line|
      line.chomp!
      parse=line.split("\s")
      row=parse[0].to_i(16)
      if (row>=512)&&(parse.length>1) then
        for i in 1..16
          sector=n/byte
          data[sector] << parse[i]
          n+=1
        end
      end
    end
    return data
  end

  def extract_2nd(data)
    value_2nd=Array.new(@parameter[23]){Array.new}
    for i in 0..@parameter[23]-1
      for j in 0..@parameter[22]-1
        value_2nd[i][j]=data[i][16+j*2]+data[i][17+j*2]
      end
    end
    return value_2nd
  end

  def extract_sector_header(data)
    header=Array.new
    for i in 0..@parameter[23]-1
      header[i]=[((data[i][0]+data[i][1]).hex.to_f/100).round(2), ((data[i][2]+data[i][3]).hex.to_f/100).round(2),
                 ((data[i][4]+data[i][5]).hex.to_f/100).round(2), ((data[i][6]+data[i][7]).hex.to_f/100).round(2)]
    end
    return header
  end
  
  def extract_par(file)
    # [DATA TYPE, OBSERVATION SITE, DATE, TIME, STATUS, ROTATION, CAPPI, CAPPI STEP, STEP NUM, ANGLE, SITE STATUS, LATITUDE, LONGITUDE, ALTITUDE
    #  HORISONTAL POWER, VERTICAL POWER, FREQUENCY, START TIME, END TIME, RANGE START, RANGE END, RANGE RESOLUTION, RANGE NUM, AZIMUTH NUM]
    parameter=Array.new
    data=Array.new
    for i in 0..10
      file[i].chomp!
      data[i]=file[i].split("\s")
    end

    # OBSERVATION SITE
    parameter[0]=data[0][5]+data[0][6]

    # DATA TYPE
    parameter[1]=data[0][8]
    
    # DATE
    parameter[2]=[["#{data[0][9]+data[0][10]+data[0][11]+data[0][12]}"].pack('H*'), ["#{data[0][14]+data[0][15]}"].pack('H*'), ["#{data[1][1]+data[1][2]}"].pack('H*')]

    # TIME
    parameter[3]=[["#{data[1][4]+data[1][5]}"].pack('H*'), ["#{data[1][7]+data[1][8]}"].pack('H*')]
    
    # STATUS
    if data[2][2]=="01" then
      parameter[4]="正常"    
    else
      parameter[4]="異常"
    end
    
    # ROTATION
    parameter[5]=((data[2][9]+data[2][10]).to_f/10.0).round(2)

    # CAPPI
    if data[2][11]+data[2][12]=="0001"
      parameter[6]="CAPPI"
    else
      parameter[6]="PPI"
    end

    # CAPPI STEP
    parameter[7]=(data[2][13]+data[2][14]).hex

    # STEP NUM
    parameter[8]=(data[2][15]+data[2][16]).hex
      
    # ANGLE
    temp=(data[3][1]+data[3][2]).hex
    if temp>32767 then
      temp+=-2**16
    end
    parameter[9]=(temp.to_f/100.00).round(2)
    
    # SITE STATUS
    if data[3][5]+data[3][6]+data[3][7]+data[3][8]=="00000004" then
      parameter[10]="正常"
    else
      parameter[10]="異常"
    end
    
    # LATITUDE
    parameter[11]=[(data[3][15]+data[3][16]).hex, (data[4][1]+data[4][2]).hex, (data[4][3]+data[4][4]).hex]

    # LONGITUDE
    parameter[12]=[(data[4][5]+data[4][6]).hex, (data[4][7]+data[4][8]).hex, (data[4][9]+data[4][10]).hex]

    # ALTITUDE
    parameter[13]=(((data[4][11]+data[4][12]+data[4][13]+data[4][14]).hex).to_f/100.0).round(2)

    # HORIZONTAL POWER
    parameter[14]=(((data[5][9]+data[5][10]).hex).to_f/100.0).round(2)

    # VERTICAL POWER
    parameter[15]=(((data[6][7]+data[6][8]).hex).to_f/100.0).round(2)

    # FREQUENCY
    parameter[16]=((data[6][15]+data[6][16]).hex.to_f/1000).round(3)

    # START TIME
    parameter[17]=[["#{data[8][1]+data[8][2]}"].pack('H*'), ["#{data[8][4]+data[8][5]}"].pack('H*'), ["#{data[8][7]+data[8][8]}"].pack('H*')]

    # END TIME
    parameter[18]=[["#{data[8][9]+data[8][10]}"].pack('H*'), ["#{data[8][12]+data[8][13]}"].pack('H*'), ["#{data[8][15]+data[8][16]}"].pack('H*')]

    # RANGE START
    parameter[19]=((data[9][1]+data[9][2]+data[9][3]+data[9][4]).hex.to_f/100000.0).round(3)

    # RANGE END
    parameter[20]=((data[9][5]+data[9][6]+data[9][7]+data[9][8]).hex.to_f/100000.0).round(3)
    
    # RANGE RESOLUTION
    parameter[21]=((data[9][9]+data[9][10]+data[9][11]+data[9][12]).hex.to_f/100000.0).round(3)

    # RANGE NUM
    parameter[22]=(data[9][13]+data[9][14]+data[9][15]+data[9][16]).hex
        
    # AZIMUTH NUM
    parameter[23]=(data[10][1]+data[10][2]).hex

    return parameter
  end

  def extract_type()
    number=["05", "06", "07", "08","09", "0E", "11", "12", "15", "19", "21", "25", "31", "35"]
    name=["受信電力強度 (dB)", "受信電力強度 (dB)", "受信電力強度 (dB)", "受信電力強度 (dB)", "受信電力強度 (dB)", "受信電力強度 (dB)", "受信電力強度 (dB)",
          "レーダー反射因子 (dBZ)", "風速 (m/s)", "分散 (m/s)", "反射因子差 (dB)", "偏波間相関係数", "偏波間位相差 (deg)", "伝播位相差変化率 (deg/km)"]
    i=number.index(@parameter[1])
    return name[i]
  end

  def extract_site()
    number=["8105", "8106", "8107", "8108", "8109", "8205", "8206", "8207", "8208", "8209", "820a", "820b",
            "8305", "8306", "8405", "8406", "8407", "8408", "8409", "840a", "8505", "8506", "8507", "8508",
            "8605", "8606", "8607", "8608", "8609", "860a", "860b", "8705", "8706", "8707", "8708",
            "8805", "8806", "8807", "8808", "8900", "8a00"]
            
    name=["関東/関東", "関東/新横浜", "関東/氏家", "関東/八丈島", "関東/船橋", "九州/九千地", "九州/菅岳", "九州/古月山", "九州/風師山", "九州/桜島", "九州/山鹿", "九州/宇城",
          "北海道/北広島", "北海道/石狩", "東北/一関", "東北/一迫", "東北/涌谷", "東北/岩沼", "東北/伊達", "東北/田村", "北陸/水橋", "北陸/能美", "東北/京ヶ瀬", "東北/中の口",
          "中部/尾西", "中部/安城", "中部/鈴鹿", "中部/静岡北", "中部/香貫山", "中部/富士宮", "中部/浜松", "近畿/六甲", "近畿/葛城", "近畿/鷲峰山", "近畿/田口",
          "中国/熊山", "中国/常山", "中国/野貝原", "中国/牛尾山", "四国", "沖縄"]
    i=number.index(@parameter[0])
    return name[i]
  end

  def credit()
    puts ""
    puts "    -------------------------------------------------- "
    puts "   | 国土交通省 XRAIN バイナリ解析 ruby ライブラリ    |"
    puts "   | Version 1.0 (2020年5月16日)                      |"
    puts "   | 作成: 和田有希 (理化学研究所)                    |"
    puts "   | https://github.com/YuukiWada/XRAIN               |"
    puts "   |                                                  |"
    puts "   | 本ソフトウェアを用いて生じた不利益・損害について |"
    puts "   | 作成者は一切の責任を負いません。                 |"
    puts "    -------------------------------------------------- "
    puts ""
  end
    
  def parameter()
    puts ""
    puts "   レーダーサイト     : #{extract_site()}"
    puts "   データ種別         : #{extract_type()}"
    puts "   データ配信日時     : #{@parameter[2][0]}年#{@parameter[2][1]}月#{@parameter[2][2]}日 #{@parameter[3][0]}時#{@parameter[3][1]}分 (日本標準時)"
    puts "   XRAINステータス    : #{@parameter[4]}"
    puts "   サイトステータス   : #{@parameter[10]}"
    puts "   レーダー回転速度   : #{@parameter[5]} rpm" 
    puts "   運用モード         : #{@parameter[6]}"
    puts "   CAPPI仰角数        : #{@parameter[7]}"
    puts "   CAPPI仰角番号      : #{@parameter[8]}"
    puts "   CAPPI仰角          : #{@parameter[9]}度"
    puts "   レーダーサイト緯度 : 北緯#{@parameter[11][0]}度#{@parameter[11][1]}分#{@parameter[11][2]}秒"
    puts "   レーダーサイト経度 : 東経#{@parameter[12][0]}度#{@parameter[12][1]}分#{@parameter[12][2]}秒"
    puts "   レーダーサイト高度 : #{@parameter[13]} m"
    puts "   水平偏波送信電力   : #{@parameter[14]} kW"
    puts "   垂直偏波送信電力   : #{@parameter[15]} kW"
    puts "   送信周波数         : #{@parameter[16]} GHz"
    puts "   観測開始時刻       : #{@parameter[17][0]}時#{@parameter[17][1]}分#{@parameter[17][2]}秒 (日本標準時)"
    puts "   観測終了時刻       : #{@parameter[18][0]}時#{@parameter[18][1]}分#{@parameter[18][2]}秒 (日本標準時)"
    puts "   視線方向最小距離   : #{@parameter[19]} km"
    puts "   視線方向最大距離   : #{@parameter[20]} km"
    puts "   視線方向ステップ   : #{@parameter[21]} km"
    puts "   視線方向観測数     : #{@parameter[22]}"
    puts "   方位角観測数       : #{@parameter[23]}"
    puts ""
  end
  
  def value(i, j)
    if (i>=0)&&(i<@parameter[22])&&(j>=0)&&(j<@parameter[23]) then
      number=["05", "06", "07", "08","09", "0E", "11", "12", "15", "19", "21", "25", "31", "35"]
      a=[90.0, 95.0, 100.0, 105.0, 1.0, 80.0, 85.0, 1.0, 1.0, 1.0, 1.0, 1.0, 360.0, 1.0]
      b=[0.0, 0.0, 0.0, 0.0, 32768.0, 0.0, 0.0, 32768.0, 32768.0, 1.0, 32768.0, 1.0, 1.0, 32768.0]
      c=[16384, 16384, 16384, 16384, 100.0, 16384, 16384, 100.0, 100.0, 100.0, 100..0, 65533.0, 65534.0, 100.0]
      type=number.index(@parameter[1])
      value=a[type]*(@data[i][j].hex.to_f-b[type])/c[type]
      return value
    else
      puts "指定した方位角・視線方向距離は範囲外です。"
      exit 1
    end
  end

  def azimuth_start(sector)
    return @sector_header[sector][0]
  end

  def azimuth_end(sector)
    return @sector_header[sector][1] 
 end

  def elevation_start(sector)
    return @sector_header[sector][4]
  end

  def elevation_end(sector)
    return @sector_header[sector][3]
  end

  def range_num()
    return @parameter[22]
  end

  def range_min()
    return @parameter[19]
  end
  
  def range_max()
    return @parameter[20]
  end
  
  def range_step()
    return @parameter[21]
  end
  
  def azimuth_num()
    return @parameter[23]
  end
  
  def date()
    return "#{@parameter[2][0]}-#{@parameter[2][1]}-#{@parameter[2][2]}"
  end
  
  def time()
    return "#{@parameter[3][0]}:#{@parameter[3][1]}:00"
  end

  def obs_start()
    return "#{@parameter[17][0]}:#{@parameter[17][1]}:#{@parameter[17][2]}"
  end

  def obs_end()
    return "#{@parameter[18][0]}:#{@parameter[18][1]}:#{@parameter[18][2]}"
  end
  
  def elevation()
    return @parameter[9]
  end
  
end
