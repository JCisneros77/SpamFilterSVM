function x = emailFeatures(word_indices,n)
%EMAILFEATURES takes in a word_indices vector and produces a feature vector
%from the word indices
%   x = EMAILFEATURES(word_indices) takes in a word_indices vector and 
%   produces a feature vector from the word indices. 

% Total number of words in the dictionary
%n = 1899;

% You need to return the following variables correctly.
x = zeros(n, 1);

for i = 1:n
		 % If i exists in word_indices, this will return 1 otherwise returns 0.
		x(i) = max(word_indices == i);
end





% =========================================================================
    

end
