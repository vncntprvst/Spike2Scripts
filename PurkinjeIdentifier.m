

% Variables from Spike2, uncomment for debugging
% clear;clc;close all;
% ssclus = 1;
% timelength = 1377.2587563;
% directory = 'E:\Data\Recordings\Resorted Files\';
% tsamp = 2e-5;

if strcmp(getenv('username'),'DangerZone')
        directory = 'E:\data\Recordings\';
    elseif strcmp(getenv('username'),'Radu')
        directory = 'E:\Spike_Sorting\';
    elseif strcmp(getenv('username'),'The Doctor')
        directory = 'C:\Users\The Doctor\Data\';
    elseif strcmp(getenv('username'),'JuanandKimi') || ...
            strcmp(getenv('username'),'Purkinje')
        directory = 'C:\Data\Recordings\';
    else
        directory = 'B:\data\Recordings\';
end

cd([directory, 'spike2temp\']);

load('postss.mat'); % post simple spike data


tn1 = whos; % temporary name holder
tn2 = tn1.name;

eval(['datastr = ', tn2,';']); % get data as a struct
data = datastr.values;
data = data';

Fsamp = tsamp^(-1);
data_fft = fft(data);
[rws,cls] = size(data_fft);


mynewlabels = ones(1,cls).*double(ssclus);
        
whatttodo = 'fft_sum_pauses';
switch whatttodo
    case 'fft_max_1hz'
        % Assuming average complex spike firing is at 1 Hz, their number
        % should equal the number of seconds in the recording. We identify
        % the spikes with the largest amplitude of the fft as these spikes.
        
        data_fft_amp = abs(data_fft(1:(floor(rws/2)+1),:)); %get fft amplitudes for positive frequencies
        
        freqs = linspace(0,Fsamp/2,(floor(rws/2)+1)); % get x axis of frequencies
        llim = find(freqs > 0); llim = llim(1); % find first nonzero freq
        rlim = find(freqs < 5000); rlim = rlim(end); % find last freq under 5000
        
        data_fft_amp = data_fft_amp(llim:rlim,:); % isolate those amplitudes: each column is a spike, each row is a frequency
        
        data_fft_maxes = max(data_fft_amp); % find maximum amplitude across frequencies
        [count_maxes,bin_centers] = hist(data_fft_maxes,1000); % divide into 1000 bins

        timelength = round(timelength); % how many seconds in the recording
        cutoff = sum(count_maxes)-timelength; %how many spikes to treat as simple

        cumul_hist = cumsum(count_maxes); % as spikes accumulate in increasing order of max_fft, we will cross the cutoff eventually

       figure(1);
       plot(bin_centers(count_maxes ~= 0),count_maxes(count_maxes ~= 0),'ko');
       hold on;
       plot(bin_centers(cumul_hist>cutoff),count_maxes(cumul_hist>cutoff),'r+');

        fft_cutoff = bin_centers(cumul_hist>cutoff); % which frequency corresponds to crossing the cuttof?
        fft_cutoff = fft_cutoff(1);
        
        mynewlabels(data_fft_maxes >= fft_cutoff) = ssclus+30; % assign new names
    
    case 'fft_sum_3sd'
        
        data_fft_amp = abs(data_fft(1:(floor(rws/2)+1),:)); %get fft amplitudes for positive frequencies
        
        freqs = linspace(0,Fsamp/2,(floor(rws/2)+1));% get x axis of frequencies
        llim = find(freqs > 0); llim = llim(1); % find first nonzero freq
        rlim = find(freqs < 4000); rlim = rlim(end); % find last freq under 4000
        
        data_fft_amp = data_fft_amp(llim:rlim,:); % isolate those amplitudes: each column is a spike, each row is a frequency
        
        data_fft_sum = sum(data_fft_amp); % sum the amplitudes, as a proxy for energy
        
        [muhat,sigmahat] = normfit(data_fft_sum'); % standard deviation
        cutoff = muhat+sigmahat;
        
        histo = hist(data_fft_sum,100);
        hist(data_fft_sum,100);
        hold on;
        plot([cutoff cutoff],[0 max(histo)],'r--','LineWidth',5);
        xlabel('Energy below 4 kHz');
        mynewlabels(data_fft_sum >= cutoff) = ssclus+30;
        
    case 'fft_sum_pauses'
        
        data_fft_amp = abs(data_fft(1:(floor(rws/2)+1),:)); %get fft amplitudes for positive frequencies
        
        freqs = linspace(0,Fsamp/2,(floor(rws/2)+1));% get x axis of frequencies
        llim = find(freqs > 0); llim = llim(1); % find first nonzero freq
        rlim = find(freqs < 4000); rlim = rlim(end); % find last freq under 4000
        
        data_fft_amp = data_fft_amp(llim:rlim,:); % isolate those amplitudes: each column is a spike, each row is a frequency
        
        data_fft_sum = sum(data_fft_amp); % sum the amplitudes, as a proxy for energy
        
        [muhat,sigmahat] = normfit(data_fft_sum'); % standard deviation
        cutoff = muhat+sigmahat;
        
        pauses = [diff(datastr.times); 0];
        [muhat,sigmahat] = normfit(pauses');
        pauses_cutoff = 0.01; % in ms
        
        figure();
        hold on;
        scatter(pauses,data_fft_sum,'bo');
        xlabel('pauses');
        ylabel('Energy below 4 kHz');
        mask = pauses' >= pauses_cutoff & data_fft_sum >= cutoff;
        
        mynewlabels(mask) = ssclus+30;
        hold on;
        scatter(pauses,data_fft_sum,'bo');
        scatter(pauses(mynewlabels == 31),data_fft_sum(mynewlabels == 31),'r+');
        
        figure();
        histo = hist(data_fft_sum,100);
        hist(data_fft_sum,100);
        hold on;
        plot([cutoff cutoff],[0 max(histo)],'r--','LineWidth',5);
        xlabel('Energy below 4 kHz');
        figure;
        histo = hist(pauses,100);
        hist(pauses,100);
        hold on;
        plot([pauses_cutoff pauses_cutoff],[0 max(histo)],'r--','LineWidth',5);
        xlabel('Pause to next spike');
        
    case 'fft_pauses'
        
        pauses = diff(datastr.times)'; % how much time after each spike until the next?
        data_fft_amp = abs(data_fft(1:(floor(rws/2)+1),1:end-1)); %get fft amplitudes for positive frequencies
        
        freqs = linspace(0,Fsamp/2,(floor(rws/2)+1));% get x axis of frequencies
        llim = find(freqs > 0); llim = llim(1); % find first nonzero freq
        rlim = find(freqs < 4000); rlim = rlim(end); % find last freq under 4000
        
        data_fft_amp = data_fft_amp(llim:rlim,:); % standard deviation
        
        data_fft_maxes = max(data_fft_amp); % max of fft amplitude in that range
        
        [muhat,sigmahat] = normfit(data_fft_maxes');
        cutoff = muhat+4*sigmahat;
        
        [count_maxes,bin_centers] = hist(data_fft_maxes,1000);
        
        figure(1);
        plot(bin_centers(count_maxes ~= 0),count_maxes(count_maxes ~= 0),'ko');
        hold on;
        plot(bin_centers(bin_centers>cutoff),count_maxes(bin_centers>cutoff),'r+');
        
        figure(2);
        plot(data_fft_maxes(data_fft_maxes>=cutoff),pauses(data_fft_maxes>=cutoff),'r*');
        hold on;
        plot(data_fft_maxes,pauses,'ko');
        xlabel('FFT amplitudes');
        ylabel('Pause lengths');
        mynewlabels(data_fft_maxes >= cutoff) = ssclus+30;
    
    case 'pauses'
        
        pauses = diff(datastr.times);
        [muhat,sigmahat] = normfit(pauses');
        cutoff = muhat+4*sigmahat;
        
        [count_maxes,bin_centers] = hist(pauses,1000);
        
        figure(1);
        plot(bin_centers(count_maxes ~= 0),count_maxes(count_maxes ~= 0),'ko');
        hold on;
        plot(bin_centers(bin_centers>cutoff),count_maxes(bin_centers>cutoff),'r+');
        
        mynewlabels(pauses >= cutoff) = ssclus+30;
        
    case 'normal_mixtures'
        
        % Calculate the first 3 principal components of the time series
        % data => 3 shape features
        
        % Calculate the energy of the signal => 1 feature
         energies = sum(data.^2)./tsamp; energies = energies';
        energies = energies./max(energies);
        [muhat,sigmahat] = normfit(energies');
        energy_cutoff = muhat+sigmahat;
        % Calculate the percent of the energy in low frequencies as opposed
        % to high. Problem: define low frequency. 1 feature
        
        % Calculate time to next spike. 1 feature.
         pauses = diff(datastr.times); pauses = [pauses; 0];
        pauses = pauses./max(pauses);
        [muhat,sigmahat] = normfit(pauses');
        pauses_cutoff = muhat+sigmahat;
        
        hold on;
        scatter(pauses,energies,'bo');
        xlabel('pauses');
        ylabel('energies');
        mask = pauses >= pauses_cutoff & energies >= energy_cutoff;
        mynewlabels(mask) = ssclus+30;
        hold on;
        scatter(pauses,energies,'bo');
        scatter(pauses(mynewlabels == 31),energies(mynewlabels == 31),'r+');
    otherwise %fft_max_sd
        
        data_fft_amp = abs(data_fft(1:(floor(rws/2)+1),:)); %get fft amplitudes for positive frequencies
        
        freqs = linspace(0,Fsamp/2,(floor(rws/2)+1));% get x axis of frequencies
        llim = find(freqs > 0); llim = llim(1); % find first nonzero freq
        rlim = find(freqs < 4000); rlim = rlim(end); % find last freq under 4000
        
        data_fft_amp = data_fft_amp(llim:rlim,:);
        
        data_fft_maxes = max(data_fft_amp);
        
        [muhat,sigmahat] = normfit(data_fft_maxes');
        cutoff = muhat+2*sigmahat;
        
        mynewlabels(data_fft_maxes >= cutoff) = ssclus+30;
        
        histo = hist(data_fft_maxes,100);
        hist(data_fft_maxes,100);
        hold on;
        plot([cutoff cutoff],[0 max(histo)],'r--','LineWidth',5);
        xlabel('Maximum power below 4 kHz');
        
end

% Display pause diagram
figure();
pausediagram(datastr.times, mynewlabels);