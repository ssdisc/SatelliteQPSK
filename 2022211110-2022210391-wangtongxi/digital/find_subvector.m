function positions = find_subvector(mainVector, subVector)
% 替代实现 - 使用滑动窗口方法

mainVector = mainVector(:)';
subVector = subVector(:)';

n = length(mainVector);
m = length(subVector);
positions = [];

if m > n
    return;
end

for i = 1:(n - m + 1)
    if all(abs(mainVector(i:i+m-1) - subVector) < eps)
        positions = [positions, i];
    end
end
end