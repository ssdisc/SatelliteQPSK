load("SatelliteData.mat")

N=length(complex_data);

oriFs=125e6;
rs=75e6;
r=6;
fs=oriFs*r;

% 上采样
complex_data_inp = upsample(complex_data,r);
lowpassFilter=fir1(100,0.15,"low");
complex_data_inp = filter(lowpassFilter,1,complex_data_inp);
FFTPlot(complex_data_inp,fs,1);

% 时间序列产生
ts_complex_data = array2timetable(complex_data_inp',"SampleRate",fs);

quadC = complex_data_inp.^4;
FFTPlot(quadC,oriFs,2)