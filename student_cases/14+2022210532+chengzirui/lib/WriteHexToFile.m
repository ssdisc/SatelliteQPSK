function WriteHexToFile(byte_array, filename)
    % 打开文件以进行写入
    fileID = fopen(filename, 'w');
    if fileID == -1
        error('无法打开文件: %s', filename);
    end

    % 将每个字节转换为两位十六进制字符串并写入文件
    fprintf(fileID, '%02X', byte_array);

    % 关闭文件
    fclose(fileID);
    disp(['十六进制数据已成功写入到 ', filename]);
end