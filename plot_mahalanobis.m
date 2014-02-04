function [ out ] = plot_mahalanobis(in, temp_size, start_offset, pulse_clus,comps)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
load(in);
eval('dataname = who;');
eval(['data = ', dataname{1}]);

cluscodes = double(data.codes(:,1)); % vector listing codes for each waveform
clusnames = unique(cluscodes);  % list of all distinct names
clusnames(clusnames == 0) = []; % we need code 0 in here for PCA, but will not examine

if pulse_clus ~= 0
    clusnames(clusnames == pulse_clus) = []; % take out the tms artifact
end

trigs = [start_offset start_offset+temp_size]; % what part of the full waveform to do PCA on
pc_values = data.values(:,trigs(1):trigs(2)); % truncate the waveform for PCA
[coeff, score] = princomp(pc_values); % scores and components


clus = cell(length(clusnames),1); % will hold times and PCA scores for each cluster
gauss_fits = cell(length(clusnames),1); % will hold the parameters of
                                        % the multivariate gaussian
                                        % approximating the clusters
score_mask = ismember(1:size(score,2),comps); % which components are we using?
                                              % i.e., which component space
                                              % to calculate mahalanobis
                                              % distance in
a = 1;
for a = 1:length(clusnames) % populate clus with times and PCA scores for each cluster
    b = clusnames(a); % current cluster name
    clus{a} = struct('times',data.times(cluscodes == b),... % times of that clus
        'scores', score(cluscodes == b,score_mask),'mahal_distance',[]);
    gauss_fits{a} = gmdistribution.fit(clus{a}.scores(:,score_mask),1); % multivariate fit to that cluster
    clus{a}.mahal_distance = mahal(gauss_fits{a},clus{a}.scores);    % calculate distances from data points to center of fit
end

for a = 1:length(clusnames)
    figure();
    whichtoplot = randi(size(clus{a}.scores,1),1,5000); % only plot 5000 data points, for speed
    if length(comps) == 2 % if there are only 2 components, we can plot a contour of them.
        subplot(1,2,1);
        scatter(clus{a}.scores(whichtoplot,1),clus{a}.scores(whichtoplot,2),5,'k.');
        hold on;
        x_limits = [gauss_fits{a}.mu(1)-4.*sqrt(gauss_fits{a}.Sigma(1,1)) gauss_fits{a}.mu(1)+4.*sqrt(gauss_fits{a}.Sigma(1,1))];
        % 4 standard deviations on either side of the mean
        y_limits = [gauss_fits{a}.mu(2)-4.*sqrt(gauss_fits{a}.Sigma(2,2)) gauss_fits{a}.mu(2)+4.*sqrt(gauss_fits{a}.Sigma(2,2))];
    
        h = ezcontour(@(x,y)pdf(gauss_fits{a},[x y]),x_limits,y_limits);
        subplot(1,2,2);
    end
    % plot distance from center over time.
    scatter(clus{a}.times, clus{a}.mahal_distance, 5, 'k.');
    hold on;
end

end