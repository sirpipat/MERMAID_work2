function updateheader(ddirin, arrfile, evtfile, ddirout)
% UPDATEHEADER(ddirin, arrfile, evtfile, ddirout)
%
% Takes reported SAC files as an input. Then, applies firstarrival picks
% and identified earthquakes to the headers. Finally, saved SAC files with
% updated headers.
%
% INPUT:
% ddirin       directory for the original reported SAC files
% arrfile      full filename to the first arrival picks file
% evtfile      full filename to the identified earthquakes file
% ddirout      output directory for the updated SAC files
%
% It creates directories <ddirout>/<EventIDs>/ if they do not exist, and
% saves SAC files containing identifiable arrivals from an earthquake with
% EventID. It updates the following header fields:
% - T0          time of the first arrival pick 
% - KT0         name of the first arrival phase
% - AZ          azimuth
% - BAZ         back azimuth
% - DIST        epicentral distance in km
% - EVDP        earthquake depth
% - EVLA        earthquake latitude
% - EVLO        earthquake longitude
% - GCARC       epicentral distance in degrees
% - MAG         magnitude
% - STEL        elevation of the seafloor at MERMAID
% - USER4       travel time residue: pick - synthetic
% - USER5       theoretical travel time of the first arrival phase using
%               taupTime.m and ak135 model
% - USER6       Time difference between reference model with bathymetry and
%               reference model w/o bathymetry
% - USER7       IRIS event ID
% - USER8       event rupture time relatve to reference time in seconds
%
% Last modified by sirawich-at-princeton.edu, 09/13/2021

[allfiles, fndex] = gatherrecords(ddirin, [], [], 'sac', []);

[sac, eqtime, eqlat, eqlon, eqregion, eqdepth, eqdist, eqmag, ...
    eqphase1, eqid, sacdate, eqdate] = readevt2txt(evtfile, [], ...
    [], 'ALL', true);

[s, ph, dat, tres, tptime, tadj, delay, twosd, maxc_y, SNR, ID, ...
    winflag, tapflag, zerflag] = readfirstarrival(arrfile);
    

for ii = 1:fndex
    [SeisData, HdrData, ~, ~, ~] = readsac(allfiles{ii});
    [dt_ref, ~, ~, ~, ~, ~, ~] = gethdrinfo(HdrData);
    firstarrival_index = strcmp(s, removepath(allfiles{ii}));
    event_index = strcmp(sac, removepath(allfiles{ii}));
    
    % update header
    if any(firstarrival_index)
        HdrData.T0 = dat(firstarrival_index);   % first arrival time
        HdrData.KT0 = ph{firstarrival_index};   % first arrival phase
        HdrData.USER4 = tres(firstarrival_index);
        HdrData.USER5 = tptime(firstarrival_index);
        HdrData.USER6 = tadj(firstarrival_index);
    end
    if any(event_index)
        evla = eqlat(event_index);
        evlo = eqlon(event_index);
        stla = HdrData.STLA;
        stlo = HdrData.STLO;
        publicid = eqid{event_index};
        % Sometimes publicid contains '*' in front. See evt2txt.m for
        % detail.
        if strcmp(publicid(1), '*')
            publicid = publicid(2:end);
        end
        HdrData.AZ = azimuth(evla, evlo, stla, stlo);
        HdrData.BAZ = azimuth(stla, stlo, evla, evlo);
        HdrData.DIST = deg2km(eqdist(event_index));
        HdrData.EVDP = eqdepth(event_index);
        HdrData.EVLA = eqlat(event_index);
        HdrData.EVLO = eqlon(event_index);
        HdrData.GCARC = eqdist(event_index);
        HdrData.MAG = eqmag(event_index);
        HdrData.USER7 = str2double(publicid);
        dt_event = datetime(eqdate(event_index));
        HdrData.USER8 = seconds(dt_event - dt_ref);
        foldername = publicid;
    else
        foldername = 'notevent';
    end
    [lons,lats,elev,~,~] = bathymetry([], [-0.1 0.1] + HdrData.STLO, ...
        [-0.1 0.1] + HdrData.STLA, false, []);
    HdrData.STEL = interp2(lats, lons, elev, HdrData.STLA, ...
        mod(HdrData.STLO, 360));
    
    % write the updated sac file
    system(sprintf('mkdir -p %s%s', ddirout, foldername));
    sacfile = strcat(ddirout, foldername, '/', removepath(allfiles{ii}));
    writesac(SeisData, HdrData, sacfile);
end
