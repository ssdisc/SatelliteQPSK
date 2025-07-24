%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SignalLoader
function y = SignalLoader(filename,pointStart,Nread)

% 打开文件
fid = fopen(filename, 'rb');

% 设置搜索指针
fseek(fid, (pointStart - 1) * 8, 'bof');

% 读取数据
raw = fread(fid, [2, Nread], 'float32');% float32 int16
y = complex(raw(1,:), raw(2,:));

%关闭指针
fclose(fid);

end

