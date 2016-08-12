function [ estimations ] = sync_SEk_by_SVD( Affinity_mat, confidence_weights, k )
% The synchronization algorithm over SE(k), based on svding the operator:
%        L = DXI - (AX1)\dotX
% As appear in the paper of Arrigoni et. al.
% 
% Input: 
%   Affinity_mat       (X) - upper blocks matrix of ratio measurments,(k+1)n X (k+1)n
%   confidence_weights (A) - matrix of confidence weights for each measurement,
%                        of order nXn
%   k                  - the dimension k of SE(k)
%
% N.S, March 2016

% the affinity matrix
s = size(Affinity_mat,1);
n = size(confidence_weights,1);

if n*(k+1)~=s
    error('wrong matrices sizes');
end

% construct the affinity matrix in SO(k+1) using Psi_lambda by tranform
% each block
L = zeros(s);
for l=1:n
    for j=(l+1):n
        if confidence_weights(l,j)>0
            ind1 = 1+(l-1)*(k+1);
            ind2 = 1+(j-1)*(k+1);
            L(ind1:(ind1+k),ind2:(ind2+k))= Affinity_mat(ind1:(ind1+k),ind2:(ind2+k));
            L(ind2:(ind2+k),ind1:(ind1+k))= inverse_SE_k(Affinity_mat(ind1:(ind1+k),ind2:(ind2+k)));
        end
    end
end
L = L+eye(s);
D = sum(confidence_weights,1);  % degree of nodes = sum of weights 
D = kron(diag(D),eye(k+1));
L = D-L;
% for l=1:n
%     ind1 = 1+(l-1)*(k+1);
%     L(ind1:(ind1+k),ind1:(ind1+k))= (D(l))*eye(k+1);
% end

%extract singular vectors
[~, ~ ,  U] = svd(L);
vecs = U(:,(end-k):end);

% parsing and rounding: 
%  we use several additional versions and choose the best by the

%  option 1 -- look for [0 ... 0 1] rows in LS fasion
estimations1 = Rounding_by_LS(vecs);


% options 2+3 -- just rounding, ignore each "[0 ... 0 1]" row
estimations2 = reshape(vecs',k+1,k+1,n);  
estimations3 = zeros(size(estimations1));
for i = 1:n
    estimations2(:,:,i) = estimations1(:,:,i)';
    estimations2(k+1,:,i) = [zeros(1,k),1];
    B = estimations2(1:k,1:k,i);
    [u, ~, v] = svd(B);
    estimations2(1:k,1:k,i) = u*diag([diag(eye(k-1));det(u*v')])*v'; %
    estimations3(1:k,1:k,i) = u*v'*diag([diag(eye(k-2));det(u*v');1]); %maybe other rounding ?
    estimations3(:,k+1,i) = estimations2(:,k+1,i);
end
% 
err1 = estimate_SE_error_by_data(estimations1, Affinity_mat, confidence_weights);
err2 = estimate_SE_error_by_data(estimations2, Affinity_mat, confidence_weights);
err3 = estimate_SE_error_by_data(estimations3, Affinity_mat, confidence_weights);
[~, j] = min([err1, err2, err3]);
switch j
    case 1
        estimations = estimations1;
    case 2
        estimations = estimations2;
    case 3
        estimations = estimations3;
end

% if err2<err1
%     estimations = estimations2;
% end



end

