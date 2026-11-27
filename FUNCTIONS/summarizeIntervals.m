function result = summarizeIntervals(A,E,start,stop)
S = E.Steps;
fields = ["Duration_s","ABLECoverage_s","ABLESteps","StepsLeft","StepsRight", ...
    "ABLEDistance_m_est","StepsPerWindow_min","DistancePerWindow_mps_est", ...
    "StepCadenceMean_spm","StepLengthL_m_est","StepLengthR_m_est", ...
    "SwingL_s","SwingR_s","StanceL_s","StanceR_s","StepTimeL_s","StepTimeR_s", ...
    "GaitCycleL_s","GaitCycleR_s","DoubleSupportL_s","DoubleSupportR_s", ...
    "SingleSupportL_s","SingleSupportR_s","ActiWear_s","ActiEpochN","Acti_VM_mean_CPM", ...
    "HR_N","HR_mean_bpm","HR_median_bpm","HR_P95_bpm", ...
    "Breathing_N","Breathing_mean_rpm","BreathingQuality_median_raw", ...
    "Temperature_N","Temperature_mean_C","HRV_N","RMSSD_mean_ms","RMSSD_median_ms","RMSSD_N", ...
    "SDNN_median_ms","MeanNN_median_ms","pNN50_median_raw","HRVReliability_median_raw"];
v = NaN(numel(start),numel(fields));
for i = 1:numel(start)
    a = start(i);
    b = stop(i);
    if isnat(a) || isnat(b) || b<=a, continue; end
    duration_s = seconds(b-a);
    [n,distance,coverage,use] = countSteps(E,a,b);
    left = NaN;
    right = NaN;
    if coverage>0
        left = nnz(use & S.Side=="L");
        right = nnz(use & S.Side=="R");
    end
    rate = NaN;
    speed = NaN;
    if coverage>=duration_s-1e-6
        rate = 60*n/duration_s;
        speed = distance/duration_s;
    end
    gait = S{use,["cadence","step_length_left","step_length_right", ...
        "swing_time_left","swing_time_right","stance_time_left","stance_time_right", ...
        "step_time_left","step_time_right","gait_cycle_time_left","gait_cycle_time_right", ...
        "double_support_time_left","double_support_time_right", ...
        "single_support_time_left","single_support_time_right"]};
    gait(:,2:3) = gait(:,2:3)/100;
    gaitMeans = mean(gait,1,"omitmissing");

    wear = A.Wear(A.Wear.Status=="Wear",:);
    overlap_s = seconds(min(wear.Stop,b)-max(wear.Start,a));
    wear_s = sum(max(overlap_s,0));
    C = A.Activity;
    c = C.Timestamp>=a & C.Timestamp+seconds(60)<=b & C.IsWear & isfinite(C.VM_CPM);
    H = A.HR;
    h = H.timestamp>=a & H.timestamp<b & H.IsWear & isfinite(H.HeartRate);
    bpm = H.HeartRate(h);
    B = A.Breathing;
    br = B.timestamp>=a & B.timestamp<b & B.IsWear & isfinite(B.breathing_rate);
    P = A.Temperature;
    temp = P.Timestamp>=a & P.Timestamp<b & P.IsWear & isfinite(P.Temperature);
    V = A.HRV;
    hrvVars = ["rmssd","sdnn","mean_nn","pnn50"];
    hasHRV = any(isfinite(V{:,hrvVars}),2);
    hrv = V.start>=a & V.("end")<=b & V.FullWear & hasHRV;
    rmssd = V.rmssd(hrv & isfinite(V.rmssd));
    v(i,:) = [duration_s,coverage,n,left,right,distance,rate,speed,gaitMeans,wear_s, ...
        nnz(c),mean(C.VM_CPM(c),"omitmissing"),nnz(h),mean(bpm),median(bpm), ...
        percentile95(bpm),nnz(br),mean(B.breathing_rate(br)), ...
        median(B.breathing_rate_quality(br),"omitmissing"),nnz(temp),mean(P.Temperature(temp)), ...
        nnz(hrv),mean(rmssd),median(rmssd),numel(rmssd), ...
        median(V{hrv,hrvVars(2:end)},1,"omitmissing"),median(V.hrv_reliability(hrv),"omitmissing")];
end
result = array2table(v,"VariableNames",cellstr(fields));
end

function q = percentile95(x)
q = NaN;
if isempty(x), return; end
x = sort(x);
position = 1+0.95*(numel(x)-1);
q = x(floor(position))+(position-floor(position))*(x(ceil(position))-x(floor(position)));
end

