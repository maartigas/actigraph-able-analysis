function R = summarizeTemperature(A,phases)
% Temperatura durant el repòs inicial, l'aixecament i la marxa anotada.
names = ["Repòs inicial";"Activació (sit-to-stand)";"Marxa"];
walking = ["Marxa recta","Marxa amb acompanyament","2MWT", ...
    "Pujada de rampa","Baixada de rampa","Eslàlom"];
select = [phases.PhaseNo==1 & phases.PhaseType=="Repòs / recuperació", ...
    phases.PhaseType=="Sit-to-stand",ismember(phases.PhaseType,walking)];
P = A.Temperature;
v = NaN(numel(names),2);
for k = 1:numel(names)
    inside = false(height(P),1);
    for i = find(select(:,k) & phases.Usable)'
        start = max(phases.Start(i),A.Start);
        stop = min(phases.Stop(i),A.Stop);
        inside = inside | (P.Timestamp>=start & P.Timestamp<stop);
    end
    inside = inside & P.IsWear & isfinite(P.Temperature);
    v(k,:) = [mean(P.Temperature(inside)),nnz(inside)];
end
R = [table(names,'VariableNames',{'Estat'}),array2table(v,'VariableNames', ...
    ["Temperature_mean_C","Temperature_samples_N"])];
R.Temperature_delta_vs_basal_C = R.Temperature_mean_C-R.Temperature_mean_C(1);
end
