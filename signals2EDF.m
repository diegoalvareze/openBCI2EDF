% Created by Diego Alvarez-Estevez (http://dalvarezestevez.com)
% Last modified 19/01/2018

% Saves signals contained on a Matlab structure to EDF format

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

function statusok = signals2EDF(signals, srs, patId, recId, snames, startdate, starttime, Pmins, Pmaxs, Dmins, Dmaxs, units, prefilterings, filename)

fid = fopen(filename, 'w', 'ieee-le');

if (fid == -1)
    fprintf(1, 'Error creating output file %s\n', filename);
    return;
end

numSignals = length(srs);

% Calculate recording length (in seconds)
recLength = -1;
for k = 1:numSignals
    recLength = max(recLength, length(signals{k})/srs(k));
end
recLength = ceil(recLength); % Ceil to an integer number

% Asuming 1s databloack duration. Check possible incompatibilities
blockSizeBytes = sum(2*srs(:));

if (blockSizeBytes > 61440)
    error('Yet to be implemented: Signals cannot fit on a 1s datablock. Check for other block size possibilities'); 
else
    blockSize = 1;
    numBlocks = recLength;
end
    
general_header_size = 256; %bytes
one_signal_header_size = 256; %bytes

% Write edf

% FIXED HEADER
header.version = 0;
header.local_patient_identification = patId;
header.local_recording_identification = recId;
header.startdate_recording = startdate;
header.starttime_recording = starttime;
header.num_signals = numSignals;
header.num_bytes_header = general_header_size + one_signal_header_size * numSignals;
header.reserved = '';
header.duration_data_record = blockSize;
header.num_data_records = numBlocks;

fprintf(fid, trimAndFillWithBlanks(num2str(header.version), 8));   % version
fprintf(fid, '%-80s', header.local_patient_identification);
fprintf(fid, '%-80s', header.local_recording_identification);
fprintf(fid, '%-8s', header.startdate_recording);
fprintf(fid, '%-8s', header.starttime_recording);
fprintf(fid, trimAndFillWithBlanks(num2str(header.num_bytes_header), 8));
fprintf(fid, '%-44s', header.reserved);
fprintf(fid, trimAndFillWithBlanks(num2str(header.num_data_records), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.duration_data_record), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.num_signals), 4));

% SIGNAL DEPENDENT HEADER
signalOffsets = zeros(1, numSignals); % In bytes
for k = 1:numSignals
    header.signals_info(k).label = snames{k};
    header.signals_info(k).transducer_type = '';
    header.signals_info(k).physical_dimension = units{k};
    header.signals_info(k).physical_min = Pmins(k);
    header.signals_info(k).physical_max = Pmaxs(k);
    header.signals_info(k).digital_min = Dmins(k);
    header.signals_info(k).digital_max = Dmaxs(k);
    header.signals_info(k).prefiltering = prefilterings{k};
    header.signals_info(k).num_samples_datarecord = srs(k)*blockSize;
    header.signals_info(k).reserved = '';
    % NOTE: The two following are not specific EDF header fields, but are practical for EDF handling 
    header.signals_info(k).sample_rate = header.signals_info(k).num_samples_datarecord / header.duration_data_record;
    if (k > 1)
        signalOffsets(k) = signalOffsets(k - 1) + 2 * header.signals_info(k - 1).num_samples_datarecord;
    end
    header.signals_info(k).signalOffset = signalOffsets(k);
end

% Write signal-dependent header to file
for k = 1:numSignals
    fprintf(fid, '%-16s', header.signals_info(k).label);
end
for k = 1:numSignals
    fprintf(fid, '%-80s', header.signals_info(k).transducer_type);
end
for k = 1:numSignals
    fprintf(fid, '%-8s', header.signals_info(k).physical_dimension);
end
for k = 1:numSignals
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).physical_min), 8));
end
for k = 1:numSignals
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).physical_max), 8));
end
for k = 1:numSignals
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).digital_min), 8));
end
for k = 1:numSignals
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).digital_max), 8));
end
for k = 1:numSignals
    fprintf(fid, '%-80s', header.signals_info(k).prefiltering);
end
for k = 1:numSignals
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).num_samples_datarecord), 8));
end
for k = 1:numSignals
    fprintf(fid, '%-32s', header.signals_info(k).reserved);
end

% Check data starting point
current_position = ftell(fid); % in bytes
if ne(header.num_bytes_header, current_position)
    disp('Something wrong could be happening: unexpected position at the beginning of the first data block');
end

bytes_full_data_record = 2 * sum([header.signals_info.num_samples_datarecord]);

% DATA WRITING
for k = 1:numBlocks
    
    % Initialize datablock
    data = zeros(1, bytes_full_data_record/2); % Num samples per data record
        
    for k1 = 1:numSignals

        offsetSignal = (k - 1) * header.signals_info(k1).num_samples_datarecord + 1;
        onsetSignal = min(offsetSignal + header.signals_info(k1).num_samples_datarecord - 1, length(signals{k1}));
        
        offsetDataBlock = header.signals_info(k1).signalOffset/2 + 1;
        onsetDataBlock = offsetDataBlock + length(offsetSignal:onsetSignal) - 1;
        
        logConversion = strcmp(header.signals_info(k1).physical_dimension', 'Filtered');
        if logConversion
            % Parse prefiltering to set this values
            tokens = textscan(header.signals_info(k1).prefiltering, 'sign*LN[sign*(at %.1fHz)/(%.5f)]/(%.5f)(Kemp:J Sleep Res 1998-supp2:132)');
            if isempty(tokens{2})
                disp('Warning: assigned default values to logConversion');
                LogFloatY0 = 0.0001; % default value
            else
                LogFloatY0 = tokens{2};
            end
            if isempty(tokens{3})
                disp('Warning: assigned default values to logConversion');
                LogFloatA = 0.001; % default value
            else
                LogFloatA = tokens{3};
            end

            % Actual writing
            data(offsetDataBlock:onsetDataBlock) = Dmins(k1) + (Dmaxs(k1) - Dmins(k1)) * (LogFloatVector(signals{k1}(offsetSignal:onsetSignal), LogFloatY0, LogFloatA) - Pmins(k1))/(Pmaxs(k1) - Pmins(k1));
        else
            data(offsetDataBlock:onsetDataBlock) = Dmins(k1) + (Dmaxs(k1) - Dmins(k1)) * (signals{k1}(offsetSignal:onsetSignal) - Pmins(k1))/(Pmaxs(k1) - Pmins(k1));
        end
    end
    data = typecast(int16(data), 'uint16'); % From double to 16bit unsigned integers
    
    fwrite(fid, data, 'uint16');
end

statusok = (fclose(fid) == 0);
