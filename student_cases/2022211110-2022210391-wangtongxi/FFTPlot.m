function [] = FFTPlot(x,fs,figureID)
N=length(x);
figure(figureID);
clf;
X=abs(fft(x));
X = fftshift(X)/N;    % 将零频移到频谱中心
f = (-N/2:N/2-1)*(fs/N);  % 单位: Hz
plot(f,X);
end