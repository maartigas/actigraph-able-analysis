function plotSession(folder,s,A,T,phases,gait,phasePct)
% Resum de sessió de cinc panells i fases mitjanes del cicle de marxa.
types = ["Repòs / recuperació","Sit-to-stand","Stand-to-sit","Pausa / ajustos", ...
    "Marxa recta","Gir de 90°","Gir de rampa","Gir","Pujada de rampa", ...
    "Baixada de rampa","Eslàlom","Porta manual","Ascensor","2MWT", ...
    "Marxa amb acompanyament","Altres"];
colors = [0.43 0.47 0.53; 0.35 0.56 0.66; 0.46 0.39 0.55; 0.61 0.51 0.42; ...
    0.11 0.44 0.73; 0.59 0.31 0.69; 0.38 0.53 0.14; 0.47 0.38 0.56; ...
    0.11 0.58 0.36; 0.86 0.44 0.12; 0.76 0.29 0.42; 0.45 0.28 0.15; ...
    0.17 0.64 0.65; 0.73 0.51 0.11; 0.37 0.33 0.66; 0.55 0.57 0.58];
legendLabels = ["Rest / recovery","Sit-to-stand","Stand-to-sit","Pause / adjustments", ...
    "Straight walking","90° turn","Ramp turn","Turn","Ramp ascent", ...
    "Ramp descent","Slalom","Manual door","Lift","2MWT","Accompanied walking","Other"];
if s.ID=="Investigadora"
    legendLabels(types=="Gir de rampa") = "180° turn (ramp)";
elseif s.ID=="Pacient"
    legendLabels(types=="Marxa recta") = "Straight / continuous walking";
end
% Veerubhotla et al. (2020), canell dominant en usuaris de cadira manual amb LM.
% Referència exploratòria per a les dues sessions amb ABLE. PMID 32502566.
thresholds = [2057 11551];

x = minutes(T.Start-A.Start);
last = minutes(A.Stop-A.Start);
drawn = phases.Usable & ~isnat(phases.FigureStart) & ~isnat(phases.FigureStop);
phases = sortrows(phases(drawn,:),"PhaseNo");
phaseStart = max(0,minutes(phases.FigureStart-A.Start));
phaseStop = min(last,minutes(phases.FigureStop-A.Start));
shown = phaseStop>phaseStart;
phaseTypes = phases.PhaseType(shown);
phaseTypes(phaseTypes=="Gir de 180° (rampa)") = "Gir de rampa";
if s.ID=="Pacient"
    phaseTypes(phaseTypes=="2MWT") = "Marxa recta";
end
[~,kind] = ismember(phaseTypes,types);
phaseStart = phaseStart(shown);
phaseStop = phaseStop(shown);
phaseNo = phases.FigurePhaseNo(shown);

steps = T.ABLESteps;
steps(T.ABLECoverage_s<T.Duration_s-1e-6) = NaN;
series = [steps,T.DistancePerWindow_mps_est,T.HR_mean_bpm,T.Acti_VM_mean_CPM,T.Temperature_mean_C];
units = ["ABLE steps / 60 s","ABLE speed (m/s, est.)", ...
    "Heart rate (bpm)","Wrist activity (counts/min)","Skin temperature (°C)"];
if any(abs(T.Duration_s-60)>1e-6)
    units(1) = "ABLE steps / interval";
end
timeLabel = "Time (min)";
ink = [0.05 0.27 0.47];

fig = figure("Visible","off","Color","white","Position",[90 90 1450 1300]);
cleanup = onCleanup(@() close(fig));
L = tiledlayout(fig,5,1,"TileSpacing","compact","Padding","loose");
ax = gobjects(5,1);
for k = 1:5
    ax(k) = nexttile(L);
    hold(ax(k),"on");
    grid(ax(k),"on");
    y = series(:,k);
    valid = y(isfinite(y));
    lo = 0;
    hi = max([valid*1.10;0.01]);
    if k==3 && ~isempty(valid)
        lo = floor(min(valid)/10)*10-5;
        hi = max(valid)+5;
    elseif k==5
        lo = 0;
        hi = 1;
        if ~isempty(valid)
            lo = min(valid)-0.15;
            hi = max(valid)+0.15;
        end
    end
    if k==1
        % Espai per etiquetar fases curtes sense tapar les passes.
        hi = hi+0.22*(hi-lo);
    elseif k==4
        hi = max(hi,thresholds(end)*1.10);
    end
    drawPhaseBands(ax(k),phaseStart,phaseStop,kind,colors,lo,hi);
    if k==4
        thresholdColor = [0.36 0.38 0.40];
        yline(ax(k),thresholds,"--","Color",thresholdColor, ...
            "LineWidth",0.9,"HandleVisibility","off");
        edges = [lo thresholds hi];
        centers = (edges(1:end-1)+edges(2:end))/2;
        text(ax(k),repmat(last/2,1,3),centers,["Sedentary","Light","Moderate-to-vigorous"], ...
            "HorizontalAlignment","center","VerticalAlignment","middle", ...
            "BackgroundColor","white","Margin",1, ...
            "Color",thresholdColor,"FontSize",8, ...
            "HandleVisibility","off");
    end
    if k==3 || k==5
        times = x;
        if k==5, times = x+minutes(T.Stop-T.Start)/2; end
        plot(ax(k),times,y,".-","Color",ink,"LineWidth",1.25,"MarkerSize",11, ...
            "HandleVisibility","off");
    else
        stairs(ax(k),[x;last],[y;y(end)],"Color",ink,"LineWidth",1.35, ...
            "HandleVisibility","off");
    end
    ylim(ax(k),[lo hi]);
    xticks(ax(k),0:10:last);
    ylabel(ax(k),units(k));
    if k<5, ax(k).XTickLabel = []; end
