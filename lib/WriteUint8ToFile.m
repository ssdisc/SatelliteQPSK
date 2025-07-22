function WriteUint8ToFile(uint8Array, outputFilePath)
% uint8ArrayToBinaryFile 将 uint8 数组转换为二进制流并写入文件。
%
% 输入参数:
%   uint8Array: 一个 uint8 类型的数组。
%   outputFilePath: 字符串，表示输出二进制文件的路径。
%
% 示例:
%   data = uint8([72, 101, 108, 108, 111]); % ASCII for "Hello"
%   uint8ArrayToBinaryFile(data, 'binary_output.bin');
%   % 这将创建一个名为 'binary_output.bin' 的文件，
%   % 其中包含 "Hello" 的二进制表示:
%   % 0100100001100101011011000110110001101111

% 检查输入参数
if ~isa(uint8Array, 'uint8')
    error('输入数组必须是 uint8 类型。');
end
if ~ischar(outputFilePath) && ~isstring(outputFilePath)
    error('输出文件路径必须是字符串。');
end

% 打开文件准备写入二进制数据
try
    fid = fopen(outputFilePath, 'wb'); % 'wb' 表示以二进制写入模式打开
    if fid == -1
        error('无法打开文件进行写入: %s', outputFilePath);
    end

    % 逐个处理 uint8 数组中的元素
    for i = 1:length(uint8Array)
        % 将 uint8 值转换为 8 位二进制字符串
        binaryString = dec2hex(uint8Array(i), 2);

        % 将二进制字符串中的每个字符 ('0' 或 '1') 写入文件
        % 注意：这里是将字符 '0' 和 '1' 的 ASCII 值写入文件。
        % 如果希望直接写入原始位，则需要更复杂的方法，
        % 例如，将8位组合成一个字节再写入，或者使用 MATLAB 的 bit* 函数。
        % 对于本例，我们假设 "二进制流" 指的是由 '0' 和 '1' 字符组成的流。
        % 如果需要更紧凑的二进制文件，请参考下面的“更紧凑的二进制输出”部分。

        for k = 1:length(binaryString)
            fwrite(fid, binaryString(k), 'char');
        end
    end

    % 关闭文件
    fclose(fid);
    fprintf('二进制数据已成功写入到: %s\n', outputFilePath);

catch ME
    % 如果在文件操作过程中发生错误，确保关闭文件
    if exist('fid', 'var') && fid ~= -1
        fclose(fid);
    end
    rethrow(ME); % 重新抛出错误
end

end

% --- 更紧凑的二进制输出 (直接写入字节) ---
% 如果你希望文件直接包含原始的二进制位，而不是 '0' 和 '1' 字符的序列，
% 那么 uint8 数组本身已经是你想要的二进制表示了。
% 你可以直接将 uint8 数组写入文件：

function uint8ArrayToRawBinaryFile(uint8Array, outputFilePath)
% uint8ArrayToRawBinaryFile 将 uint8 数组直接按字节写入二进制文件。
%
% 输入参数:
%   uint8Array: 一个 uint8 类型的数组。
%   outputFilePath: 字符串，表示输出二进制文件的路径。
%
% 示例:
%   data = uint8([72, 101, 108, 108, 111]); % ASCII for "Hello"
%   uint8ArrayToRawBinaryFile(data, 'raw_binary_output.bin');
%   % 这将创建一个名为 'raw_binary_output.bin' 的文件，
%   % 文件大小为 5 字节，直接包含这些 uint8 值。
%   % 用十六进制编辑器打开会看到 48 65 6C 6C 6F

% 检查输入参数
if ~isa(uint8Array, 'uint8')
    error('输入数组必须是 uint8 类型。');
end
if ~ischar(outputFilePath) && ~isstring(outputFilePath)
    error('输出文件路径必须是字符串。');
end

% 打开文件准备写入二进制数据
try
    fid = fopen(outputFilePath, 'wb'); % 'wb' 表示以二进制写入模式打开
    if fid == -1
        error('无法打开文件进行写入: %s', outputFilePath);
    end

    % 将整个 uint8 数组作为字节流写入文件
    fwrite(fid, uint8Array, 'uint8');

    % 关闭文件
    fclose(fid);
    fprintf('原始 uint8 数据已成功写入到: %s\n', outputFilePath);

catch ME
    % 如果在文件操作过程中发生错误，确保关闭文件
    if exist('fid', 'var') && fid ~= -1
        fclose(fid);
    end
    rethrow(ME); % 重新抛出错误
end
end