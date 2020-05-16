
% For every email get a list of processed words

spam_files = dir('spam_2/*.*');
ham_files = dir('easy_ham/*.*');
word_list = cell(1,1);
word_list_count = zeros(1,1);

% This should only get executed to get the vocab list
tic();
for i = 1:length(spam_files)
	% 1 Read the current email
	current_mail = readFile(['spam_2/' spam_files(i).name]);

	%current_mail
	% 2 Preprocess the current mail. The word list is returned with these emails words.
	[word_list,word_list_count] = preProcessEmail(current_mail,word_list,word_list_count);

end
toc();

tic();
for i = 1:length(ham_files)
	% 1 Read the current email
	current_mail = readFile(['easy_ham/' ham_files(i).name]);

	%current_mail
	% 2 Preprocess the current mail. The word list is returned with these emails words.
	[word_list,word_list_count] = preProcessEmail(current_mail,word_list,word_list_count);

end
toc();

% Insert all the words to a list in case we need them later
fid = fopen("AllWords.txt","w");
fprintf(fid,"%s\n",word_list{:});
fclose(fid); 

fid = fopen("AllWordsCounts.txt","w");
fprintf(fid,"%d\n",word_list_count(:));
fclose(fid); 
% At this point we have all of the words and their ocurrences
% Only use the words that were used more than x times

threshold = 123;
vocabFileName = "vocabList.txt";
fid = fopen(vocabFileName,"w");
wordIndex = 1;

for i = 1:length(word_list_count)
	if (word_list_count(i) >= threshold)
	fprintf(fid,"%d %s\n",wordIndex, word_list{i});
	wordIndex += 1;
	endif
endfor
wordIndex
fclose(fid);

% Now load the vocabList
fid = fopen('vocabList.txt');
vocabList = cell(0,1);
while (fscanf(fid,"%d",1))
	vocabList(end+1,1) = fscanf(fid,"%s",1);
end

fclose(fid);

n = length(vocabList);% Number of different words;

% Load the emails as feature vector

X = [];
y = [];
tic();
for i = 1:length(spam_files)
	% 1 Read the current email
	current_mail = readFile(['spam_2/' spam_files(i).name]);

	% 2 Process the current mail. The word list is returned with these email's words.
	word_indexes = processEmail(current_mail,vocabList);

	% 3 Get the words as features
	current_features = emailFeatures(word_indexes,n);

	% 4 Insert these features to the entire set 
	X = [X current_features];

	% 5 Insert a y for this example with 1 since it's spam
	y = [y; 1];
end
toc();

tic();
for i = 1:length(ham_files)
	% 1 Read the current email
	current_mail = readFile(['easy_ham/' ham_files(i).name]);

	% 2 Process the current mail. The word list is returned with these emails words.
	word_indexes = processEmail(current_mail,vocabList);

	% 3 Get the words as features
	current_features = emailFeatures(word_indexes,n);

	% 4 Insert these features to the entire set 
	X = [X current_features];

	% 5 Insert a y for this example with 0 since it's not spam
	y = [y; 0];
end
toc();


% Insert all the X to a file
save X.txt X;
save Y.txt y;


% Load the vocabList
fid = fopen('vocabList.txt');
vocabList = cell(0,1);
while (fscanf(fid,"%d",1))
	vocabList(end+1,1) = fscanf(fid,"%s",1);
end
fclose(fid);

n = length(vocabList);% Number of different words;

% Load X and Y
load('X.txt');
load('Y.txt');

% n where y = 1 (Not spam)
n0_start  = 2398;
n0_amount = 2500;

%Divide the X into training,cross validation and test sets.
total_1s = n0_start - 1;
total_70_1s = ceil(total_1s * .7);
total_15_1s = ceil(total_1s * .15);
X_train = X(:,1:total_70_1s);
X_val   = X(:,total_70_1s+1:total_70_1s + total_15_1s);
X_test  = X(:,(total_70_1s + total_15_1s) + 1:n0_start-1);

y_train = y(1:total_70_1s,:);
y_val   = y(total_70_1s+1:total_70_1s + total_15_1s,:);
y_test  = y((total_70_1s + total_15_1s) + 1:n0_start-1,:);


total_70_0s = ceil(n0_amount * .7);
total_15_0s = ceil(n0_amount * .15);

X_train = [X_train X(:,n0_start:n0_start + total_70_0s-1)];
X_val   = [X_val X(:,total_70_0s+n0_start:n0_start+total_70_0s -1 + total_15_0s)];
X_test  = [X_test X(:,(n0_start + total_70_0s + total_15_0s) :end)];

y_train = [y_train; y(n0_start:n0_start + total_70_0s-1,:)];
y_val   = [y_val;y(total_70_0s+n0_start:n0_start+total_70_0s -1 + total_15_0s,:)];
y_test  = [y_test;y((n0_start + total_70_0s + total_15_0s) :end,:)];

% Make a file with the input how the library expects it
% <label> <index1;value1> <index2>:<value2>
% Where <label> = integer indicating the class label. In this case 1 or 0
% Where <index> = feature number. Goes from 1 to n
% Where <vañue> = the value of feature <index>
filename = "X_train.txt";
fid = fopen(filename,"w");

%For every example in the training set
for i = 1:size(X_train,2)
	% Write the label for this training example
	fprintf (fid, '%d ',y_train(i));
	% For every feature
	for j = 1:n
	% Write the jth feature and its value
	fprintf (fid, '%d:%d ',j,X_train(j,i));
	end
	% WHen all features have been written, print a new line
	fprintf (fid, '\n');
end

fclose(fid);

% Train the SVM
C = 0.1;
options = cstrcat("-t 0 -c ",num2str(C));
model = svmtrain(y_train,X_train',options);

% Test the SVM with the cross validation set
[p] = svmpredict(y_val,X_val',model);

fprintf('Training Accuracy on Cross-Validation: %f\n', mean(double(p == y_val)) * 100);

% Test the SVM with the test set
[p] = svmpredict(y_test,X_test',model);

fprintf('Training Accuracy on Test: %f\n', mean(double(p == y_test)) * 100);

% Test the emailSample
	% 1 Read the current email
	sample_email = readFile('emailSample1.txt');

	% 2 Process the current mail. The word list is returned with these email's words.
	word_indexes = processEmail(sample_email,vocabList);

	% 3 Get the words as features
	X_sample = emailFeatures(word_indexes,n)';

	% 5 Insert a y for this example with 1 since it's spam
	y_sample = [1];

[p] = svmpredict(y_sample,X_sample,model);