end
linkaxes(ax,"x");
xlim(ax(1),[0 last]);
xlabel(ax(5),timeLabel);
labelPhases(ax(1),phaseStart,phaseStop,phaseNo,kind,colors,last);
addPhaseLegend(ax(1),kind,colors,legendLabels);
writeFigurePNG(fig,fullfile(folder,"00_resum_sessio_5_panells.png"),[14.5 13]);
clear cleanup

if ~isempty(gait)
    phaseNames = ["Initial double support","Single support","Final double support","Swing"];
    legLabels = ["Left leg","Right leg"];
    plotMeanGaitPhases(folder,phasePct,phaseNames,legLabels);
end

% Retirem els PNG substituïts pel resum actual i les fases mitjanes.
retired = ["00_resum_sessio_4_panells.png","01_activitat_VM_60s.png","03_fases_cicle_marxa.png"];
for name = retired
    path = fullfile(folder,name);
    if isfile(path)
        delete(path);
    end
end
end

function plotMeanGaitPhases(folder,phasePct,phaseNames,legLabels)
fig = figure("Visible","off","Color","white","Position",[100 100 780 555]);
cleanup = onCleanup(@() close(fig));
a = axes(fig);
left = [0.80 0.31 0.12;0.94 0.58 0.39;0.98 0.74 0.61;1.00 0.91 0.77];
right = [0.10 0.58 0.58;0.37 0.73 0.71;0.61 0.82 0.79;0.79 0.92 0.88];
meanPct = squeeze(phasePct(end,:,:)).';
drawGaitBars(a,meanPct,cat(3,left,right));
ylabel(a,"Gait cycle (%)");
xticks(a,[1 2]);
xticklabels(a,legLabels);
xlim(a,[0.45 4.25]);
a.Box = "off";
centers = mean(cumsum(meanPct,2)-meanPct/2,1,"omitnan");
for k = find(isfinite(centers))
    text(a,2.52,centers(k),phaseNames(k),"VerticalAlignment","middle","FontWeight","bold");
end
writeFigurePNG(fig,fullfile(folder,"04_fases_cicle_marxa_mitjanes.png"));
end

function bars = drawGaitBars(a,p,fills)
hold(a,"on");
x = (1:size(p,1))';
bars = bar(a,x,p,0.74,"stacked","FaceColor","flat","EdgeColor","white","LineWidth",0.8);
mid = cumsum(p,2)-p/2;
for phase = 1:size(p,2)
    fill = squeeze(fills(phase,:,:)).';
    bars(phase).CData = fill;
    for row = find(p(:,phase)>=5)'
        color = [0.10 0.15 0.20];
        if fill(row,:)*[0.21;0.72;0.07]<0.5
            color = [1 1 1];
        end
        text(a,x(row),mid(row,phase),compose("%.0f",p(row,phase)), ...
            "HorizontalAlignment","center","VerticalAlignment","middle", ...
            "FontWeight","bold","Color",color);
    end
end
missing = all(isnan(p),2);
text(a,x(missing),50*ones(nnz(missing),1),repmat("No cycles",nnz(missing),1), ...
    "HorizontalAlignment","center","Color",[0.36 0.36 0.36]);
ylim(a,[0 100]);
yticks(a,0:20:100);
end

function addPhaseLegend(ax,kind,colors,legendLabels)
used = unique(kind);
h = gobjects(numel(used)+1,1);
for j = 1:numel(used)
    h(j) = plot(ax,NaN,NaN,"s","MarkerSize",8,"MarkerFaceColor",colors(used(j),:), ...
        "MarkerEdgeColor","none");
end
h(end) = plot(ax,NaN,NaN,"s","MarkerSize",8,"MarkerFaceColor","white", ...
    "MarkerEdgeColor",[0.45 0.45 0.45]);
key = legend(ax,h,[legendLabels(used),"No phase recorded"], ...
    "NumColumns",5,"Orientation","horizontal");
key.Layout.Tile = "south";
end

function drawPhaseBands(ax,a,b,kind,colors,lo,hi)
for i = 1:numel(a)
    patch(ax,[a(i) b(i) b(i) a(i)],[lo lo hi hi],colors(kind(i),:), ...
        "FaceAlpha",0.19,"EdgeColor","none","HandleVisibility","off");
end
end

function labelPhases(ax,a,b,numbers,kind,colors,last)
limits = ylim(ax);
span = diff(limits);
laneEnd = -Inf(1,3);
for i = 1:numel(a)
    midpoint = (a(i)+b(i))/2;
    lane = find(midpoint-last*0.022>laneEnd,1);
    if isempty(lane), [~,lane] = min(laneEnd); end
    laneEnd(lane) = midpoint;
    text(ax,midpoint,limits(2)-(0.01+0.063*(lane-1))*span,compose("%02d",numbers(i)), ...
        "VerticalAlignment","top","HorizontalAlignment","center","FontWeight","bold", ...
        "FontSize",8,"Color",0.78*colors(kind(i),:));
end
end

