%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEMI classifier based on 4th Universal definition of MI j-point
%   criteria
%
% Returns result - Boolean 1 = STEMI detected; 0 = no STEMI detected
% Passed 
%     -extract_beat - N x 9 matrix with one beat. Columns are V1-V6;I-III
%     -jPoint_n - the sample number of the j-point e.g. 460
%     -sex - whether the patient is male ('m') or female ('f')
%     -age - age in years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRITERIA: (1 mm == 100uV)
% New ST-elevation at the J-point in two contiguous leads with
% the cut-point: >= 1 mm in all leads other than leads V2–V3 where
% the following cut-points apply: >= 2mm in men >= 40 years;
% <= 2.5 mm in men < 40 years, or >= 1.5 mm in women regardless
% of age
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [result, location] = detectSTEMI_12Lead_STdep(Data)

    averageBeats = Data.signals.extract_beat_WB'; % Alinge to CM FYP code
    jPoint_n = Data.signals.jPoint_n_WB;
    sex = Data.sex;
    age = Data.age;

    %Expand 9 leads to 12 leads (append aVR, aVL, aVF on the end columns)
    Nleads = length(averageBeats(1,:));
    N = length(averageBeats(:,1));
    beats = zeros(N,12); %preallocation
    beats(:,1:9) = averageBeats; 
    beats(:,10) = -(0.5)*(beats(:,7) + beats(:,8));  %aVR = -(1/2)(I + II)
    beats(:,11) = beats(:,7) - 0.5*beats(:,8);  %aVL = I – (1/2) II
    beats(:,12) = beats(:,8) - beats(:,7);  %aVF = II – (1/2)I

    % get the j points for all leads (including augmented leads)
    jPoints = zeros(1,12);
    for i = 1:12
        jPoints(i) =  beats(jPoint_n(i),i);
    end
   
    %Convert male/female into a binary (0 for male, 1 for female)
    if(sex == 'm')
        maleFemale = 0;
    elseif(sex == 'f')
        maleFemale = 1;
    end
    
    %% STEMI CRITERIA %%
    count = 0;
    % column numbers for each vessel
    ant = [1 2 3 4 5 6]; % (V1-V6)
    lat = [5 6 7 11];   % (V5 V6 I aVL)
    inf = [8 9 12]; % (II III aVF)
    
    if(maleFemale == 0) %for males
        %% MORE THAN 40
        if(age >= 40)
            %ANTERIOR (V1-V6)
            for i = 1:length(ant) %for each lead
                if(i==2 || i==3) %V2/V3
                    if(jPoints(i) >= 200e-3) %200uV
                        count = count+1;    %STE present leads +1
                        continue;
                    end
                elseif(jPoints(i) >= 100e-3) %100uV
                    count = count+1;    %STE present leads +1
                    continue;
                end
            end
            if(count > 1)   %if 2 contiguous leads
                result = 1; %STEMI detected
                location = "Anterior";
                return;
            else
                count=0; %else reset the count to 0
            end
            
            %LATERAL (I,aVL,V5,V6,-aVR)
            for i = 1:length(lat) %for each lead
                if(jPoints(lat(i)) >= 100e-3) %100uV
                    count = count+1;    %STE present leads +1
                    continue;
                end
            end
            if(count > 1)   %if 2 contiguous leads
                result = 1; %STEMI detected
                location = "Lateral";
                return;
            else
                count=0;    %else reset the count to 0
            end
            
            %INFERIOR (II,III,aVF,-aVR)
            for i = 1:length(inf) %for each lead
                if(jPoints(inf(i)) >= 100e-3) %100uV
                    count = count+1;    %STE present leads +1
                    continue;
                end
            end
            if(count > 1)   %if 2 contiguous leads
                result = 1; %STEMI detected
                location = "Inferior";
                return;
            else
                count=0;    %else reset the count to 0
            end
  
        %% LESS THAN 40
        else %age < 40 years old
            %ANTERIOR (V1-V6)
            for i = 1:length(ant) %for each lead
                if(i==2 || i==3) %V2/V3
                    if(jPoints(i) >= 250e-3) %200uV
                        count = count+1;
                        continue;
                    end
                elseif(jPoints(i) >= 100e-3) %100uV
                    count = count+1;
                    continue;
                end
            end
            if(count > 1)
                result = 1;
                location = "Anterior";
                return;
            else
                count=0;
            end
            
            %LATERAL (I,aVL,V5,V6,-aVR)
            for i = 1:length(lat) %for each lead
                if(jPoints(lat(i)) >= 100e-3) %100uV
                    count = count+1;
                    continue;
                end
            end
            if(count > 1)
                result = 1;
                location = "Lateral";
                return;
            else
                count=0;
            end
            
            %INFERIOR (II,III,aVF,-aVR)
            for i = 1:length(inf) %for each lead
                if(jPoints(inf(i)) >= 100e-3) %100uV
                    count = count+1;
                    continue;
                end
            end
            if(count > 1)
                result = 1;
                location = "Inferior";
                return;
            else
                count=0;
            end
        end
    %% FOR FEMALES %%
    else
        %ANTERIOR (V1-V6)
        for i = 1:length(ant) %for each lead
            if(i==2 || i==3) %V2/V3
                if(jPoints(i) >= 150e-3) %200uV
                    count = count+1;
                    continue;
                end
            elseif(jPoints(i) >= 100e-3) %100uV
                count = count+1;
                continue;
            end
        end
        if(count > 1)
            result = 1;
            location = "Anterior";
            return;
        end

        %LATERAL (I,aVL,V5,V6)
        for i = 1:length(lat) %for each lead
            if(jPoints(lat(i)) >= 100e-3) %100uV
                count = count+1;
                continue;
            end
        end
        if(count > 1)
            result = 1;
            location = "Lateral";
            return;
        else 
            count=0;
        end

        %INFERIOR (II,III,aVF)
        for i = 1:length(inf) %for each lead
            if(jPoints(inf(i)) >= 100e-3) %100uV
                count = count+1;
                continue;
            end
        end
        if(count > 1)
            result = 1;
            location = "Inferior";
            return;
        else
            count=0;
        end
    end
    
    %% ST depression with T-wave criteria
    dep = 50e-3; %amount of depression required in mV (high number means not required)
    % get the ST-segment
    st_seg_n = jPoint_n + 40; % get the Jpoint sample no at J+40ms for fs=1000Hz
    st_seg = zeros(12,1);
    for i = 1:12
        st_seg(i) =  beats(st_seg_n(i),i);   
    end
    
    % get the R, S, T wave peaks
    rWave_n = Data.signals.RWave_n_WB;
    sWave_n = Data.signals.SWave_n_WB;
    tWave_n = Data.signals.TWave_n_WB;
    [r_peaks, s_peaks, t_peaks] = deal(zeros(12,1));    % preallocation
    for lead = 1:12
        r_peaks(lead) = beats(rWave_n(lead), lead);
        s_peaks(lead) = beats(sWave_n(lead), lead);
        t_peaks(lead) = beats(tWave_n(lead), lead);
    end
    
    
    %ANTERIOR (V1-V6)
    t_criteria = [];
    count_T = 0;
    for i = 1:length(ant) %for each lead
        if(st_seg(i) <= -dep) %50uV depression
            count = count+1;
            continue;
        end
        % is t_peaks inverted (sign() = -1 for inverted)
        t_criteria(1,i) = sign(t_peaks(i)) < 0;
        % t_peaks is larger than 100uV (1mm)
        t_criteria(2,i) = (abs(t_peaks(i)) >= 100e-3);
        % "prominent" R-peak
        t_criteria(3,i) = ( abs(r_peaks(i)) >= 1.3*abs(t_peaks(i)));
         % R/S ratio > 1
        t_criteria(4,i) = (abs(r_peaks(i))/abs(s_peaks(i)) > 1);   
        % t_peaks inverted AND t_peaks larger than 100uV AND (prominent R-peak OR R/S > 1)
        t_criteria(5,i) = t_criteria(1,i) && t_criteria(2,i) && (t_criteria(3,i) || t_criteria(4,i));
        if t_criteria(5,i)
            count_T = count_T + 1;
        end
    end
    if(count > 1)
        if(count_T > 0)
            result = 1;
            location = "Anterior Depression";
            return;
        else
            count=0;
        end
    else
        count=0;
    end

    %LATERAL (I,aVL,V5,V6)
    t_criteria = [];
    count_T = 0;
    for i = 1:length(lat) %for each lead
        if(st_seg(lat(i)) <= -dep) %50uV depression
            count = count+1;
            continue;
        end
        % is t_peaks inverted (sign() = -1 for inverted)
        t_criteria(1,i) = sign(t_peaks(lat(i))) < 0;
        % t_peaks is larger than 100uV (1mm)
        t_criteria(2,i) = (abs(t_peaks(lat(i))) >= 100e-3);
        % "prominent" R-peak
        t_criteria(3,i) = (abs(r_peaks(lat(i))) >= 1.3*abs(t_peaks(lat(i))));
         % R/S ratio > 1
        t_criteria(4,i) = (abs(r_peaks(lat(i)))/abs(s_peaks(lat(i))) > 1);   
        % t_peaks inverted AND t_peaks larger than 100uV AND (prominent R-peak OR R/S > 1)
        t_criteria(5,i) = t_criteria(1,i) && t_criteria(2,i) && (t_criteria(3,i) || t_criteria(4,i));
        if t_criteria(5,i)
            count_T = count_T + 1;
        end
    end
    if(count > 1)
        if(count_T > 0)
            result = 1;
            location = "Lateral Depression";
            return;
        else
            count=0;
        end
    else
        count=0;
    end

    %INFERIOR (II,III,aVF)
    t_criteria = [];
    count_T = 0;
    for i = 1:length(inf) %for each lead
        if(st_seg(inf(i)) <= -dep) %50uV depression
            count = count+1;
            continue;
        end
        % is t_peaks inverted (sign() = -1 for inverted)
        t_criteria(1,i) = sign(t_peaks(inf(i))) < 0;
        % t_peaks is larger than 100uV (1mm)
        t_criteria(2,i) = (abs(t_peaks(inf(i))) >= 100e-3);
        % "prominent" R-peak
        t_criteria(3,i) = ( abs(r_peaks(inf(i))) >= 1.3*abs(t_peaks(inf(i))));
         % R/S ratio > 1
        t_criteria(4,i) = (abs(r_peaks(inf(i)))/abs(s_peaks(inf(i))) > 1);   
        % t_peaks inverted AND t_peaks larger than 100uV AND (prominent R-peak OR R/S > 1)
        t_criteria(5,i) = t_criteria(1,i) && t_criteria(2,i) && (t_criteria(3,i) || t_criteria(4,i));
        if t_criteria(5,i)
            count_T = count_T + 1;
        end
    end
    if(count > 1)
        if(count_T > 0)
            result = 1;
            location = "Inferior Depression";
            return;
        else
            count=0;
        end
    else
        count=0;
    end

    %% Return null
    if(count < 2)   %if no contigous leads detected
        result = 0; %no stemi detected
        location = "null";
        return;
    end
end