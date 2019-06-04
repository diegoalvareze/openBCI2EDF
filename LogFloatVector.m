% Created by Diego Alvarez-Estevez (http://dalvarezestevez.com)
% Last modified 19/01/2018

% LogFloat conversion (see www.edfplus.info/specs/edffloat.html for
% more information)

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

function out = LogFloatVector(vector, Y0, A)

out = zeros(size(vector));

r = (log10(vector(vector > Y0)) - log10(Y0)) / A;
out(vector > Y0) = int16(round(min(r, intmax('int16'))));

r = (-log10((-1)*vector(vector < Y0)) + log10(Y0)) / A;
out(vector < Y0) = int16(round(max(r, -intmax('int16'))));

% Those with zero value at input remain zero at output