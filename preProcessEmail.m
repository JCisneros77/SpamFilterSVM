function [stemWords, stemWordsCount] = preProcessEmail(email_contents,stemWords, stemWordsCount)

% The first column stores the word. The second one stores the amount of times
% it's been found.

%stemWords = cell(1,1);
%stemWordsCount = zeros(1,1);

% Find the Headers ( \n\n and remove )
% Uncomment the following lines if you are working with raw emails with the
% full headers

 hdrstart = strfind(email_contents, ([char(10) char(10)]));
 email_contents = email_contents(hdrstart(1):end);


% Lower case
email_contents = lower(email_contents);

% Strip all HTML
% Looks for any expression that starts with < and ends with > and replace
% and does not have any < or > in the tag it with a space
email_contents = regexprep(email_contents, '<[^<>]+>', ' ');

% Handle Numbers
% Look for one or more characters between 0-9
email_contents = regexprep(email_contents, '[0-9]+', 'number');

% Handle URLS
% Look for strings starting with http:// or https://
email_contents = regexprep(email_contents, ...
                           '(http|https)://[^\s]*', 'httpaddr');

% Handle Email Addresses
% Look for strings with @ in the middle
email_contents = regexprep(email_contents, '[^\s]+@[^\s]+', 'emailaddr');

% Handle $ sign
email_contents = regexprep(email_contents, '[$]+', 'dollar');

% Output the email to screen as well
%email_contents

while ~isempty(email_contents)

    % Tokenize and also get rid of any punctuation
    [str, email_contents] = ...
       strtok(email_contents, ...
              [' @$/#.-:&*+=[]?!(){},''">_<;%' char(10) char(13)]);
   
    % Remove any non alphanumeric characters
    str = regexprep(str, '[^a-zA-Z0-9]', '');

    % Stem the word 
    % (the porterStemmer sometimes has issues, so we use a try catch block)
    try str = porterStemmer(strtrim(str)); 
    catch str = ''; continue;
    end;

    % Skip the word if it is too short
    if length(str) < 1
       continue;
    end

    % Add the word to the word list
    % Get the index in case the word already exists
    [v index] = max(strcmp(str,stemWords));

    if (v == 1)
    	% If v == 1 it means the word is already in stemWords
    	stemWordsCount(index) += 1;
    else
    	% THe word doesn't exist yet
    	stemWords(end+1,1) = str;
    	stemWordsCount = [stemWordsCount; 1];
    end
end
end