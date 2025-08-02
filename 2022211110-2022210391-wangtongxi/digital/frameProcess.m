% 初始化状态I.Q（'11111 11111 11111'）（'00000 00111 11111'）
stateI = [1 1 1 1 1  1 1 1 1 1  1 1 1 1 1];
stateQ = [0 0 0 0 0  0 0 1 1 1  1 1 1 1 1];

frame=frames(1,:);

sync_word = frame(1:32);
I_content = frame(33:end);

% 生成伪随机序列（PRBS），长度与 data_in 相同
prbsIOri = generate_prbs32767(stateI);
prbsQOri = generate_prbs32767(stateQ);

prbsI = prbsIOri(1:length(I_content));
prbsQ = prbsQOri(1:length(I_content));

%prbsI = prbs131071(100371-48:length(I_content)+100371-48-1);

% 解随机化
I_des = xor(I_content, prbsQ);

% 组合同步字和解扰后的数据
final_frame = [sync_word, I_des];
hex_final_frame = getHex(final_frame);

%data_out_I = ccsds_ldpc_decoder(I_des,8);
%data_out_Q = xor(Q_content, prbsQ);

parse_aos_header_6b(I_des(1:48))
%parse_aos_header_6b(data_out_Q(1:48))



% 将解扰后的十六进制数据写入文件
fileID = fopen('output.txt','w');
fprintf(fileID,'%s\r\n',hex_final_frame);
fclose(fileID);
