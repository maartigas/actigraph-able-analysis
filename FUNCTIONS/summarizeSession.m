function [trials, minutesOut, bouts, summary, hrv, relations] = summarizeSession(s,A,E,T)
% Intervals semioberts [inici, fi). Cap interpolacio de fisiologia.
step = E.Steps;
covered = step.Timestamp>=A.Start & step.Timestamp<A.Stop;
n = height(step);
endWalking = lastTimer(E.Timers,"walking_time");
endStanding = lastTimer(E.Timers,"standing_time");
actiSummary = summarizeIntervals(A,E,A.Start,A.Stop);
summary = table(s.ID,A.Start,A.Stop,actiSummary.ActiWear_s,E.StartAligned,E.StopAligned, ...
    step.Timestamp(1),step.Timestamp(end),n,nnz(step.Side=="L"),nnz(step.Side=="R"), ...
    sum(covered),step.DistanceTotal_m_est(end),sum(step.StepDistance_m_est(covered)), ...
    step.total_cadence(end),step.AverageSpeed_mps_est(end),step.total_gait_symmetry(end), ...
    endWalking,endStanding, ...
    'VariableNames',["Session","ActiStart","ActiStopExclusive","Wear_s","ABLEStartAligned", ...
    "ABLEEndAligned","FirstStep","LastStep","ABLEStepsTotal","LeftSteps","RightSteps", ...
    "StepsInsideActiRecording","ABLEDistanceTotal_m_est","DistanceInsideActi_m_est", ...
    "ABLETotalCadence_spm","ABLEAverageSpeed_mps_est","ABLESymmetry_raw", ...
    "LastWalkingSnapshot_s","LastStandingSnapshot_s"]);
% El resum global inclou tots els valors numèrics d'RMSSD dins l'interval.
rmssd = A.HRV.rmssd(isfinite(A.HRV.rmssd));
hrvSummary = table(mean(rmssd),numel(rmssd), ...
    'VariableNames',["RMSSD_mean_ms","RMSSD_N"]);
summary = [summary,actiSummary(:,["HR_mean_bpm","HR_N"]),hrvSummary, ...
    actiSummary(:,["Acti_VM_mean_CPM","ActiEpochN"])];

trials = T;
trials = [trials,summarizeIntervals(A,E,T.Start,T.Stop)];

edges = unique([A.Start; A.Activity.Timestamp; A.Activity.Timestamp+seconds(60); A.Stop]);
start = edges(1:end-1);
stop = edges(2:end);
minutesOut = [table(start,stop,'VariableNames',["Start","Stop"]),summarizeIntervals(A,E,start,stop)];
minutesOut.PhaseNo = NaN(height(minutesOut),1);
minutesOut.Activity = repmat("Sense_tasca_completa",height(minutesOut),1);
for i = 1:height(minutesOut)
    match = T.Usable & T.Start<=start(i) & T.Stop>=stop(i);
    if nnz(match)==1
        minutesOut.Activity(i) = T.Activity(match);
        minutesOut.PhaseNo(i) = T.PhaseNo(match);
    end
    if nnz(match)>1, minutesOut.Activity(i) = "Tasques_solapades"; end
end
relations = describeRelations(minutesOut);

% Trams operatius: separacio per una pausa de mes de 5 s entre registres.
% No son intervals de contacte ni la metrica walking_time del firmware.
cut = [1;find(seconds(diff(step.Timestamp))>5)+1;n+1];
start = step.Timestamp(cut(1:end-1));
last = step.Timestamp(cut(2:end)-1);
bouts = [table(start,last,'VariableNames',["FirstLoggedStep","LastLoggedStep"]), ...
    summarizeIntervals(A,E,start,last+milliseconds(1))];
elapsed = seconds(last-start);
bouts.BoutSpan_s = elapsed;
bouts.CadenceBetweenSteps_spm = (bouts.ABLESteps-1)*60./elapsed;
bouts.CadenceBetweenSteps_spm(elapsed==0) = NaN;

hrv = A.HRV;
hrv.ABLESteps = NaN(height(hrv),1);
hrv.ABLEDistance_m_est = hrv.ABLESteps;
hrv.ABLECoverage_s = hrv.ABLESteps;
for i = 1:height(hrv)
    [hrv.ABLESteps(i,1),hrv.ABLEDistance_m_est(i,1),hrv.ABLECoverage_s(i,1)] = ...
        countSteps(E,hrv.start(i),hrv.("end")(i));
end
end

function v = lastTimer(t,metric)
v = NaN;
i = find(t.Metric==metric,1,"last");
if ~isempty(i), v = t.Value(i); end
end

function R = describeRelations(T)
R = table;
exos = ["ABLESteps","ABLEDistance_m_est","StepCadenceMean_spm", ...
    "StepLengthL_m_est","StepLengthR_m_est"];
actis = ["Acti_VM_mean_CPM", ...
    "HR_mean_bpm","Breathing_mean_rpm","Temperature_mean_C"];
full = T.ABLECoverage_s>=60-1e-6 & T.ActiWear_s>=60-1e-6;
for sample = ["Finestres_amb_cobertura","Finestres_amb_passes"]
    selected = full;
    if sample=="Finestres_amb_passes", selected = full & T.ABLESteps>0; end
    for x = exos
        for y = actis
            good = selected & isfinite(T.(x)) & isfinite(T.(y));
            n = nnz(good);
            r = NaN;
            if n>=5, r = pearson(T.(x)(good),T.(y)(good)); end
            R = [R; table(sample,x,y,n,r,'VariableNames',["Subset","ABLE","ActiGraph","N","Pearson_r"])];
        end
    end
end
end

