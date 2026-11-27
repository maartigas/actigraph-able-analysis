function [G,phasePct] = summarizeStraightGait(s,E,trials,bouts)
% Resum dels trams de marxa. El pacient utilitza les franges del resum visual.
walk = trials.Usable & ismember(trials.PhaseType,["Marxa recta","2MWT"]);
T = sortrows(trials(walk,:),"Start");
if s.ID=="Pacient"
    drawn = ~isnat(T.FigureStart) & ~isnat(T.FigureStop) & T.FigureStop>T.FigureStart;
    T = sortrows(T(drawn,:),"FigureStart");
    T.Start = T.FigureStart;
    T.Stop = T.FigureStop;
end
n = height(T);
labels = "Marxa contínua "+string((1:n)');
if s.ID=="Investigadora"
    tests = T.PhaseType=="2MWT";
    labels(~tests) = "Marxa contínua";
    labels(tests) = "2 Minute Walk Test "+string((1:nnz(tests))');
end

elapsed = seconds(T.Stop-T.Start);
stepN = NaN(n,1);
distance = NaN(n,1);
coverage = NaN(n,1);
for i = 1:n
    [stepN(i),distance(i),coverage(i)] = countSteps(E,T.Start(i),T.Stop(i));
end
speed = distance./elapsed;
cadence = 60*stepN./elapsed;
incomplete = coverage<elapsed-1e-6;
speed(incomplete) = NaN;
cadence(incomplete) = NaN;
stepLength = distance./stepN;
stepLength(stepN==0) = NaN;
G = table(labels,T.PhaseNo,T.FigurePhaseNo,T.Activity,T.Start,T.Stop,elapsed,coverage, ...
    stepN,distance,speed,cadence,stepLength, ...
    NaN(n,1),NaN(n,1),NaN(n,1),zeros(n,1),zeros(n,1), ...
    'VariableNames',["Tram","Fase_registre","Fase_grafic","Activitat_registre","Inici","Fi", ...
    "Temps_s","Cobertura_ABLE_s","Passes","Distancia_m_est","Velocitat_m_s_est", ...
    "Cadencia_passes_min","Longitud_passa_m_est","Suport_s","Balanceig_s", ...
    "Doble_suport_s","Cicles_E","Cicles_D"]);
phasePct = NaN(n,4,2);
if n==0, return; end

C = firmwareCycles(E.Steps,bouts.FirstLoggedStep);
sides = ["L","R"];
for i = 1:n
    inTrial = C.Start>=T.Start(i) & C.Stop<T.Stop(i);
    durations = C.Phases_s(inTrial,:);
    G.Suport_s(i) = mean(sum(durations(:,1:3),2));
    G.Balanceig_s(i) = mean(durations(:,4));
    G.Doble_suport_s(i) = mean(sum(durations(:,[1 3]),2));
    G.Cicles_E(i) = nnz(inTrial & C.Side=="L");
    G.Cicles_D(i) = nnz(inTrial & C.Side=="R");
    for leg = 1:2
        legCycles = C.Phases_s(inTrial & C.Side==sides(leg),:);
        phasePct(i,:,leg) = mean(100*legCycles./sum(legCycles,2),1);
    end
end

meanRow = G(1,:);
meanRow.Tram = "Mitjana";
meanRow.Activitat_registre = "Mitjana dels trams";
meanRow.Fase_registre = NaN;
meanRow.Fase_grafic = NaN;
meanRow.Inici(:) = NaT;
meanRow.Fi(:) = NaT;
meanRow{1,["Cicles_E","Cicles_D"]} = [NaN NaN];
metrics = ["Temps_s","Cobertura_ABLE_s","Passes","Distancia_m_est","Velocitat_m_s_est", ...
    "Cadencia_passes_min","Longitud_passa_m_est","Suport_s","Balanceig_s","Doble_suport_s"];
meanRow{1,metrics} = mean(G{:,metrics},1,"omitnan");
G = [G;meanRow];
phasePct = [phasePct;mean(phasePct,1,"omitnan")];
end

function C = firmwareCycles(S,boutStarts)
% Cicle entre tres registres alterns del mateix tram operatiu (E-D-E o D-E-D).
bout = cumsum(ismember(S.Timestamp,boutStarts));
last = (3:height(S))';
last = last(S.Side(last)==S.Side(last-2) & S.Side(last)~=S.Side(last-1) ...
    & bout(last)==bout(last-2));

legs = ["left","right"];
sides = ["L","R"];
C = table;
for leg = 1:2
    same = legs(leg);
    opposite = legs(3-leg);
    finish = last(S.Side(last)==sides(leg));
    middle = finish-1;
    % El registre de la passa contrària conté el suport del costat del cicle.
    phases = [S{middle,"double_support_time_"+same},S{middle,"single_support_time_"+same}, ...
        S{finish,"double_support_time_"+opposite},S{finish,"swing_time_"+same}];
    stance = S{finish,"stance_time_"+same};
    cycle = S{finish,"gait_cycle_time_"+same};
    valid = all(isfinite(phases) & phases>=0,2) & cycle>0 ...
        & abs(sum(phases(:,1:3),2)-stance)<1e-6 & abs(sum(phases,2)-cycle)<1e-6;
    finish = finish(valid);
    C = [C;table(S.Timestamp(finish-2),S.Timestamp(finish),S.Side(finish),phases(valid,:), ...
        'VariableNames',["Start","Stop","Side","Phases_s"])];
end
end
