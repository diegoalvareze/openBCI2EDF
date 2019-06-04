% Created by Diego Alvarez-Estevez (http://dalvarezestevez.com)
% Last modified 19/01/2018

% Implements Notch filter from Polyman

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

function signalFilt = polymanNotchFilter(signal, sr, centerFreq, bandWidth)

% Check for valid settings
if ((centerFreq <= 0) || (centerFreq > sr/2))
    error('Center frequency is not in the Nyquist interval');
elseif ((bandWidth <= 0) || (bandWidth > sr/4))
    error('Not valid bandwidth');
end

r = 2 * pi * centerFreq/sr;
s = 2 * pi * (centerFreq - (bandWidth/2))/sr;
t = 1 - sqrt((cos(r)-cos(s))^2 + (sin(r)-sin(s))^2) * sqrt(exp(1)^2-1);
x = cos(r);
y = sin(r);

b = [1, -2*x, x^2+y^2]; % b coeffs according to filter function description (for x(n))
a = [1, 2*t*x, -((t*x)^2 + (t*y)^2)]; % a coeffs according to filter function description (for y(n))

% We multiply a(2:end)*(-1) because filter function is implemented as a direct
% form II transposed structure
a(2:end) = -a(2:end);

signalFilt = filter(b, a, signal);
    
    