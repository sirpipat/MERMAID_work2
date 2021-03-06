function r = presiduestat(sacfiles, plt)
% r = presiduestat(sacfiles, plt)
% 
% Compute the residual times between the pick arrvial and the assigned
% arrival time for P-phase. The arivals are picked by finding the first
% incident when the absolute signal exceeds 2 percent of the maximum of the
% absolute of the signal within 30 seconds centered at the assigned
% arrival.
%
% INPUT:
% sacfiles      cell array to SAC files
% plt           whether to plot the picks and the stat or not
%
% OUTPUT:
% r             residuals
%
% Last modified by sirawich-at-princeton.edu, 01/17/2022

n = length(sacfiles);
r = zeros(size(sacfiles));

for ii = 1:n
    % read the sac file
    [x, HdrData] = readsac(sacfiles{ii});
    
    % gets the information from SAC header
    [dt_ref, dt_B, dt_E, fs, npts, dts, tims] = gethdrinfo(HdrData);
    t = seconds(tims - tims(1));
    
    % detect P-phase
    phaseNum = 0;
    phaseTime = HdrData.T0;
    phaseName = HdrData.KT0;
    
    while (~strcmpi(phaseName, 'P') && ~strcmpi(phaseName, 'PKP') && ...
            ~strcmp(phaseName, 'PKIKP') && ...
            ~strcmpi(phaseName, 'Pdiff')) && phaseTime == -12345 && ...
            phaseNum < 10
        phaseNum = phaseNum + 1;
        switch phaseNum
            case 1
                phaseTime = HdrData.T1;
                phaseName = HdrData.KT1;
            case 2
                phaseTime = HdrData.T2;
                phaseName = HdrData.KT2;
            case 3
                phaseTime = HdrData.T3;
                phaseName = HdrData.KT3;
            case 4
                phaseTime = HdrData.T4;
                phaseName = HdrData.KT4;
            case 5
                phaseTime = HdrData.T5;
                phaseName = HdrData.KT5;
            case 6
                phaseTime = HdrData.T6;
                phaseName = HdrData.KT6;
            case 7
                phaseTime = HdrData.T7;
                phaseName = HdrData.KT7;
            case 8
                phaseTime = HdrData.T8;
                phaseName = HdrData.KT8;
            case 9
                phaseTime = HdrData.T9;
                phaseName = HdrData.KT9;
            otherwise
                break
        end
    end
    
    % pick the arrival based on the rise of the signal
    wh = and(t - phaseTime > -15, t - phaseTime < 15);
    t_wh = t(wh);
    x_wh = x(wh);
    
    arrival = indeks(t_wh(abs(x_wh) > 2e-2 * max(abs(x_wh))), 1);
    r(ii) = arrival - phaseTime;
    
    if plt && false
        if HdrData.USER7 == -12345
            HdrData.USER7 = ii;
        end
        plotsac2(x, HdrData, 'Color', 'k');
        
        % add the pick arrival
        fig = gcf;
        ax = fig.Children(2);
        hold on
        vline(ax, r(ii), 'LineWidth', 1, 'LineStyle', '-.', 'Color', [0.1 0.4 0.9]);
        hold off
        legend(ax.Children(1:2), 'pick', 'ak135', 'Location', 'northwest')
        
        savename = sprintf('%s_seis_%d_%s.eps', mfilename, ...
            HdrData.USER7, replace(HdrData.KSTNM, ' ', ''));
        figdisp(savename,[],[],2,[],'epstopdf');
        delete(fig)
    end
end

if plt
    figure
    histogram(r, 'BinWidth', 0.5, 'FaceColor', [0.75 0.75 0.75])
    hold on
    [~,v1] = vline(gca, mean(r), 'Color', 'k', 'LineWidth', 1.5, 'LineStyle', '-.');
    [~,v2] = vline(gca, median(r), 'Color', 'r', 'LineWidth', 1.5, 'LineStyle', '--');
    [~,v3] = vline(gca, median(r) + std(r) * [-1 1], 'Color', [0.1 0.4 0.9], 'LineWidth', 1.5, 'LineStyle', '--');
    grid on
    set(gca, 'FontSize', 12, 'TickDir', 'both');
    xlabel('residual (s)')
    ylabel('counts')
    title(sprintf('n = %d, mean = %.2f, median = %.2f, std = %.2f', n, mean(r), median(r), std(r)));
    legend([v1 v2 v3(1)], 'mean', 'median', '1 std from median')
    
    set(gcf, 'Renderer', 'painters')
    savename = sprintf('%s_histogram.eps', mfilename);
    figdisp(savename,[],[],2,[],'epstopdf');
end
end