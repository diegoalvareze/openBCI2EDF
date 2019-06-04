% Created by Diego Alvarez-Estevez (http://dalvarezestevez.com)
% Last modified 19/01/2018

% Extracts EEG data from an OpenBCI exported file and saves it to EDF format (check www.edfplus.info for more information on EDF/EDF+ format) 

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

%%----------------------------------------------------------------------

% Clean possible previously-existing results
clear all;
clc;

%% USER CONFIGURABLE PARAMETERS

% Skip first (possible invalid, such as comments, etc.) rows of the OpenBCI
% export file. Note this is file-dependent, use a "more" (windows) or "cat" (unix/linux) alike commands
% to check the real beginning of the recording
skipFirstLines = 0;
% Sampling frequency of the signals, depends on OpenBCI configuration, default is 250 Hz
fs = 250;
% Number of channels (default in OpenBCI is 8)
nchannels = 8;
% Signal filtering paramaters
highpass_f = 0.1; % High-pass cut-off frequency
notch_fc = 50; % Frequency of mains interference (50 Hz for Europe)
notch_w = 1; % Notch filter bandwith

%% CONVERSION SCRIPT STARTS

% Ask the user to select the source file
[filename, path] = uigetfile(['.', filesep, '*.*'], 'Select file in OpenBCI format');
if (filename == 0)
    return;
end
fullfilename = fullfile(path, filename);

% Asks some necessary data to the user
disp('Please provide the following information to complete the header information of the EDF file');
disp('Check www.edfplus.info/specs/edf.html for detailed information');
% Examples
% patId = 'XXX';
% recId = 'XXX';
% startdate = '23.06.17';
% starttime = '00.08.52';
patId = input('\nSpecify the local patient identification string\n(max 80 characters, press [ENTER] to continue): ', 's');
recId = input('\nSpecify the local recording identification string\n(max 80 characters, press [ENTER] to continue): ' , 's');
startdate = input('\nSpecify the Startdate of recording\n(DD.MM.YY, press [ENTER] to continue): ', 's');
starttime = input('\nSpecify the Starttime of recording\n(HH.MM.SS, press [ENTER] to continue): ', 's');

% Read OpenBCI data
fprintf(1, '\nReading OpenBCI data...');
data = csvread(fullfilename, skipFirstLines, 0);
eegdata = data(:, 2:9);          

% Apply signal filtering
fprintf(1, '\nFiltering signals...\n');
for k = 1:nchannels
    f_eeg(:, k) = polymanHighPassFilter(eegdata(:, k), fs, 1, highpass_f);
    
    f_eeg(:, k) = polymanNotchFilter(f_eeg(:, k), fs, notch_fc, notch_w); 
end

% Export unfiltered data
disp('Writing signals (unfiltered) to EDF file...');
filename1 = [filename, '-raw.edf'];
signals = [];
snames = [];
units = [];
prefilterings = [];
for k = 1:nchannels
    signals{k} = eegdata(:, k);
    snames{k} = sprintf('EEG CH%d', k);
    fsamps(k) = fs;
    Pmins(k) = min(eegdata(:, k));
    Pmaxs(k) = max(eegdata(:, k));
    Dmins(k) = -32768;
    Dmaxs(k) = 32767;
    units{k} = 'uV';
    prefilterings{k} = '';
end

statusOK = signals2EDF(signals, fsamps, patId, recId, snames, startdate, starttime, Pmins, Pmaxs, Dmins, Dmaxs, units, prefilterings, filename1);

if not(statusOK)
    error('Problem exporting unfiltered signals to EDF');
else
    disp('...done!');
end

% Export filtered data
disp('Writing signals (filtered) to EDF file...');
filename1 = [filename, '-filt.edf'];
signals = [];
snames = [];
units = [];
prefilterings = [];
for k = 1:nchannels
    signals{k} = f_eeg(:, k);
    snames{k} = sprintf('EEG CH%d', k);
    fsamps(k) = fs;
    Pmins(k) = min(f_eeg(:, k));
    Pmaxs(k) = max(f_eeg(:, k));
    Dmins(k) = -32768;
    Dmaxs(k) = 32767;
    units{k} = 'uV';
    prefilterings{k} = sprintf('HP(%g) Notch(%g/%g)', highpass_f, notch_fc, notch_w);
end
    
statusOK = signals2EDF(signals, fsamps, patId, recId, snames, startdate, starttime, Pmins, Pmaxs, Dmins, Dmaxs, units, prefilterings, filename1);

if not(statusOK)
    error('Problem exporting filtered signals to EDF');
else
    disp('...done!')
end
