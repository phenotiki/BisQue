function A = normalize(A)
%NORMALIZE Normalize matrix A to range [0,1]

minA = min(A(:));
maxA = max(A(:));
A = (A - minA) ./ (maxA - minA);

end