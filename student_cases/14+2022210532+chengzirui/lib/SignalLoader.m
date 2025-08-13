%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SignalLoader
function y = SignalLoader(filename,pointStart,Nread)

% 打开文件
fid = fopen(filename, 'rb');

% 设置搜索指针
fseek(fid, (pointStart - 1) * 8, 'bof');

% 读取数据
if Nread == -1
    % 读取文件中所有剩余数据
    raw = fread(fid, [2, Inf], 'int16');
else
    % 读取指定数量的数据
    raw = fread(fid, [2, Nread], 'int16');
end

y = complex(raw(1,:), raw(2,:));

%关闭指针
fclose(fid);

end

