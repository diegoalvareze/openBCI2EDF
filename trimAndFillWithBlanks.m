% Created by Diego Alvarez-Estevez (http://dalvarezestevez.com)
% Last modified 19/01/2018

% Trims, justifies, and fills with blanks a character vector

%% This program is free software: you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation, either version 3 of the License, or
%% (at your option) any later version.

%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.

%% You should have received a copy of the GNU General Public License
%% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function result = trimAndFillWithBlanks(str, maxLength, justify)

if (nargin == 2)
    justify = 'left';
end

if length(str) > maxLength
    result = str(1:maxLength);
else
    if strcmp(justify, 'right')
        result = [blanks(maxLength - length(str)), str];
    else 
        % default is left
        result = [str, blanks(maxLength - length(str))];
    end
end