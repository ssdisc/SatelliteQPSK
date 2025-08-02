function hexStr = getHex(bin)
nibbles = reshape(bin(1,:), 4, [])'; % 每行一组4位
hexStr = dec2hex(bin2dec(num2str(nibbles)))';
end

