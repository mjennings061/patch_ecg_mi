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

function [result, location] = detectSTEMI_12Lead(Data)
%Expand 9 leads to 12 leads (append aVR, aVL, aVF on the end columns)
%     averageBeats = cell2mat(averageBeats);

    averageBeats = Data.signals.extract_beat_WB'; % Alinge to CM FYP code
    jPoint_n = Data.signals.jPoint_n_WB;
    sex = Data.sex;
    age = Data.age;

    Nleads = length(averageBeats(1,:));
    N = length(averageBeats(:,1));
    beats = zeros(N,13); %preallocation
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
    if(maleFemale == 0) %for males
        %% MORE THAN 40 %%
        if(age >= 40)
            %ANTERIOR (V1-V6)
            for i = 1:6 %for each lead
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
            lat = [5 6 7 11]; %indexes the above leads in jPoints
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
            inf = [8 9 12];
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
  
        %% LESS THAN 40 %%
        else %age < 40 years old
            %ANTERIOR (V1-V6)
            for i = 1:6 %for each lead
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
            lat = [5 6 7 11]; %indexes the above leads in jPoints
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
            inf = [8 9 12];
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
        for i = 1:6 %for each lead
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

        %LATERAL (I,aVL,V5,V6,-aVR)
        lat = [5 6 7 11];
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
        inf = [8 9 12];
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
    %% Return null
    if(count < 2)   %if no contigous leads detected
        result = 0; %no stemi detected
        location = "null";
        return;
    end
end
